// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "RED_SIM/Water/Surface Underwater Uber"
{
	Properties
	{
		[Header(Color Settings)]_Color("Color", Color) = (1,1,1,0)
		_Tint("Tint", Color) = (0,0,0,0)
		_ColorFar("Color Far", Color) = (0.1176471,0.3333333,0.4039216,0)
		_ColorClose("Color Close", Color) = (0.1960784,0.6,0.8392157,0)
		_GradientRadiusFar("Gradient Radius Far", Range( 0 , 2)) = 0.519
		_GradientRadiusClose("Gradient Radius Close", Range( 0 , 1)) = 0.374
		_GradientContrast("Gradient Contrast", Range( 0 , 1)) = 1
		_ColorSaturation("Color Saturation", Range( 0 , 2)) = 1
		_ColorContrast("Color Contrast", Range( 0 , 3)) = 1
		[Header(Fog Settings)]_FogColorFar("Fog Color Far", Color) = (0.1176471,0.3333333,0.4039216,0)
		_FogColorClose("Fog Color Close", Color) = (0.1960784,0.6,0.8392157,0)
		_FogDepth("Fog Depth", Float) = 0
		_FogGradation("Fog Gradation", Range( 0 , 2)) = 1
		_DepthSaturation("Depth Saturation", Range( 0 , 1)) = 0.5
		[Header(Normal Settings)]_Normal("Normal", 2D) = "bump" {}
		_Normal2nd("Normal 2nd", 2D) = "bump" {}
		_Smoothness("Smoothness", Range( 0 , 1)) = 0.8
		_NormalPower("Normal Power", Range( 0 , 1)) = 1
		_NormalPower2nd("Normal Power 2nd", Range( 0 , 1)) = 0.5
		_Refraction("Refraction", Range( 0 , 1)) = 0.01
		_Refraction2nd("Refraction 2nd", Range( 0 , 1)) = 0.01
		_RefractionDistanceFade("Refraction Distance Fade", Range( 0 , 1)) = 0.6
		[Header(Animation Settings)]_RipplesSpeed("Ripples Speed", Float) = 1
		_RipplesSpeed2nd("Ripples Speed 2nd", Float) = 1
		_SpeedX("Speed X", Float) = 0
		_SpeedY("Speed Y", Float) = 0
		[Header(Visual Fixes)]_DepthSmoothing("Depth Smoothing", Range( 0 , 1)) = 0.5
		[IntRange]_EdgeMaskShiftpx("Edge Mask Shift (px)", Range( 0 , 3)) = 2
		[Toggle]_ZWrite("ZWrite", Float) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
		[Header(Forward Rendering Options)]
		[ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		[ToggleOff] _GlossyReflections("Reflections", Float) = 1.0
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Transparent-2" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Front
		ZWrite [_ZWrite]
		GrabPass{ "_GrabWater" }
		CGPROGRAM
		#include "UnityStandardUtils.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#pragma target 5.0
		#pragma shader_feature _SPECULARHIGHLIGHTS_OFF
		#pragma shader_feature _GLOSSYREFLECTIONS_OFF
		#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
		#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex);
		#else
		#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex)
		#endif
		#pragma surface surf Standard keepalpha noshadow exclude_path:deferred nofog vertex:vertexDataFunc 
		struct Input
		{
			float2 uv_texcoord;
			float4 screenPos;
			float3 worldPos;
			float3 worldNormal;
			INTERNAL_DATA
			float eyeDepth;
		};

		uniform sampler2D _Normal;
		uniform float _NormalPower;
		uniform float _RipplesSpeed;
		uniform float4 _Normal_ST;
		uniform sampler2D _Sampler0409;
		uniform float _SpeedX;
		uniform float _SpeedY;
		uniform sampler2D _Normal2nd;
		uniform float _NormalPower2nd;
		uniform float _RipplesSpeed2nd;
		uniform float4 _Normal2nd_ST;
		uniform sampler2D _Sampler0410;
		uniform float4 _Tint;
		uniform float _ColorContrast;
		uniform float4 _Color;
		ASE_DECLARE_SCREENSPACE_TEXTURE( _GrabWater )
		uniform float _Refraction;
		uniform float _RefractionDistanceFade;
		uniform float _Refraction2nd;
		UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
		uniform float4 _CameraDepthTexture_TexelSize;
		uniform float _DepthSmoothing;
		uniform float _EdgeMaskShiftpx;
		uniform float4 _ColorClose;
		uniform float4 _ColorFar;
		uniform float _GradientContrast;
		uniform float _GradientRadiusFar;
		uniform float _GradientRadiusClose;
		uniform float _FogDepth;
		uniform float _FogGradation;
		uniform float _DepthSaturation;
		uniform float4 _FogColorClose;
		uniform float4 _FogColorFar;
		uniform float _ColorSaturation;
		uniform float _Smoothness;
		uniform float _ZWrite;


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

		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			o.eyeDepth = -UnityObjectToViewPos( v.vertex.xyz ).z;
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float mulTime187 = _Time.y * _RipplesSpeed;
			float2 uv0_Normal = i.uv_texcoord * _Normal_ST.xy + _Normal_ST.zw;
			float2 panner22 = ( mulTime187 * float2( -0.04,0 ) + uv0_Normal);
			float mulTime395 = _Time.y * ( _SpeedX / (_Normal_ST.xy).x );
			float mulTime403 = _Time.y * ( _SpeedY / (_Normal_ST.xy).y );
			float2 appendResult402 = (float2(mulTime395 , mulTime403));
			float2 temp_output_422_0 = ( _Normal_ST.xy * appendResult402 );
			float2 panner19 = ( mulTime187 * float2( 0.03,0.03 ) + uv0_Normal);
			float3 temp_output_24_0 = BlendNormals( UnpackScaleNormal( tex2D( _Normal, ( panner22 + temp_output_422_0 ) ), _NormalPower ) , UnpackScaleNormal( tex2D( _Normal, ( panner19 + temp_output_422_0 ) ), _NormalPower ) );
			float mulTime323 = _Time.y * _RipplesSpeed2nd;
			float2 uv0_Normal2nd = i.uv_texcoord * _Normal2nd_ST.xy + _Normal2nd_ST.zw;
			float2 temp_output_397_0 = ( uv0_Normal2nd + float2( 0,0 ) );
			float2 panner320 = ( mulTime323 * float2( 0.03,0.03 ) + temp_output_397_0);
			float2 temp_output_423_0 = ( appendResult402 * _Normal2nd_ST.xy );
			float2 panner321 = ( mulTime323 * float2( -0.04,0 ) + temp_output_397_0);
			float3 temp_output_325_0 = BlendNormals( UnpackScaleNormal( tex2D( _Normal2nd, ( panner320 + temp_output_423_0 ) ), _NormalPower2nd ) , UnpackScaleNormal( tex2D( _Normal2nd, ( panner321 + temp_output_423_0 ) ), _NormalPower2nd ) );
			float3 NormalWater315 = BlendNormals( temp_output_24_0 , temp_output_325_0 );
			o.Normal = NormalWater315;
			o.Albedo = _Tint.rgb;
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( ase_screenPos );
			float4 screenColor223 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabWater,ase_grabScreenPos.xy/ase_grabScreenPos.w);
			float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
			float temp_output_754_0 = ( _Refraction + 0.0001 );
			float3 ase_worldPos = i.worldPos;
			float CameraVertexDistance756 = pow( distance( _WorldSpaceCameraPos , ase_worldPos ) , _RefractionDistanceFade );
			float clampResult764 = clamp( ( pow( saturate( temp_output_754_0 ) , 2.0 ) / CameraVertexDistance756 ) , 0.0 , temp_output_754_0 );
			float RefractionPower767 = clampResult764;
			float temp_output_752_0 = ( _Refraction2nd + 0.0001 );
			float clampResult765 = clamp( ( pow( saturate( temp_output_752_0 ) , 2.0 ) / CameraVertexDistance756 ) , 0.0 , temp_output_752_0 );
			float RefractionPower2nd766 = clampResult765;
			float3 lerpResult770 = lerp( ( RefractionPower767 * temp_output_24_0 ) , ( temp_output_325_0 * RefractionPower2nd766 ) , float3( 0.5,0.5,0.5 ));
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float eyeDepth167 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
			float DepthSmoothing716 = saturate( (0.0 + (( eyeDepth167 - ase_screenPos.w ) - 0.0) * (1.0 - 0.0) / (_DepthSmoothing - 0.0)) );
			float2 appendResult806 = (float2((0.0 + (( 1.0 / ( atan( ( 1.0 / unity_CameraProjection[0].x ) ) * 2.0 ) ) - 0.0) * (1.0 - 0.0) / (UNITY_PI - 0.0)) , (0.0 + (( 1.0 / ( atan( ( 1.0 / unity_CameraProjection[1].y ) ) * 2.0 ) ) - 0.0) * (1.0 - 0.0) / (UNITY_PI - 0.0))));
			float2 FovFactor807 = appendResult806;
			float3 NormalShift237 = ( lerpResult770 * DepthSmoothing716 * float3( FovFactor807 ,  0.0 ) );
			float4 screenColor65 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabWater,( float3( (ase_grabScreenPosNorm).xy ,  0.0 ) + NormalShift237 ).xy);
			float4 temp_output_214_0 = ( ase_grabScreenPosNorm + float4( NormalShift237 , 0.0 ) );
			float temp_output_436_0 = ( 1.0 / _ScreenParams.y );
			float2 appendResult251 = (float2(0.0 , -temp_output_436_0));
			float2 ShiftDown257 = ( appendResult251 * _EdgeMaskShiftpx );
			float eyeDepth212 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ( temp_output_214_0 + float4( ShiftDown257, 0.0 , 0.0 ) ).xy ));
			float2 appendResult254 = (float2(0.0 , temp_output_436_0));
			float2 ShiftUp258 = ( appendResult254 * _EdgeMaskShiftpx );
			float eyeDepth271 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ( temp_output_214_0 + float4( ShiftUp258, 0.0 , 0.0 ) ).xy ));
			float temp_output_435_0 = ( 1.0 / _ScreenParams.x );
			float2 appendResult255 = (float2(-temp_output_435_0 , 0.0));
			float2 ShiftLeft259 = ( appendResult255 * _EdgeMaskShiftpx );
			float eyeDepth275 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ( temp_output_214_0 + float4( ShiftLeft259, 0.0 , 0.0 ) ).xy ));
			float2 appendResult256 = (float2(temp_output_435_0 , 0.0));
			float2 ShiftRight260 = ( appendResult256 * _EdgeMaskShiftpx );
			float eyeDepth279 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ( temp_output_214_0 + float4( ShiftRight260, 0.0 , 0.0 ) ).xy ));
			float DepthMask188 = ( 1.0 - saturate( ( ( 1.0 - saturate( (0.0 + (( eyeDepth212 - ase_grabScreenPos.a ) - 0.0) * (1.0 - 0.0) / (1E-05 - 0.0)) ) ) + ( 1.0 - saturate( (0.0 + (( eyeDepth271 - ase_grabScreenPos.a ) - 0.0) * (1.0 - 0.0) / (1E-05 - 0.0)) ) ) + ( 1.0 - saturate( (0.0 + (( eyeDepth275 - ase_grabScreenPos.a ) - 0.0) * (1.0 - 0.0) / (1E-05 - 0.0)) ) ) + ( 1.0 - saturate( (0.0 + (( eyeDepth279 - ase_grabScreenPos.a ) - 0.0) * (1.0 - 0.0) / (1E-05 - 0.0)) ) ) ) ) );
			float4 lerpResult224 = lerp( screenColor223 , screenColor65 , DepthMask188);
			float3 normalizeResult625 = normalize( -NormalWater315 );
			float3 lerpResult633 = lerp( float3( 0,0,-1 ) , normalizeResult625 , _GradientContrast);
			float3 ase_worldViewDir = Unity_SafeNormalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float3 ase_tanViewDir = mul( ase_worldToTangent, ase_worldViewDir );
			float dotResult624 = dot( lerpResult633 , ase_tanViewDir );
			float temp_output_601_0 = ( 1.0 - _GradientRadiusFar );
			float smoothstepResult607 = smoothstep( 0.0 , 1.0 , (0.0 + (dotResult624 - temp_output_601_0) * (1.0 - 0.0) / (( temp_output_601_0 + ( 1.0 - _GradientRadiusClose ) ) - temp_output_601_0)));
			float UnderwaterSurfaceGradientMask638 = ( 1.0 - smoothstepResult607 );
			float4 lerpResult645 = lerp( _ColorClose , _ColorFar , UnderwaterSurfaceGradientMask638);
			float4 lerpResult448 = lerp( ( _Color * lerpResult224 ) , lerpResult645 , UnderwaterSurfaceGradientMask638);
			float3 hsvTorgb686 = RGBToHSV( lerpResult448.rgb );
			float smoothstepResult669 = smoothstep( 0.0 , 1.0 , (0.0 + (i.eyeDepth - 0.0) * (1.0 - 0.0) / (_FogDepth - 0.0)));
			float DepthFog678 = pow( smoothstepResult669 , ( _FogGradation + 0.0001 ) );
			float lerpResult690 = lerp( ( 1.0 - DepthFog678 ) , 1.0 , _DepthSaturation);
			float3 hsvTorgb687 = HSVToRGB( float3(hsvTorgb686.x,( hsvTorgb686.y * lerpResult690 ),hsvTorgb686.z) );
			float4 lerpResult695 = lerp( _FogColorClose , _FogColorFar , DepthFog678);
			float4 lerpResult694 = lerp( float4( hsvTorgb687 , 0.0 ) , lerpResult695 , DepthFog678);
			float3 hsvTorgb705 = RGBToHSV( lerpResult694.rgb );
			float3 hsvTorgb708 = HSVToRGB( float3(hsvTorgb705.x,( hsvTorgb705.y * _ColorSaturation ),hsvTorgb705.z) );
			o.Emission = CalculateContrast(_ColorContrast,float4( hsvTorgb708 , 0.0 )).rgb;
			float lerpResult671 = lerp( _Smoothness , 0.0 , DepthFog678);
			o.Smoothness = ( lerpResult671 + ( _ZWrite * 0.0 ) );
			o.Alpha = 1;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=17800
