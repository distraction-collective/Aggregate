// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "RED_SIM/Water/Underwater Fog Caustics"
{
	Properties
	{
		[Header(Color Settings)]_ColorFar("Color Far", Color) = (0.1176471,0.3333333,0.4039216,0)
		_ColorClose("Color Close", Color) = (0.1960784,0.6,0.8392157,0)
		_ColorSaturation("Color Saturation", Range( 0 , 2)) = 1
		_ColorContrast("Color Contrast", Range( 0 , 3)) = 1
		[Header(Depth Settings)]_FogDepth("Fog Depth", Float) = 0.374
		_DepthSaturation("Depth Saturation", Range( 0 , 1)) = 1
		_FogGradation("Fog Gradation", Range( 0 , 2)) = 0
		[IntRange][Header(Stencil)]_StencilMask("Stencil Mask", Range( 0 , 255)) = 228
		[Header(Caustics)]_CausticsPower("Caustics Power", Range( 0 , 5)) = 0
		_CausticsSize("Caustics Size", Float) = 20
		_CausticsSpeed("Caustics Speed", Float) = 1
		_CausticsDispersion("Caustics Dispersion", Range( 0 , 1)) = 0.25
		_CausticsRefractionSize("Caustics Refraction Size", Range( 0 , 1)) = 1
		_CausticsRefractionPower("Caustics Refraction Power", Range( 0 , 1)) = 0.5
		[NoScaleOffset]_CausticsRefractionNormal("Caustics Refraction Normal", 2D) = "bump" {}
		_CausticsDarknessLimit("Caustics Darkness Limit", Range( 0 , 1)) = 0
		_CausticsBrightnessGradation("Caustics Brightness Gradation", Range( 0 , 1)) = 0
		_CausticsDirection("Caustics Direction", Vector) = (0,0,0,0)
		[Toggle]_MatchCausticsDirectionWithLightSource("Match Caustics Direction With Light Source", Float) = 0
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Transparent-2" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Front
		ZWrite Off
		ZTest GEqual
		Stencil
		{
			Ref [_StencilMask]
			Comp NotEqual
			Pass Keep
			Fail Keep
			ZFail Keep
		}
		GrabPass{ "_GrabWater" }
		CGPROGRAM
		#include "UnityCG.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityStandardUtils.cginc"
		#pragma target 5.0
		#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
		#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex);
		#else
		#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex)
		#endif
		#pragma surface surf Unlit keepalpha noshadow exclude_path:deferred nofog 
		struct Input
		{
			float4 screenPos;
			float3 worldPos;
		};

		uniform float _ColorContrast;
		ASE_DECLARE_SCREENSPACE_TEXTURE( _GrabWater )
		UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
		uniform float4 _CameraDepthTexture_TexelSize;
		uniform float _FogDepth;
		uniform float _FogGradation;
		uniform float _DepthSaturation;
		uniform float4 _ColorClose;
		uniform float4 _ColorFar;
		uniform float _StencilMask;
		uniform float _ColorSaturation;
		uniform float _CausticsSpeed;
		uniform float _CausticsSize;
		uniform float _MatchCausticsDirectionWithLightSource;
		uniform float3 _CausticsDirection;
		uniform float _CausticsRefractionPower;
		uniform sampler2D _CausticsRefractionNormal;
		uniform float _CausticsRefractionSize;
		uniform float _CausticsDispersion;
		uniform float _CausticsDarknessLimit;
		uniform float _CausticsBrightnessGradation;
		uniform float _CausticsPower;


		float3 HSVToRGB( float3 c )
		{
			float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
			float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
			return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
		}


		float3 RGBToHSV(float3 c)
		{
			float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
			float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
			float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
			float d = q.x - min( q.w, q.y );
			float e = 1.0e-10;
			return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
		}

		inline float4 ASE_ComputeGrabScreenPos( float4 pos )
		{
			#if UNITY_UV_STARTS_AT_TOP
			float scale = -1.0;
			#else
			float scale = 1.0;
			#endif
			float4 o = pos;
			o.y = pos.w * 0.5f;
			o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
			return o;
		}


		float4 CalculateContrast( float contrastValue, float4 colorTarget )
		{
			float t = 0.5 * ( 1.0 - contrastValue );
			return mul( float4x4( contrastValue,0,0,t, 0,contrastValue,0,t, 0,0,contrastValue,t, 0,0,0,1 ), colorTarget );
		}

		float2 voronoihash205( float2 p )
		{
			p = p - 1000 * floor( p / 1000 );
			p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
			return frac( sin( p ) *43758.5453);
		}


		float voronoi205( float2 v, float time, inout float2 id, float smoothness )
		{
			float2 n = floor( v );
			float2 f = frac( v );
			float F1 = 8.0;
			float F2 = 8.0; float2 mr = 0; float2 mg = 0;
			for ( int j = -1; j <= 1; j++ )
			{
				for ( int i = -1; i <= 1; i++ )
			 	{
			 		float2 g = float2( i, j );
			 		float2 o = voronoihash205( n + g );
					o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = g - f + o;
					float d = 0.5 * dot( r, r );
			 		if( d<F1 ) {
			 			F2 = F1;
			 			F1 = d; mg = g; mr = r; id = o;
			 		} else if( d<F2 ) {
			 			F2 = d;
			 		}
			 	}
			}
			return (F2 + F1) * 0.5;
		}


		float2 UnStereo( float2 UV )
		{
			#if UNITY_SINGLE_PASS_STEREO
			float4 scaleOffset = unity_StereoScaleOffset[ unity_StereoEyeIndex ];
			UV.xy = (UV.xy - scaleOffset.zw) / scaleOffset.xy;
			#endif
			return UV;
		}


		float2 voronoihash202( float2 p )
		{
			p = p - 1000 * floor( p / 1000 );
			p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
			return frac( sin( p ) *43758.5453);
		}


		float voronoi202( float2 v, float time, inout float2 id, float smoothness )
		{
			float2 n = floor( v );
			float2 f = frac( v );
			float F1 = 8.0;
			float F2 = 8.0; float2 mr = 0; float2 mg = 0;
			for ( int j = -1; j <= 1; j++ )
			{
				for ( int i = -1; i <= 1; i++ )
			 	{
			 		float2 g = float2( i, j );
			 		float2 o = voronoihash202( n + g );
					o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = g - f + o;
					float d = 0.5 * dot( r, r );
			 		if( d<F1 ) {
			 			F2 = F1;
			 			F1 = d; mg = g; mr = r; id = o;
			 		} else if( d<F2 ) {
			 			F2 = d;
			 		}
			 	}
			}
			return (F2 + F1) * 0.5;
		}


		float2 voronoihash201( float2 p )
		{
			p = p - 1000 * floor( p / 1000 );
			p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
			return frac( sin( p ) *43758.5453);
		}


		float voronoi201( float2 v, float time, inout float2 id, float smoothness )
		{
			float2 n = floor( v );
			float2 f = frac( v );
			float F1 = 8.0;
			float F2 = 8.0; float2 mr = 0; float2 mg = 0;
			for ( int j = -1; j <= 1; j++ )
			{
				for ( int i = -1; i <= 1; i++ )
			 	{
			 		float2 g = float2( i, j );
			 		float2 o = voronoihash201( n + g );
					o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = g - f + o;
					float d = 0.5 * dot( r, r );
			 		if( d<F1 ) {
			 			F2 = F1;
			 			F1 = d; mg = g; mr = r; id = o;
			 		} else if( d<F2 ) {
			 			F2 = d;
			 		}
			 	}
			}
			return (F2 + F1) * 0.5;
		}


		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( ase_screenPos );
			float4 screenColor13 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabWater,ase_grabScreenPos.xy/ase_grabScreenPos.w);
			float3 hsvTorgb25 = RGBToHSV( screenColor13.rgb );
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float eyeDepth1 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
			float smoothstepResult9 = smoothstep( 0.0 , 1.0 , (0.0 + (eyeDepth1 - 0.0) * (1.0 - 0.0) / (_FogDepth - 0.0)));
			float temp_output_15_0 = pow( smoothstepResult9 , ( _FogGradation + 0.0001 ) );
			float lerpResult29 = lerp( ( 1.0 - temp_output_15_0 ) , 1.0 , _DepthSaturation);
			float3 hsvTorgb26 = HSVToRGB( float3(hsvTorgb25.x,( hsvTorgb25.y * lerpResult29 ),hsvTorgb25.z) );
			float4 lerpResult12 = lerp( _ColorClose , _ColorFar , temp_output_15_0);
			float FogGradationMask146 = temp_output_15_0;
			float4 lerpResult14 = lerp( float4( hsvTorgb26 , 0.0 ) , lerpResult12 , FogGradationMask146);
			float3 hsvTorgb69 = RGBToHSV( ( lerpResult14 + ( _StencilMask * 0.0 ) ).rgb );
			float3 hsvTorgb72 = HSVToRGB( float3(hsvTorgb69.x,( hsvTorgb69.y * _ColorSaturation ),hsvTorgb69.z) );
			float CausticsSpeed165 = _CausticsSpeed;
			float mulTime190 = _Time.y * CausticsSpeed165;
			float time205 = mulTime190;
			float3 temp_output_1_0_g103 = float3( 1,0,0 );
			float3 break3_g90 = radians( _CausticsDirection );
			float temp_output_4_0_g90 = cos( break3_g90.x );
			float3 appendResult10_g90 = (float3(( temp_output_4_0_g90 * cos( break3_g90.y ) ) , ( temp_output_4_0_g90 * sin( break3_g90.y ) ) , sin( break3_g90.x )));
			float3 temp_output_2_0_g103 = appendResult10_g90;
			float dotResult3_g103 = dot( temp_output_1_0_g103 , temp_output_2_0_g103 );
			float3 break19_g103 = cross( temp_output_1_0_g103 , temp_output_2_0_g103 );
			float4 appendResult23_g103 = (float4(break19_g103.x , break19_g103.y , break19_g103.z , ( dotResult3_g103 + 1.0 )));
			float4 normalizeResult24_g103 = normalize( appendResult23_g103 );
			float4 ifLocalVar25_g103 = 0;
			if( dotResult3_g103 <= 0.999999 )
				ifLocalVar25_g103 = normalizeResult24_g103;
			else
				ifLocalVar25_g103 = float4(0,0,0,1);
			float temp_output_4_0_g104 = ( UNITY_PI / 2.0 );
			float3 temp_output_8_0_g103 = cross( float3(1,0,0) , temp_output_1_0_g103 );
			float3 ifLocalVar10_g103 = 0;
			if( length( temp_output_8_0_g103 ) >= 1E-06 )
				ifLocalVar10_g103 = temp_output_8_0_g103;
			else
				ifLocalVar10_g103 = cross( float3(0,1,0) , temp_output_1_0_g103 );
			float3 normalizeResult13_g103 = normalize( ifLocalVar10_g103 );
			float3 break10_g104 = ( sin( temp_output_4_0_g104 ) * normalizeResult13_g103 );
			float4 appendResult8_g104 = (float4(break10_g104.x , break10_g104.y , break10_g104.z , cos( temp_output_4_0_g104 )));
			float4 ifLocalVar4_g103 = 0;
			if( dotResult3_g103 >= -0.999999 )
				ifLocalVar4_g103 = ifLocalVar25_g103;
			else
				ifLocalVar4_g103 = appendResult8_g104;
			float3 temp_output_1_0_g105 = float3( 0,1,0 );
			float3 ase_worldPos = i.worldPos;
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = Unity_SafeNormalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float3 appendResult156 = (float3(ase_worldlightDir.x , -ase_worldlightDir.y , ase_worldlightDir.z));
			float3 temp_output_2_0_g105 = appendResult156;
			float dotResult3_g105 = dot( temp_output_1_0_g105 , temp_output_2_0_g105 );
			float3 break19_g105 = cross( temp_output_1_0_g105 , temp_output_2_0_g105 );
			float4 appendResult23_g105 = (float4(break19_g105.x , break19_g105.y , break19_g105.z , ( dotResult3_g105 + 1.0 )));
			float4 normalizeResult24_g105 = normalize( appendResult23_g105 );
			float4 ifLocalVar25_g105 = 0;
			if( dotResult3_g105 <= 0.999999 )
				ifLocalVar25_g105 = normalizeResult24_g105;
			else
				ifLocalVar25_g105 = float4(0,0,0,1);
			float temp_output_4_0_g106 = ( UNITY_PI / 2.0 );
			float3 temp_output_8_0_g105 = cross( float3(1,0,0) , temp_output_1_0_g105 );
			float3 ifLocalVar10_g105 = 0;
			if( length( temp_output_8_0_g105 ) >= 1E-06 )
				ifLocalVar10_g105 = temp_output_8_0_g105;
			else
				ifLocalVar10_g105 = cross( float3(0,1,0) , temp_output_1_0_g105 );
			float3 normalizeResult13_g105 = normalize( ifLocalVar10_g105 );
			float3 break10_g106 = ( sin( temp_output_4_0_g106 ) * normalizeResult13_g105 );
			float4 appendResult8_g106 = (float4(break10_g106.x , break10_g106.y , break10_g106.z , cos( temp_output_4_0_g106 )));
			float4 ifLocalVar4_g105 = 0;
			if( dotResult3_g105 >= -0.999999 )
				ifLocalVar4_g105 = ifLocalVar25_g105;
			else
				ifLocalVar4_g105 = appendResult8_g106;
			float4 temp_output_2_0_g109 = (( _MatchCausticsDirectionWithLightSource )?( ifLocalVar4_g105 ):( ifLocalVar4_g103 ));
			float4 temp_output_1_0_g110 = temp_output_2_0_g109;
			float3 temp_output_7_0_g110 = (temp_output_1_0_g110).xyz;
			float4 temp_output_72_0_g107 = ase_screenPosNorm;
			float2 UV22_g108 = temp_output_72_0_g107.xy;
			float2 localUnStereo22_g108 = UnStereo( UV22_g108 );
			float2 break64_g107 = localUnStereo22_g108;
			float eyeDepth68_g107 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
			float4 tex2DNode36_g107 = tex2D( _CameraDepthTexture, ( temp_output_72_0_g107 + ( eyeDepth68_g107 * 0.0 ) ).xy );
			#ifdef UNITY_REVERSED_Z
				float4 staticSwitch38_g107 = ( 1.0 - tex2DNode36_g107 );
			#else
				float4 staticSwitch38_g107 = tex2DNode36_g107;
			#endif
			float3 appendResult39_g107 = (float3(break64_g107.x , break64_g107.y , staticSwitch38_g107.r));
			float4 appendResult42_g107 = (float4((appendResult39_g107*2.0 + -1.0) , 1.0));
			float4 temp_output_43_0_g107 = mul( unity_CameraInvProjection, appendResult42_g107 );
			float4 appendResult49_g107 = (float4(( ( (temp_output_43_0_g107).xyz / (temp_output_43_0_g107).w ) * float3( 1,1,-1 ) ) , 1.0));
			float3 break8_g109 = mul( unity_CameraToWorld, appendResult49_g107 ).xyz;
			float4 appendResult9_g109 = (float4(break8_g109.x , break8_g109.y , break8_g109.z , 0.0));
			float4 temp_output_1_0_g111 = appendResult9_g109;
			float3 temp_output_7_0_g111 = (temp_output_1_0_g111).xyz;
			float4 temp_output_2_0_g111 = ( temp_output_2_0_g109 * float4(-1,-1,-1,1) );
			float temp_output_10_0_g111 = (temp_output_2_0_g111).w;
			float3 temp_output_3_0_g111 = (temp_output_2_0_g111).xyz;
			float temp_output_11_0_g111 = (temp_output_1_0_g111).w;
			float3 break17_g111 = ( ( temp_output_7_0_g111 * temp_output_10_0_g111 ) + cross( temp_output_1_0_g111.xyz , temp_output_2_0_g111.xyz ) + ( temp_output_3_0_g111 * temp_output_11_0_g111 ) );
			float dotResult16_g111 = dot( temp_output_7_0_g111 , temp_output_3_0_g111 );
			float4 appendResult18_g111 = (float4(break17_g111.x , break17_g111.y , break17_g111.z , ( ( temp_output_11_0_g111 * temp_output_10_0_g111 ) - dotResult16_g111 )));
			float4 temp_output_2_0_g110 = appendResult18_g111;
			float temp_output_10_0_g110 = (temp_output_2_0_g110).w;
			float3 temp_output_3_0_g110 = (temp_output_2_0_g110).xyz;
			float temp_output_11_0_g110 = (temp_output_1_0_g110).w;
			float3 break17_g110 = ( ( temp_output_7_0_g110 * temp_output_10_0_g110 ) + cross( temp_output_1_0_g110.xyz , temp_output_2_0_g110.xyz ) + ( temp_output_3_0_g110 * temp_output_11_0_g110 ) );
			float dotResult16_g110 = dot( temp_output_7_0_g110 , temp_output_3_0_g110 );
			float4 appendResult18_g110 = (float4(break17_g110.x , break17_g110.y , break17_g110.z , ( ( temp_output_11_0_g110 * temp_output_10_0_g110 ) - dotResult16_g110 )));
			float3 break162 = (appendResult18_g110).xyz;
			float2 appendResult164 = (float2(break162.x , break162.z));
			float2 OverlayUV167 = appendResult164;
			float mulTime168 = _Time.y * CausticsSpeed165;
			float2 panner170 = ( mulTime168 * float2( 0.03,0.03 ) + OverlayUV167);
			float2 panner171 = ( mulTime168 * float2( -0.04,0 ) + OverlayUV167);
			float2 CausticsNormalShift182 = (BlendNormals( UnpackScaleNormal( tex2D( _CausticsRefractionNormal, ( _CausticsRefractionSize * ( panner170 + float2( 0,0 ) ) ) ), _CausticsRefractionPower ) , UnpackScaleNormal( tex2D( _CausticsRefractionNormal, ( _CausticsRefractionSize * ( panner171 + float2( 0,0 ) ) ) ), _CausticsRefractionPower ) )).xy;
			float2 CausticsUV191 = (( _CausticsSize * ( OverlayUV167 + CausticsNormalShift182 ) )).xy;
			float2 coords205 = CausticsUV191 * 1.0;
			float2 id205 = 0;
			float voroi205 = voronoi205( coords205, time205,id205, 0 );
			float time202 = ( mulTime190 + _CausticsDispersion );
			float2 coords202 = CausticsUV191 * 1.0;
			float2 id202 = 0;
			float voroi202 = voronoi202( coords202, time202,id202, 0 );
			float time201 = ( mulTime190 + ( _CausticsDispersion * 2.0 ) );
			float2 coords201 = CausticsUV191 * 1.0;
			float2 id201 = 0;
			float voroi201 = voronoi201( coords201, time201,id201, 0 );
			float3 appendResult207 = (float3(voroi205 , voroi202 , voroi201));
			float3 smoothstepResult210 = smoothstep( float3( 0,0,0 ) , float3( 1,1,1 ) , appendResult207);
			float4 screenColor195 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabWater,ase_grabScreenPos.xy/ase_grabScreenPos.w);
			float3 hsvTorgb204 = RGBToHSV( screenColor195.rgb );
			float3 Caustics213 = ( smoothstepResult210 * ( 1.0 - FogGradationMask146 ) * saturate( (0.0 + (hsvTorgb204.z - _CausticsDarknessLimit) * (1.0 - 0.0) / (( _CausticsDarknessLimit + _CausticsBrightnessGradation ) - _CausticsDarknessLimit)) ) * _CausticsPower );
			o.Emission = ( CalculateContrast(_ColorContrast,float4( hsvTorgb72 , 0.0 )) + float4( Caustics213 , 0.0 ) ).rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=17500