1927;10;1906;987;779.08;2214.033;3.153856;True;False
Node;AmplifyShaderEditor.CommentaryNode;746;-3620.915,-1367.692;Inherit;False;1010.247;444.9871;Distance from Camera to Vertex;6;772;771;753;750;751;756;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;151;-3919.04,-2889.683;Inherit;False;3686.834;1339.161;Normals Generation and Animation;47;409;315;326;325;24;17;318;319;23;415;416;417;396;322;48;19;22;321;320;187;21;397;410;323;402;331;324;330;403;395;400;401;422;423;426;427;428;429;717;744;769;768;770;98;237;743;787;;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldPosInputsNode;750;-3493.954,-1171.524;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceCameraPos;751;-3574.404,-1315.324;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;747;-2529.579,-1365.387;Inherit;False;1351.063;305.8954;Reftaction Power;8;767;764;762;761;759;757;754;748;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;790;-4183.884,-874.1801;Inherit;False;1567.501;495.8999;FOV from Projection Matrix;17;807;806;805;804;803;802;801;800;799;798;797;796;795;794;793;792;791;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;745;-2529.798,-1016.914;Inherit;False;1442.461;323.4593;Reftaction Power 2nd;8;766;765;763;760;758;755;752;749;;1,1,1,1;0;0
Node;AmplifyShaderEditor.TextureTransformNode;409;-3616.597,-2809.653;Inherit;False;17;False;1;0;SAMPLER2D;_Sampler0409;False;2;FLOAT2;0;FLOAT2;1
Node;AmplifyShaderEditor.RangedFloatNode;400;-3450.595,-2616.963;Float;False;Property;_SpeedX;Speed X;25;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;429;-3355.179,-2735.041;Inherit;False;False;True;False;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;753;-3279.173,-1250.882;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;771;-3545.034,-1015.28;Inherit;False;Property;_RefractionDistanceFade;Refraction Distance Fade;22;0;Create;True;0;0;False;0;0.6;0.6;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;428;-3358.179,-2824.041;Inherit;False;True;False;False;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;749;-2507.132,-870.5839;Float;False;Property;_Refraction2nd;Refraction 2nd;21;0;Create;True;0;0;False;0;0.01;0.4;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;748;-2494.414,-1216.415;Float;False;Property;_Refraction;Refraction;20;0;Create;True;0;0;False;0;0.01;0.3;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;401;-3450.595,-2540.963;Float;False;Property;_SpeedY;Speed Y;26;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CameraProjectionNode;791;-4174.65,-698.8214;Inherit;False;unity_CameraProjection;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;427;-3116.729,-2522.889;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;752;-2218.946,-864.536;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.0001;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;772;-3090.308,-1237.311;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;754;-2206.229,-1210.367;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.0001;False;1;FLOAT;0
Node;AmplifyShaderEditor.VectorFromMatrixNode;793;-3927.842,-822.8491;Inherit;False;Row;0;1;0;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VectorFromMatrixNode;792;-3924.557,-612.3395;Inherit;False;Row;1;1;0;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;426;-3115.442,-2618.11;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;330;-3069.416,-2304.658;Float;False;Property;_RipplesSpeed;Ripples Speed;23;0;Create;True;0;0;False;1;Header(Animation Settings);1;1.15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;756;-2900.866,-1256.442;Inherit;False;CameraVertexDistance;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;755;-2081.414,-938.3944;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;395;-2965.775,-2598.016;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;403;-2964.284,-2526.095;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;757;-2062.329,-1282.407;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;795;-3724.731,-800.8021;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;324;-2814.069,-2134.079;Inherit;False;0;318;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;794;-3738.653,-586.3395;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;331;-3047.458,-1796.373;Float;False;Property;_RipplesSpeed2nd;Ripples Speed 2nd;24;0;Create;True;0;0;False;0;1;0.27;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;236;-2529.492,-669.3808;Inherit;False;1223.351;528.5051;Regular Depth For Smoothing;8;716;232;230;229;168;166;167;549;;1,1,1,1;0;0
Node;AmplifyShaderEditor.DynamicAppendNode;402;-2717.284,-2553.095;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;323;-2740.844,-1790.693;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;759;-2038.503,-1147.428;Inherit;False;756;CameraVertexDistance;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;21;-2813.575,-2848.262;Inherit;False;0;17;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;397;-2546.152,-2124.988;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;187;-2744.88,-2298.973;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;549;-2518.208,-607.3217;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ATanOpNode;797;-3609.954,-586.3394;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ATanOpNode;796;-3596.032,-800.8021;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;761;-1910.491,-1286.464;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;760;-2029.183,-795.3209;Inherit;False;756;CameraVertexDistance;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureTransformNode;410;-3611.579,-2429.771;Inherit;False;318;False;1;0;SAMPLER2D;_Sampler0410;False;2;FLOAT2;0;FLOAT2;1
Node;AmplifyShaderEditor.PowerNode;758;-1909.597,-942.4524;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;763;-1714.703,-937.4595;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;423;-2335.654,-2441.821;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;320;-2377.59,-2121.547;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.03,0.03;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScreenDepthNode;167;-2288.75,-618.4318;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;762;-1742.073,-1285.931;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;22;-2375.328,-2827.009;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;-0.04,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;422;-2340.801,-2570.498;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;799;-3487.283,-583.0717;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;798;-3473.361,-797.5344;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;321;-2375.289,-2004.857;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;-0.04,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;166;-2499.078,-437.4156;Float;False;1;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;19;-2372.873,-2713.796;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.03,0.03;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-2468.442,-2296.232;Float;False;Property;_NormalPower;Normal Power;18;0;Create;True;0;0;False;0;1;0.176;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;764;-1566.076,-1281.152;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;417;-2152.953,-2005.359;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;322;-2448.032,-1792.274;Float;False;Property;_NormalPower2nd;Normal Power 2nd;19;0;Create;True;0;0;False;0;0.5;0.616;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;396;-2156.085,-2827.058;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ClampOpNode;765;-1538.705,-932.6794;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;415;-2155.73,-2713.29;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;416;-2154.167,-2121.82;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;800;-3348.083,-604.0386;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PiNode;803;-3484.631,-695.9273;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;802;-3334.161,-818.5012;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;168;-2071.072,-615.0898;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;229;-2481.736,-228.4308;Float;False;Property;_DepthSmoothing;Depth Smoothing;27;0;Create;True;0;0;False;1;Header(Visual Fixes);0.5;0.25;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.PiNode;801;-3489.552,-481.4648;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;391;239.2129,-2957.333;Inherit;False;1400.039;588.3945;Edge Mask Shift;19;260;257;259;258;293;291;290;292;255;256;254;251;294;253;250;252;435;436;431;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;766;-1386.294,-937.8235;Inherit;False;RefractionPower2nd;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;767;-1419.415,-1287.506;Inherit;False;RefractionPower;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;318;-2021.84,-1928.277;Inherit;True;Property;_Normal2nd;Normal 2nd;16;0;Create;True;0;0;False;0;-1;None;8d1c512a0b7c09542b55aa818b398907;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;804;-3210.052,-597.4644;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;805;-3196.13,-811.9269;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;17;-2025.745,-2633.925;Inherit;True;Property;_Normal;Normal;15;0;Create;True;0;0;False;1;Header(Normal Settings);-1;None;6d095a40a0b25e746a709fedd6a9aae6;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;23;-2026.205,-2831.384;Inherit;True;Property;_Normal2;Normal2;15;0;Create;True;0;0;False;0;-1;None;None;True;0;True;bump;Auto;True;Instance;17;Auto;Texture2D;6;0;SAMPLER2D;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;319;-2022.3,-2125.736;Inherit;True;Property;_TextureSample3;Texture Sample 3;16;0;Create;True;0;0;False;0;-1;None;None;True;0;True;bump;Auto;True;Instance;318;Auto;Texture2D;6;0;SAMPLER2D;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;230;-1914.495,-615.6957;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.25;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.BlendNormalsNode;24;-1711.333,-2735.692;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BlendNormalsNode;325;-1711.018,-2036.221;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;232;-1729.491,-616.0368;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;744;-1716.116,-2829.693;Inherit;False;767;RefractionPower;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;769;-1714.846,-1873.89;Inherit;False;766;RefractionPower2nd;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenParams;431;301.0161,-2702.363;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;806;-2972.308,-673.6473;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;435;513.8156,-2636.676;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;716;-1554.607,-625.3691;Inherit;False;DepthSmoothing;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;768;-1446.046,-2009.89;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;807;-2833.281,-678.3801;Inherit;False;FovFactor;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;743;-1448.434,-2763.854;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;436;510.8156,-2737.676;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;252;721.3448,-2800.098;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;250;722.0259,-2886.742;Float;False;Constant;_Zero;Zero;4;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;253;712.9914,-2649.224;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;717;-1035.306,-2214.885;Inherit;False;716;DepthSmoothing;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;770;-952.1125,-2370.222;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0.5,0.5,0.5;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;787;-1009.427,-2072.382;Inherit;False;807;FovFactor;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;256;909.0142,-2592.353;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;254;910.0709,-2777.263;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;255;909.0142,-2685.337;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;98;-759.2418,-2365.009;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT2;0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;294;803.119,-2473.777;Float;False;Property;_EdgeMaskShiftpx;Edge Mask Shift (px);28;1;[IntRange];Create;True;0;0;False;0;2;2;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;251;905.8449,-2869.193;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;290;1099.918,-2869.005;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;243;230.7903,-2345.048;Inherit;False;2477.782;932.5398;Depth Mask for Ripples;37;188;310;287;285;299;301;300;302;314;311;313;312;307;308;306;309;217;280;276;272;212;523;279;275;271;164;269;278;270;274;282;284;214;261;283;240;239;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;293;1102.028,-2580.99;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;292;1104.138,-2671.72;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;237;-570.4957,-2372.97;Float;False;NormalShift;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;291;1105.193,-2768.78;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;258;1337.472,-2770.073;Float;False;ShiftUp;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GrabScreenPosition;240;256.1357,-2300.151;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;259;1339.472,-2681.073;Float;False;ShiftLeft;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;257;1335.472,-2863.073;Float;False;ShiftDown;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;260;1341.472,-2586.073;Float;False;ShiftRight;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;239;275.4224,-2125.375;Inherit;False;237;NormalShift;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;214;577.9457,-2141.933;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;283;515.0703,-1769.553;Inherit;False;259;ShiftLeft;1;0;OBJECT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;282;512.0703,-1902.553;Inherit;False;258;ShiftUp;1;0;OBJECT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;261;512.5007,-2039.558;Inherit;False;257;ShiftDown;1;0;OBJECT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;284;517.0703,-1661.553;Inherit;False;260;ShiftRight;1;0;OBJECT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;269;741.9175,-2056.276;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;270;745.7346,-1917.244;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;278;748.7346,-1680.244;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.BlendNormalsNode;326;-1476.11,-2358.941;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GrabScreenPosition;164;706.5804,-2296.699;Inherit;False;1;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;274;746.7346,-1786.244;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;315;-1268.256,-2365.063;Float;False;NormalWater;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RelayNode;523;962.2374,-2114.949;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;598;-372.7881,-797.6434;Inherit;False;1674.51;530.7842;Underwater Surface Gradient Mask;16;625;610;612;638;637;607;605;603;599;600;602;601;624;604;633;634;;1,1,1,1;0;0
Node;AmplifyShaderEditor.ScreenDepthNode;275;897.4249,-1766.194;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;212;889.8936,-2036.225;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;279;896.7106,-1660.194;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;271;893.7106,-1897.194;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;276;1113.887,-1762.767;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;217;1109.07,-2032.8;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;272;1112.887,-1893.766;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;612;-357.3556,-748.0967;Inherit;False;315;NormalWater;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;280;1115.887,-1656.767;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;307;1280.524,-1944.28;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1E-05;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;309;1286.524,-1604.28;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1E-05;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;306;1276.151,-2143.207;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1E-05;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;308;1281.524,-1774.28;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1E-05;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;610;-166.4554,-743.2637;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;634;-221.5041,-666.4843;Inherit;False;Property;_GradientContrast;Gradient Contrast;7;0;Create;True;0;0;False;0;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;599;-156.6509,-446.361;Float;False;Property;_GradientRadiusFar;Gradient Radius Far;5;0;Create;True;0;0;False;0;0.519;0.685;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;625;-43.64868,-743.8143;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;312;1472.017,-1938.85;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;313;1462.637,-1768.963;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;311;1447.004,-2149.384;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;600;-155.8528,-361.0601;Float;False;Property;_GradientRadiusClose;Gradient Radius Close;6;0;Create;True;0;0;False;0;0.374;0.365;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;314;1471.795,-1604.51;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;602;182.336,-354.1662;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;302;1614.032,-1607.401;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;301;1611.032,-1776.401;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;601;182.336,-439.1667;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;299;1596.382,-2142.85;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;604;80.44044,-594.707;Float;False;Tangent;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.OneMinusNode;300;1608.282,-1945.749;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;633;118.412,-707.6127;Inherit;False;3;0;FLOAT3;0,0,-1;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;285;1892.97,-1846.653;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;624;293.9012,-612.5743;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;603;344.7842,-376.7643;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;826;82.67691,-228.1086;Inherit;False;1218.982;378.6841;Depth Fog;8;675;668;677;674;669;703;676;678;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;150;-41.11066,-1216.245;Inherit;False;1341.654;394.7715;Final Refracted Image;8;219;224;65;96;238;165;220;223;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;675;149.9859,-91.77991;Float;False;Property;_FogDepth;Fog Depth;12;0;Create;True;0;0;False;0;0;1.92;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SurfaceDepthNode;668;132.6769,-176.6632;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;287;2039.412,-1844.234;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;605;463.7131,-462.949;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GrabScreenPosition;220;-11.38195,-1025.708;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;677;454.086,17.32018;Float;False;Property;_FogGradation;Fog Gradation;13;0;Create;True;0;0;False;0;1;0.516;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;674;512.6859,-173.6799;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;238;225.6004,-929.9606;Inherit;False;237;NormalShift;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SmoothstepOpNode;607;642.2212,-462.3149;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;165;231.9172,-1026.504;Inherit;False;True;True;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.OneMinusNode;310;2201.055,-1842.142;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;669;697.4279,-169.6358;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;188;2394.104,-1849.841;Float;False;DepthMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;96;459.4991,-1022.236;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;637;810.5151,-462.5138;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;703;721.8747,17.57547;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.0001;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;676;879.2838,-171.0799;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;223;858.8641,-1159.593;Float;False;Global;_GrabWater;GrabWater;-1;0;Create;True;0;0;False;0;Object;-1;True;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;219;868.0611,-935.7646;Inherit;False;188;DepthMask;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;65;590.1062,-1027.76;Float;False;Global;_WaterGrab;WaterGrab;-1;0;Create;True;0;0;False;0;Instance;223;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;638;956.3541,-468.2075;Inherit;False;UnderwaterSurfaceGradientMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;678;1058.659,-178.1086;Float;False;DepthFog;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;639;1324.517,-605.5632;Inherit;False;638;UnderwaterSurfaceGradientMask;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;224;1115.616,-1046.043;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;643;1364.615,-782.0511;Float;False;Property;_ColorFar;Color Far;2;0;Create;True;0;0;False;0;0.1176471,0.3333333,0.4039216,0;0.09277611,0.2663534,0.3235287,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;701;1376.477,-1217.08;Float;False;Property;_Color;Color;0;0;Create;True;0;0;False;1;Header(Color Settings);1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;644;1352.417,-964.6722;Float;False;Property;_ColorClose;Color Close;4;0;Create;True;0;0;False;0;0.1960784,0.6,0.8392157,0;0.1972311,0.5995165,0.8382353,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;693;1817.753,-757.3713;Inherit;False;678;DepthFog;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;645;1711.188,-969.9944;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;702;1624.069,-1080.25;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;691;1997.448,-757.4111;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;692;1967.294,-644.9539;Float;False;Property;_DepthSaturation;Depth Saturation;14;0;Create;True;0;0;False;0;0.5;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;448;1939.716,-1005.23;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RGBToHSVNode;686;2133.144,-986.7526;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;690;2252.716,-807.7907;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;698;2342.442,-481.1403;Float;False;Property;_FogColorFar;Fog Color Far;10;0;Create;True;0;0;False;1;Header(Fog Settings);0.1176471,0.3333333,0.4039216,0;0.09926421,0.3481057,0.3970583,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;699;2341.944,-648.1616;Float;False;Property;_FogColorClose;Fog Color Close;11;0;Create;True;0;0;False;0;0.1960784,0.6,0.8392157,0;0.1411758,0.572549,0.7137255,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;689;2463.395,-943.2451;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;696;2368.843,-301.1353;Inherit;False;678;DepthFog;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.HSVToRGBNode;687;2752.918,-984.5665;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;815;2798.925,-693.2238;Inherit;False;678;DepthFog;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;695;2810.488,-813.2999;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;694;3046.805,-976.9639;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;711;3170.323,-840.939;Inherit;False;Property;_ColorSaturation;Color Saturation;8;0;Create;True;0;0;False;0;1;1.04;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RGBToHSVNode;705;3230.615,-982.0688;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;679;3253.369,-578.6138;Inherit;False;678;DepthFog;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;368;3159.895,-655.9775;Float;False;Property;_Smoothness;Smoothness;17;0;Create;True;0;0;False;0;0.8;0.8;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;707;3485.413,-946.9677;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;712;3171.164,-764.2682;Inherit;False;Property;_ColorContrast;Color Contrast;9;0;Create;True;0;0;False;0;1;1.25;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;809;3309.516,-501.5934;Inherit;False;Property;_ZWrite;ZWrite;29;1;[Toggle];Create;True;2;Option1;0;Option2;1;1;;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;808;3464.153,-498.4748;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;671;3454.955,-632.1666;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.HSVToRGBNode;708;3637.229,-959.8311;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WireNode;715;3827.722,-795.8451;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;810;3646.154,-628.475;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleContrastOpNode;710;3867.913,-960.4098;Inherit;False;2;1;COLOR;0,0,0,0;False;0;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;369;3859.082,-1056.752;Inherit;False;315;NormalWater;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;392;3862.354,-1221.846;Float;False;Property;_Tint;Tint;1;0;Create;True;0;0;False;0;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;4171.137,-1040.981;Float;False;True;-1;7;ASEMaterialInspector;0;0;Standard;RED_SIM/Water/Surface Underwater Uber;False;False;False;False;False;False;False;False;False;True;False;False;False;False;True;False;False;False;True;True;False;Front;0;True;809;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;False;-2;True;Opaque;;Transparent;ForwardOnly;14;all;True;True;True;True;0;False;-1;False;228;False;-1;255;False;-1;255;False;-1;6;False;-1;1;False;-1;1;False;-1;1;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;0;4;10;25;False;0.5;False;0;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;1;False;-1;1;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;3;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0;False;-1;0;False;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;429;0;409;0
WireConnection;753;0;751;0
WireConnection;753;1;750;0
WireConnection;428;0;409;0
WireConnection;427;0;401;0
WireConnection;427;1;429;0
WireConnection;752;0;749;0
WireConnection;772;0;753;0
WireConnection;772;1;771;0
WireConnection;754;0;748;0
WireConnection;793;0;791;0
WireConnection;792;0;791;0
WireConnection;426;0;400;0
WireConnection;426;1;428;0
WireConnection;756;0;772;0
WireConnection;755;0;752;0
WireConnection;395;0;426;0
WireConnection;403;0;427;0
WireConnection;757;0;754;0
WireConnection;795;1;793;1
WireConnection;794;1;792;2
WireConnection;402;0;395;0
WireConnection;402;1;403;0
WireConnection;323;0;331;0
WireConnection;397;0;324;0
WireConnection;187;0;330;0
WireConnection;797;0;794;0
WireConnection;796;0;795;0
WireConnection;761;0;757;0
WireConnection;758;0;755;0
WireConnection;763;0;758;0
WireConnection;763;1;760;0
WireConnection;423;0;402;0
WireConnection;423;1;410;0
WireConnection;320;0;397;0
WireConnection;320;1;323;0
WireConnection;167;0;549;0
WireConnection;762;0;761;0
WireConnection;762;1;759;0
WireConnection;22;0;21;0
WireConnection;22;1;187;0
WireConnection;422;0;409;0
WireConnection;422;1;402;0
WireConnection;799;0;797;0
WireConnection;798;0;796;0
WireConnection;321;0;397;0
WireConnection;321;1;323;0
WireConnection;19;0;21;0
WireConnection;19;1;187;0
WireConnection;764;0;762;0
WireConnection;764;2;754;0
WireConnection;417;0;321;0
WireConnection;417;1;423;0
WireConnection;396;0;22;0
WireConnection;396;1;422;0
WireConnection;765;0;763;0
WireConnection;765;2;752;0
WireConnection;415;0;19;0
WireConnection;415;1;422;0
WireConnection;416;0;320;0
WireConnection;416;1;423;0
WireConnection;800;1;799;0
WireConnection;802;1;798;0
WireConnection;168;0;167;0
WireConnection;168;1;166;4
WireConnection;766;0;765;0
WireConnection;767;0;764;0
WireConnection;318;1;417;0
WireConnection;318;5;322;0
WireConnection;804;0;800;0
WireConnection;804;2;801;0
WireConnection;805;0;802;0
WireConnection;805;2;803;0
WireConnection;17;1;415;0
WireConnection;17;5;48;0
WireConnection;23;1;396;0
WireConnection;23;5;48;0
WireConnection;319;1;416;0
WireConnection;319;5;322;0
WireConnection;230;0;168;0
WireConnection;230;2;229;0
WireConnection;24;0;23;0
WireConnection;24;1;17;0
WireConnection;325;0;319;0
WireConnection;325;1;318;0
WireConnection;232;0;230;0
WireConnection;806;0;805;0
WireConnection;806;1;804;0
WireConnection;435;1;431;1
WireConnection;716;0;232;0
WireConnection;768;0;325;0
WireConnection;768;1;769;0
WireConnection;807;0;806;0
WireConnection;743;0;744;0
WireConnection;743;1;24;0
WireConnection;436;1;431;2
WireConnection;252;0;436;0
WireConnection;253;0;435;0
WireConnection;770;0;743;0
WireConnection;770;1;768;0
WireConnection;256;0;435;0
WireConnection;256;1;250;0
WireConnection;254;0;250;0
WireConnection;254;1;436;0
WireConnection;255;0;253;0
WireConnection;255;1;250;0
WireConnection;98;0;770;0
WireConnection;98;1;717;0
WireConnection;98;2;787;0
WireConnection;251;0;250;0
WireConnection;251;1;252;0
WireConnection;290;0;251;0
WireConnection;290;1;294;0
WireConnection;293;0;256;0
WireConnection;293;1;294;0
WireConnection;292;0;255;0
WireConnection;292;1;294;0
WireConnection;237;0;98;0
WireConnection;291;0;254;0
WireConnection;291;1;294;0
WireConnection;258;0;291;0
WireConnection;259;0;292;0
WireConnection;257;0;290;0
WireConnection;260;0;293;0
WireConnection;214;0;240;0
WireConnection;214;1;239;0
WireConnection;269;0;214;0
WireConnection;269;1;261;0
WireConnection;270;0;214;0
WireConnection;270;1;282;0
WireConnection;278;0;214;0
WireConnection;278;1;284;0
WireConnection;326;0;24;0
WireConnection;326;1;325;0
WireConnection;274;0;214;0
WireConnection;274;1;283;0
WireConnection;315;0;326;0
WireConnection;523;0;164;4
WireConnection;275;0;274;0
WireConnection;212;0;269;0
WireConnection;279;0;278;0
WireConnection;271;0;270;0
WireConnection;276;0;275;0
WireConnection;276;1;523;0
WireConnection;217;0;212;0
WireConnection;217;1;523;0
WireConnection;272;0;271;0
WireConnection;272;1;523;0
WireConnection;280;0;279;0
WireConnection;280;1;523;0
WireConnection;307;0;272;0
WireConnection;309;0;280;0
WireConnection;306;0;217;0
WireConnection;308;0;276;0
WireConnection;610;0;612;0
WireConnection;625;0;610;0
WireConnection;312;0;307;0
WireConnection;313;0;308;0
WireConnection;311;0;306;0
WireConnection;314;0;309;0
WireConnection;602;0;600;0
WireConnection;302;0;314;0
WireConnection;301;0;313;0
WireConnection;601;0;599;0
WireConnection;299;0;311;0
WireConnection;300;0;312;0
WireConnection;633;1;625;0
WireConnection;633;2;634;0
WireConnection;285;0;299;0
WireConnection;285;1;300;0
WireConnection;285;2;301;0
WireConnection;285;3;302;0
WireConnection;624;0;633;0
WireConnection;624;1;604;0
WireConnection;603;0;601;0
WireConnection;603;1;602;0
WireConnection;287;0;285;0
WireConnection;605;0;624;0
WireConnection;605;1;601;0
WireConnection;605;2;603;0
WireConnection;674;0;668;0
WireConnection;674;2;675;0
WireConnection;607;0;605;0
WireConnection;165;0;220;0
WireConnection;310;0;287;0
WireConnection;669;0;674;0
WireConnection;188;0;310;0
WireConnection;96;0;165;0
WireConnection;96;1;238;0
WireConnection;637;0;607;0
WireConnection;703;0;677;0
WireConnection;676;0;669;0
WireConnection;676;1;703;0
WireConnection;65;0;96;0
WireConnection;638;0;637;0
WireConnection;678;0;676;0
WireConnection;224;0;223;0
WireConnection;224;1;65;0
WireConnection;224;2;219;0
WireConnection;645;0;644;0
WireConnection;645;1;643;0
WireConnection;645;2;639;0
WireConnection;702;0;701;0
WireConnection;702;1;224;0
WireConnection;691;0;693;0
WireConnection;448;0;702;0
WireConnection;448;1;645;0
WireConnection;448;2;639;0
WireConnection;686;0;448;0
WireConnection;690;0;691;0
WireConnection;690;2;692;0
WireConnection;689;0;686;2
WireConnection;689;1;690;0
WireConnection;687;0;686;1
WireConnection;687;1;689;0
WireConnection;687;2;686;3
WireConnection;695;0;699;0
WireConnection;695;1;698;0
WireConnection;695;2;696;0
WireConnection;694;0;687;0
WireConnection;694;1;695;0
WireConnection;694;2;815;0
WireConnection;705;0;694;0
WireConnection;707;0;705;2
WireConnection;707;1;711;0
WireConnection;808;0;809;0
WireConnection;671;0;368;0
WireConnection;671;2;679;0
WireConnection;708;0;705;1
WireConnection;708;1;707;0
WireConnection;708;2;705;3
WireConnection;715;0;712;0
WireConnection;810;0;671;0
WireConnection;810;1;808;0
WireConnection;710;1;708;0
WireConnection;710;0;715;0
WireConnection;0;0;392;0
WireConnection;0;1;369;0
WireConnection;0;2;710;0
WireConnection;0;4;810;0
ASEEND*/
//CHKSM=279A2BE44806B498BFBE2E548A04C7BD2D655E7B