1925;31;1906;987;1242.314;405.7394;1.720556;True;False
Node;AmplifyShaderEditor.CommentaryNode;148;-250.2432,395.5448;Inherit;False;2010.473;443.9841;Caustics World Space Overlay UV;13;167;164;162;161;160;158;157;156;155;154;153;152;215;;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;152;-200.2432,660.0016;Inherit;False;True;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;154;-180.8019,511.5295;Inherit;False;Property;_CausticsDirection;Caustics Direction;20;0;Create;True;0;0;False;0;0,0,0;-9.7,34.54,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NegateNode;153;61.1982,706.5295;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;155;62.1982,542.5295;Inherit;False;EulerToVector;-1;;90;eccb94dfd3409444dbce1a6ab89f5ecd;0;1;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;156;188.1982,683.5295;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;157;322.2106,519.1215;Inherit;False;FromToRotation;-1;;103;ad10913350839ec49a3853aee4185e18;0;2;1;FLOAT3;1,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;158;323.2106,661.1215;Inherit;False;FromToRotation;-1;;105;ad10913350839ec49a3853aee4185e18;0;2;1;FLOAT3;0,1,0;False;2;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;215;379.6775,445.2205;Inherit;False;Reconstruct World Position From Depth Fixed;1;;107;beeca014df21a9f499a4ef97f930ce20;0;1;72;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ToggleSwitchNode;160;558.2108,570.1215;Inherit;False;Property;_MatchCausticsDirectionWithLightSource;Match Caustics Direction With Light Source;21;0;Create;True;0;0;False;0;0;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;161;874.4573,539.8366;Inherit;False;RotateVector;-1;;109;5c6ddc37cb38dfb458f9519ddf619b0c;0;2;1;FLOAT3;0,0,0;False;2;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;149;-399.3387,1892.97;Inherit;False;2346.389;895.553;Caustics Visual Part;27;213;212;211;210;209;208;207;206;205;204;203;202;201;200;199;198;197;196;195;194;193;192;190;189;165;163;214;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;163;-349.3387,2172.014;Inherit;False;Property;_CausticsSpeed;Caustics Speed;13;0;Create;True;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;162;1127.695,541.7875;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.CommentaryNode;150;-308.8358,1257.596;Inherit;False;2123.895;581.9497;Caustics Refraction Normal Shift;16;182;181;180;179;178;177;176;175;174;173;172;171;170;169;168;166;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;165;-157.747,2171.194;Inherit;False;CausticsSpeed;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;164;1378.125,556.0095;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;166;-258.8358,1515.589;Inherit;False;165;CausticsSpeed;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;167;1517.229,551.4374;Inherit;False;OverlayUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;169;-55.70081,1408.082;Inherit;False;167;OverlayUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;168;-38.06381,1520.131;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;171;177.4912,1531.968;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;-0.04,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;170;175.1902,1415.276;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.03,0.03;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;174;264.2579,1305.868;Inherit;False;Property;_CausticsRefractionSize;Caustics Refraction Size;15;0;Create;True;0;0;False;0;1;0.155;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;173;399.827,1531.465;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;172;398.6131,1415.003;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;176;330.7483,1676.551;Float;False;Property;_CausticsRefractionPower;Caustics Refraction Power;16;0;Create;True;0;0;False;0;0.5;0.045;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;177;574.734,1511.094;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;175;580.5481,1344.807;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;179;772.94,1609.547;Inherit;True;Property;_TextureSample1;Texture Sample 1;17;0;Create;True;0;0;False;0;-1;None;8d1c512a0b7c09542b55aa818b398907;True;0;True;bump;Auto;True;Instance;178;Auto;Texture2D;6;0;SAMPLER2D;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;178;772.48,1412.087;Inherit;True;Property;_CausticsRefractionNormal;Caustics Refraction Normal;17;1;[NoScaleOffset];Create;True;0;0;False;0;-1;None;6d095a40a0b25e746a709fedd6a9aae6;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BlendNormalsNode;180;1109.704,1498.603;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;181;1315.351,1494.472;Inherit;False;True;True;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScreenDepthNode;1;-959.5709,-22.73474;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;3;-929.0142,54.68321;Float;False;Property;_FogDepth;Fog Depth;6;0;Create;True;0;0;False;1;Header(Depth Settings);0.374;1.92;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;16;-724.7006,193.1168;Float;False;Property;_FogGradation;Fog Gradation;8;0;Create;True;0;0;False;0;0;0.516;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;8;-738.7921,0.06058526;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;151;90.5868,886.5236;Inherit;False;1094.699;301.6119;Caustics Final UV;7;191;188;187;186;185;184;183;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;182;1533.06,1494.698;Inherit;False;CausticsNormalShift;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;183;201.5869,995.1354;Inherit;False;167;OverlayUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;64;-449.3161,191.6917;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.0001;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;184;140.5868,1073.135;Inherit;False;182;CausticsNormalShift;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SmoothstepOpNode;9;-530.1303,2.794655;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;185;394.578,936.5236;Inherit;False;Property;_CausticsSize;Caustics Size;12;0;Create;True;0;0;False;0;20;40;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;186;389.5868,1022.135;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PowerNode;15;-295.499,32.55543;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;187;580.1918,989.3156;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;30;-78.0406,-104.4592;Inherit;False;Property;_DepthSaturation;Depth Saturation;7;0;Create;True;0;0;False;0;1;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;28;-76.13652,-172.3118;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;13;-58.47787,-466.4052;Inherit;False;Global;_GrabWater;GrabWater;1;0;Create;True;0;0;False;0;Object;-1;True;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;29;193.7859,-171.0587;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RGBToHSVNode;25;128.6529,-458.2219;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ComponentMaskNode;188;730.8716,985.1406;Inherit;False;True;True;False;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;189;-216.3992,2389.637;Inherit;False;Property;_CausticsDispersion;Caustics Dispersion;14;0;Create;True;0;0;False;0;0.25;0.204;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;190;54.05341,2177.836;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;10;-421.7459,-440.2226;Float;False;Property;_ColorClose;Color Close;3;0;Create;True;0;0;False;0;0.1960784,0.6,0.8392157,0;0.1415974,0.571576,0.7132353,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;11;-430.5082,-267.4655;Float;False;Property;_ColorFar;Color Far;0;0;Create;True;0;0;False;1;Header(Color Settings);0.1176471,0.3333333,0.4039216,0;0.1176462,0.3570241,0.4039207,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;192;115.3894,2528.225;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;27;449.7531,-410.1221;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;191;942.2856,984.2775;Inherit;False;CausticsUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;193;289.2216,2426.67;Inherit;False;191;CausticsUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;200;774.9215,2595.076;Inherit;False;Property;_CausticsDarknessLimit;Caustics Darkness Limit;18;0;Create;True;0;0;False;0;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;196;285.5231,2270.15;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;146;-59.26943,19.39008;Inherit;False;FogGradationMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;194;272.8503,2188.827;Inherit;False;191;CausticsUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;197;751.017,2670.523;Inherit;False;Property;_CausticsBrightnessGradation;Caustics Brightness Gradation;19;0;Create;True;0;0;False;0;0;0.866;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;199;270.8342,1942.97;Inherit;False;191;CausticsUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;65;851.8067,-93.27044;Inherit;False;Property;_StencilMask;Stencil Mask;9;1;[IntRange];Create;True;0;0;False;1;Header(Stencil);228;228;0;255;0;1;FLOAT;0
Node;AmplifyShaderEditor.HSVToRGBNode;26;709.7528,-433.5219;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;198;289.9301,2505.133;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;12;-74.89443,-294.1148;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ScreenColorNode;195;749.8455,2429.076;Float;False;Global;_GrabScreen0;Grab Screen 0;-1;0;Create;True;0;0;False;0;Instance;13;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;203;1053.017,2655.523;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VoronoiNode;202;477.3134,2193.681;Inherit;True;0;0;1;3;1;True;1000;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;1;False;2;FLOAT;1;False;3;FLOAT;0;False;2;FLOAT;0;FLOAT;1
Node;AmplifyShaderEditor.LerpOp;14;1053.143,-305.518;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;66;1132.807,-88.27044;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VoronoiNode;201;484.1173,2432.148;Inherit;True;0;0;1;3;1;True;1000;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;1;False;2;FLOAT;1;False;3;FLOAT;0;False;2;FLOAT;0;FLOAT;1
Node;AmplifyShaderEditor.RGBToHSVNode;204;982.9138,2435.589;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.VoronoiNode;205;477.1364,1947.594;Inherit;True;0;0;1;3;1;True;1000;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;1;False;2;FLOAT;1;False;3;FLOAT;0;False;2;FLOAT;0;FLOAT;1
Node;AmplifyShaderEditor.GetLocalVarNode;209;1075.052,2239.653;Inherit;False;146;FogGradationMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;67;1313.052,-297.0311;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;207;747.2261,2170.832;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TFHCRemapNode;206;1205.921,2520.076;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;75;1418.287,-50.22781;Inherit;False;Property;_ColorSaturation;Color Saturation;4;0;Create;True;0;0;False;0;1;1.0714;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;210;909.5181,2173.418;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;1,1,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;211;1212.176,2322.264;Inherit;False;Property;_CausticsPower;Caustics Power;10;0;Create;True;0;0;False;1;Header(Caustics);0;1.53;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.RGBToHSVNode;69;1662.612,-278.5303;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.OneMinusNode;214;1345.712,2247.688;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;208;1380.921,2520.076;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;212;1553.752,2174.253;Inherit;False;4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;71;1917.41,-243.4293;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;76;1419.13,25.05942;Inherit;False;Property;_ColorContrast;Color Contrast;5;0;Create;True;0;0;False;0;1;1.25;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.HSVToRGBNode;72;2078.61,-269.4294;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;213;1704.05,2169.341;Inherit;False;Caustics;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;77;2267.846,-49.47736;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleContrastOpNode;74;2324.311,-268.1304;Inherit;False;2;1;COLOR;0,0,0,0;False;0;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;145;2348.12,-161.8514;Inherit;False;213;Caustics;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;144;2581.541,-176.3152;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;2754.083,-306.5802;Float;False;True;-1;7;ASEMaterialInspector;0;0;Unlit;RED_SIM/Water/Underwater Fog Caustics;False;False;False;False;False;False;False;False;False;True;False;False;False;False;True;False;False;False;False;False;False;Front;2;False;-1;4;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;False;-2;True;Opaque;;Transparent;ForwardOnly;14;all;True;True;True;True;0;False;-1;True;228;True;65;255;False;-1;255;False;-1;6;False;-1;1;False;-1;1;False;-1;1;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;11;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;153;0;152;2
WireConnection;155;2;154;0
WireConnection;156;0;152;1
WireConnection;156;1;153;0
WireConnection;156;2;152;3
WireConnection;157;2;155;0
WireConnection;158;2;156;0
WireConnection;160;0;157;0
WireConnection;160;1;158;0
WireConnection;161;1;215;0
WireConnection;161;2;160;0
WireConnection;162;0;161;0
WireConnection;165;0;163;0
WireConnection;164;0;162;0
WireConnection;164;1;162;2
WireConnection;167;0;164;0
WireConnection;168;0;166;0
WireConnection;171;0;169;0
WireConnection;171;1;168;0
WireConnection;170;0;169;0
WireConnection;170;1;168;0
WireConnection;173;0;171;0
WireConnection;172;0;170;0
WireConnection;177;0;174;0
WireConnection;177;1;173;0
WireConnection;175;0;174;0
WireConnection;175;1;172;0
WireConnection;179;1;177;0
WireConnection;179;5;176;0
WireConnection;178;1;175;0
WireConnection;178;5;176;0
WireConnection;180;0;178;0
WireConnection;180;1;179;0
WireConnection;181;0;180;0
WireConnection;8;0;1;0
WireConnection;8;2;3;0
WireConnection;182;0;181;0
WireConnection;64;0;16;0
WireConnection;9;0;8;0
WireConnection;186;0;183;0
WireConnection;186;1;184;0
WireConnection;15;0;9;0
WireConnection;15;1;64;0
WireConnection;187;0;185;0
WireConnection;187;1;186;0
WireConnection;28;0;15;0
WireConnection;29;0;28;0
WireConnection;29;2;30;0
WireConnection;25;0;13;0
WireConnection;188;0;187;0
WireConnection;190;0;165;0
WireConnection;192;0;189;0
WireConnection;27;0;25;2
WireConnection;27;1;29;0
WireConnection;191;0;188;0
WireConnection;196;0;190;0
WireConnection;196;1;189;0
WireConnection;146;0;15;0
WireConnection;26;0;25;1
WireConnection;26;1;27;0
WireConnection;26;2;25;3
WireConnection;198;0;190;0
WireConnection;198;1;192;0
WireConnection;12;0;10;0
WireConnection;12;1;11;0
WireConnection;12;2;15;0
WireConnection;203;0;200;0
WireConnection;203;1;197;0
WireConnection;202;0;194;0
WireConnection;202;1;196;0
WireConnection;14;0;26;0
WireConnection;14;1;12;0
WireConnection;14;2;146;0
WireConnection;66;0;65;0
WireConnection;201;0;193;0
WireConnection;201;1;198;0
WireConnection;204;0;195;0
WireConnection;205;0;199;0
WireConnection;205;1;190;0
WireConnection;67;0;14;0
WireConnection;67;1;66;0
WireConnection;207;0;205;0
WireConnection;207;1;202;0
WireConnection;207;2;201;0
WireConnection;206;0;204;3
WireConnection;206;1;200;0
WireConnection;206;2;203;0
WireConnection;210;0;207;0
WireConnection;69;0;67;0
WireConnection;214;0;209;0
WireConnection;208;0;206;0
WireConnection;212;0;210;0
WireConnection;212;1;214;0
WireConnection;212;2;208;0
WireConnection;212;3;211;0
WireConnection;71;0;69;2
WireConnection;71;1;75;0
WireConnection;72;0;69;1
WireConnection;72;1;71;0
WireConnection;72;2;69;3
WireConnection;213;0;212;0
WireConnection;77;0;76;0
WireConnection;74;1;72;0
WireConnection;74;0;77;0
WireConnection;144;0;74;0
WireConnection;144;1;145;0
WireConnection;0;2;144;0
ASEEND*/
//CHKSM=7C50ED61DB195D8D3879FD468CC97E818367468E