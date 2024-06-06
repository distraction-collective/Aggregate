// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "RED_SIM/Water/Surface Underwater Light"
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
		_ColorSaturation1("Color Saturation", Range( 0 , 2)) = 1
		_ColorContrast1("Color Contrast", Range( 0 , 3)) = 1
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
		[Header(Animation Settings)]_RipplesSpeed("Ripples Speed", Float) = 1
		_RipplesSpeed2nd("Ripples Speed 2nd", Float) = 1
		_SpeedX("Speed X", Float) = 0
		_SpeedY("Speed Y", Float) = 0
		[Toggle][Header(Visual Fixes)]_ZWrite("ZWrite", Float) = 1
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
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
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
		uniform float _ColorContrast1;
		uniform float4 _Color;
		ASE_DECLARE_SCREENSPACE_TEXTURE( _GrabWater )
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
		uniform float _ColorSaturation1;
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
			float mulTime323 = _Time.y * _RipplesSpeed2nd;
			float2 uv0_Normal2nd = i.uv_texcoord * _Normal2nd_ST.xy + _Normal2nd_ST.zw;
			float2 temp_output_397_0 = ( uv0_Normal2nd + float2( 0,0 ) );
			float2 panner320 = ( mulTime323 * float2( 0.03,0.03 ) + temp_output_397_0);
			float2 temp_output_423_0 = ( appendResult402 * _Normal2nd_ST.xy );
			float2 panner321 = ( mulTime323 * float2( -0.04,0 ) + temp_output_397_0);
			float3 NormalWater315 = BlendNormals( BlendNormals( UnpackScaleNormal( tex2D( _Normal, ( panner22 + temp_output_422_0 ) ), _NormalPower ) , UnpackScaleNormal( tex2D( _Normal, ( panner19 + temp_output_422_0 ) ), _NormalPower ) ) , BlendNormals( UnpackScaleNormal( tex2D( _Normal2nd, ( panner320 + temp_output_423_0 ) ), _NormalPower2nd ) , UnpackScaleNormal( tex2D( _Normal2nd, ( panner321 + temp_output_423_0 ) ), _NormalPower2nd ) ) );
			o.Normal = NormalWater315;
			o.Albedo = _Tint.rgb;
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( ase_screenPos );
			float4 screenColor223 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabWater,ase_grabScreenPos.xy/ase_grabScreenPos.w);
			float3 normalizeResult625 = normalize( -NormalWater315 );
			float3 lerpResult633 = lerp( float3( 0,0,-1 ) , normalizeResult625 , _GradientContrast);
			float3 ase_worldPos = i.worldPos;
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
			float4 lerpResult448 = lerp( ( _Color * screenColor223 ) , lerpResult645 , UnderwaterSurfaceGradientMask638);
			float3 hsvTorgb686 = RGBToHSV( lerpResult448.rgb );
			float smoothstepResult669 = smoothstep( 0.0 , 1.0 , (0.0 + (i.eyeDepth - 0.0) * (1.0 - 0.0) / (_FogDepth - 0.0)));
			float DepthFog678 = pow( smoothstepResult669 , ( _FogGradation + 0.0001 ) );
			float lerpResult690 = lerp( ( 1.0 - DepthFog678 ) , 1.0 , _DepthSaturation);
			float3 hsvTorgb687 = HSVToRGB( float3(hsvTorgb686.x,( hsvTorgb686.y * lerpResult690 ),hsvTorgb686.z) );
			float4 lerpResult695 = lerp( _FogColorClose , _FogColorFar , DepthFog678);
			float4 lerpResult694 = lerp( float4( hsvTorgb687 , 0.0 ) , lerpResult695 , DepthFog678);
			float3 hsvTorgb705 = RGBToHSV( lerpResult694.rgb );
			float3 hsvTorgb708 = HSVToRGB( float3(hsvTorgb705.x,( hsvTorgb705.y * _ColorSaturation1 ),hsvTorgb705.z) );
			o.Emission = CalculateContrast(_ColorContrast1,float4( hsvTorgb708 , 0.0 )).rgb;
			float lerpResult671 = lerp( _Smoothness , 0.0 , DepthFog678);
			o.Smoothness = ( lerpResult671 + ( _ZWrite * 0.0 ) );
			o.Alpha = 1;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=17500
1925;31;1906;987;-1391.916;2553.525;3.181975;True;False
Node;AmplifyShaderEditor.CommentaryNode;151;-2603.808,-2227.266;Inherit;False;3686.834;1339.161;Normals Generation and Animation;38;409;315;326;325;24;17;318;319;23;415;416;417;396;322;48;19;22;321;320;187;21;397;410;323;402;331;324;330;403;395;400;401;422;423;426;427;428;429;;1,1,1,1;0;0
Node;AmplifyShaderEditor.TextureTransformNode;409;-2301.364,-2147.236;Inherit;False;17;False;1;0;SAMPLER2D;_Sampler0409;False;2;FLOAT2;0;FLOAT2;1
Node;AmplifyShaderEditor.ComponentMaskNode;429;-2039.946,-2072.624;Inherit;False;False;True;False;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;428;-2042.946,-2161.624;Inherit;False;True;False;False;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;401;-2135.362,-1878.547;Float;False;Property;_SpeedY;Speed Y;23;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;400;-2135.362,-1954.546;Float;False;Property;_SpeedX;Speed X;22;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;426;-1800.209,-1955.694;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;427;-1801.497,-1860.473;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;331;-1732.226,-1133.957;Float;False;Property;_RipplesSpeed2nd;Ripples Speed 2nd;21;0;Create;True;0;0;False;0;1;0.27;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;395;-1650.542,-1935.599;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;403;-1649.051,-1863.679;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;324;-1498.836,-1471.663;Inherit;False;0;318;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;330;-1754.184,-1642.241;Float;False;Property;_RipplesSpeed;Ripples Speed;20;0;Create;True;0;0;False;1;Header(Animation Settings);1;1.15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;21;-1498.342,-2185.845;Inherit;False;0;17;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;187;-1429.647,-1636.556;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;402;-1402.051,-1890.679;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureTransformNode;410;-2296.347,-1767.355;Inherit;False;318;False;1;0;SAMPLER2D;_Sampler0410;False;2;FLOAT2;0;FLOAT2;1
Node;AmplifyShaderEditor.SimpleTimeNode;323;-1425.611,-1128.277;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;397;-1230.919,-1462.572;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;422;-1025.568,-1908.082;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;22;-1060.095,-2164.592;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;-0.04,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;321;-1060.056,-1342.441;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;-0.04,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;423;-1020.421,-1779.405;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;19;-1057.64,-2051.379;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.03,0.03;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;320;-1062.357,-1459.131;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.03,0.03;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;396;-840.8523,-2164.641;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;417;-837.7202,-1342.943;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-1153.209,-1633.815;Float;False;Property;_NormalPower;Normal Power;18;0;Create;True;0;0;False;0;1;0.176;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;416;-838.9343,-1459.404;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;322;-1132.799,-1129.858;Float;False;Property;_NormalPower2nd;Normal Power 2nd;19;0;Create;True;0;0;False;0;0.5;0.616;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;415;-840.4973,-2050.873;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;23;-710.9724,-2168.967;Inherit;True;Property;_Normal2;Normal2;15;0;Create;True;0;0;False;0;-1;None;None;True;0;True;bump;Auto;True;Instance;17;Auto;Texture2D;6;0;SAMPLER2D;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;319;-707.0675,-1463.32;Inherit;True;Property;_TextureSample3;Texture Sample 3;16;0;Create;True;0;0;False;0;-1;None;None;True;0;True;bump;Auto;True;Instance;318;Auto;Texture2D;6;0;SAMPLER2D;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;318;-706.6074,-1265.861;Inherit;True;Property;_Normal2nd;Normal 2nd;16;0;Create;True;0;0;False;0;-1;None;8d1c512a0b7c09542b55aa818b398907;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;17;-710.5125,-1971.509;Inherit;True;Property;_Normal;Normal;15;0;Create;True;0;0;False;1;Header(Normal Settings);-1;None;6d095a40a0b25e746a709fedd6a9aae6;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BlendNormalsNode;325;-395.7854,-1373.805;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BlendNormalsNode;24;-396.1005,-2073.275;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BlendNormalsNode;326;-144.8125,-1869.665;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;598;-573.1965,-783.8221;Inherit;False;1674.51;530.7842;Underwater Surface Gradient Mask;16;625;610;612;638;637;607;605;603;599;600;602;601;624;604;633;634;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;315;70.11144,-1872.395;Float;False;NormalWater;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;612;-567.764,-736.2754;Inherit;False;315;NormalWater;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NegateNode;610;-366.8637,-729.4424;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;599;-357.0592,-432.5397;Float;False;Property;_GradientRadiusFar;Gradient Radius Far;5;0;Create;True;0;0;False;0;0.519;0.685;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;600;-356.2611,-347.2388;Float;False;Property;_GradientRadiusClose;Gradient Radius Close;6;0;Create;True;0;0;False;0;0.374;0.365;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;625;-244.057,-729.993;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;634;-421.9124,-652.663;Inherit;False;Property;_GradientContrast;Gradient Contrast;7;0;Create;True;0;0;False;0;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;633;-81.99634,-693.7914;Inherit;False;3;0;FLOAT3;0,0,-1;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;602;-18.07234,-340.3449;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;604;-119.9679,-580.8857;Float;False;Tangent;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.OneMinusNode;601;-18.07234,-425.3454;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;603;144.3758,-362.943;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;624;93.49286,-598.753;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;675;1820.498,-150.3717;Float;False;Property;_FogDepth;Fog Depth;12;0;Create;True;0;0;False;0;0;1.92;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SurfaceDepthNode;668;1803.189,-235.2549;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;605;263.3047,-449.1277;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;677;2124.599,-41.27158;Float;False;Property;_FogGradation;Fog Gradation;13;0;Create;True;0;0;False;0;1;0.516;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;674;2183.199,-232.2717;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;607;441.8128,-448.4936;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;669;2367.941,-228.2275;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;703;2392.388,-41.01629;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.0001;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;637;610.1068,-448.6925;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;638;755.9457,-454.3862;Inherit;False;UnderwaterSurfaceGradientMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;676;2549.797,-229.6716;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;701;1376.477,-1217.08;Float;False;Property;_Color;Color;1;0;Create;True;0;0;False;1;Header(Color Settings);1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;644;1352.417,-964.6722;Float;False;Property;_ColorClose;Color Close;4;0;Create;True;0;0;False;0;0.1960784,0.6,0.8392157,0;0.1972314,0.5995165,0.8382353,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;643;1364.615,-782.0511;Float;False;Property;_ColorFar;Color Far;3;0;Create;True;0;0;False;0;0.1176471,0.3333333,0.4039216,0;0.0927764,0.2663537,0.323529,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;678;2729.172,-236.7004;Float;False;DepthFog;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;639;1324.517,-605.5632;Inherit;False;638;UnderwaterSurfaceGradientMask;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;223;1151.154,-1060.994;Float;False;Global;_GrabWater;GrabWater;-1;0;Create;True;0;0;False;0;Object;-1;True;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;702;1624.069,-1080.25;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;645;1711.188,-969.9944;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;693;1817.753,-757.3713;Inherit;False;678;DepthFog;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;448;1939.716,-1005.23;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;692;1967.294,-644.9539;Float;False;Property;_DepthSaturation;Depth Saturation;14;0;Create;True;0;0;False;0;0.5;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;691;1997.448,-757.4111;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;690;2252.716,-807.7907;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RGBToHSVNode;686;2133.144,-986.7526;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ColorNode;698;2342.442,-481.1403;Float;False;Property;_FogColorFar;Fog Color Far;10;0;Create;True;0;0;False;1;Header(Fog Settings);0.1176471,0.3333333,0.4039216,0;0.09926448,0.348106,0.3970586,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;689;2460.716,-917.7907;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;696;2756.147,-579.3616;Inherit;False;678;DepthFog;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;699;2341.944,-648.1616;Float;False;Property;_FogColorClose;Fog Color Close;11;0;Create;True;0;0;False;0;0.1960784,0.6,0.8392157,0;0.1411761,0.572549,0.7137255,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;695;2810.488,-813.2999;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.HSVToRGBNode;687;2752.918,-984.5665;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;694;3038.629,-953.5234;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;704;3591.418,-709.2321;Inherit;False;Property;_ColorSaturation1;Color Saturation;8;0;Create;True;0;0;False;0;1;1.0714;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RGBToHSVNode;705;3835.743,-937.5347;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;711;4296.845,-387.615;Inherit;False;Property;_ZWrite;ZWrite;24;1;[Toggle];Create;True;2;Option1;0;Option2;1;1;;False;1;Header(Visual Fixes);1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;706;3592.261,-633.9449;Inherit;False;Property;_ColorContrast1;Color Contrast;9;0;Create;True;0;0;False;0;1;1.25;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;707;4090.541,-902.4337;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;679;4253.364,-485.7087;Inherit;False;678;DepthFog;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;368;4159.889,-563.0725;Float;False;Property;_Smoothness;Smoothness;17;0;Create;True;0;0;False;0;0.8;0.8;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.HSVToRGBNode;708;4251.741,-928.4337;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WireNode;709;4440.977,-708.4817;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;671;4454.95,-539.2615;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;712;4451.485,-384.4964;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;680;2586.493,-1095.339;Inherit;False;678;DepthFog;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;369;2206.154,-1168.782;Inherit;False;315;NormalWater;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleContrastOpNode;710;4497.441,-927.1348;Inherit;False;2;1;COLOR;0,0,0,0;False;0;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;713;4633.486,-514.4964;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;672;2833.224,-1137.491;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;392;2209.426,-1333.876;Float;False;Property;_Tint;Tint;2;0;Create;True;0;0;False;0;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;4985.755,-1089.487;Float;False;True;-1;7;ASEMaterialInspector;0;0;Standard;RED_SIM/Water/Surface Underwater Light;False;False;False;False;False;False;False;False;False;True;False;False;False;False;True;False;False;False;True;True;False;Front;0;True;711;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;False;-2;True;Opaque;;Transparent;ForwardOnly;14;all;True;True;True;True;0;False;-1;False;228;False;-1;255;False;-1;255;False;-1;6;False;-1;1;False;-1;1;False;-1;1;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;0;4;10;25;False;0.5;False;0;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;1;False;-1;1;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0;False;-1;0;False;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;429;0;409;0
WireConnection;428;0;409;0
WireConnection;426;0;400;0
WireConnection;426;1;428;0
WireConnection;427;0;401;0
WireConnection;427;1;429;0
WireConnection;395;0;426;0
WireConnection;403;0;427;0
WireConnection;187;0;330;0
WireConnection;402;0;395;0
WireConnection;402;1;403;0
WireConnection;323;0;331;0
WireConnection;397;0;324;0
WireConnection;422;0;409;0
WireConnection;422;1;402;0
WireConnection;22;0;21;0
WireConnection;22;1;187;0
WireConnection;321;0;397;0
WireConnection;321;1;323;0
WireConnection;423;0;402;0
WireConnection;423;1;410;0
WireConnection;19;0;21;0
WireConnection;19;1;187;0
WireConnection;320;0;397;0
WireConnection;320;1;323;0
WireConnection;396;0;22;0
WireConnection;396;1;422;0
WireConnection;417;0;321;0
WireConnection;417;1;423;0
WireConnection;416;0;320;0
WireConnection;416;1;423;0
WireConnection;415;0;19;0
WireConnection;415;1;422;0
WireConnection;23;1;396;0
WireConnection;23;5;48;0
WireConnection;319;1;416;0
WireConnection;319;5;322;0
WireConnection;318;1;417;0
WireConnection;318;5;322;0
WireConnection;17;1;415;0
WireConnection;17;5;48;0
WireConnection;325;0;319;0
WireConnection;325;1;318;0
WireConnection;24;0;23;0
WireConnection;24;1;17;0
WireConnection;326;0;24;0
WireConnection;326;1;325;0
WireConnection;315;0;326;0
WireConnection;610;0;612;0
WireConnection;625;0;610;0
WireConnection;633;1;625;0
WireConnection;633;2;634;0
WireConnection;602;0;600;0
WireConnection;601;0;599;0
WireConnection;603;0;601;0
WireConnection;603;1;602;0
WireConnection;624;0;633;0
WireConnection;624;1;604;0
WireConnection;605;0;624;0
WireConnection;605;1;601;0
WireConnection;605;2;603;0
WireConnection;674;0;668;0
WireConnection;674;2;675;0
WireConnection;607;0;605;0
WireConnection;669;0;674;0
WireConnection;703;0;677;0
WireConnection;637;0;607;0
WireConnection;638;0;637;0
WireConnection;676;0;669;0
WireConnection;676;1;703;0
WireConnection;678;0;676;0
WireConnection;702;0;701;0
WireConnection;702;1;223;0
WireConnection;645;0;644;0
WireConnection;645;1;643;0
WireConnection;645;2;639;0
WireConnection;448;0;702;0
WireConnection;448;1;645;0
WireConnection;448;2;639;0
WireConnection;691;0;693;0
WireConnection;690;0;691;0
WireConnection;690;2;692;0
WireConnection;686;0;448;0
WireConnection;689;0;686;2
WireConnection;689;1;690;0
WireConnection;695;0;699;0
WireConnection;695;1;698;0
WireConnection;695;2;696;0
WireConnection;687;0;686;1
WireConnection;687;1;689;0
WireConnection;687;2;686;3
WireConnection;694;0;687;0
WireConnection;694;1;695;0
WireConnection;694;2;696;0
WireConnection;705;0;694;0
WireConnection;707;0;705;2
WireConnection;707;1;704;0
WireConnection;708;0;705;1
WireConnection;708;1;707;0
WireConnection;708;2;705;3
WireConnection;709;0;706;0
WireConnection;671;0;368;0
WireConnection;671;2;679;0
WireConnection;712;0;711;0
WireConnection;710;1;708;0
WireConnection;710;0;709;0
WireConnection;713;0;671;0
WireConnection;713;1;712;0
WireConnection;672;2;680;0
WireConnection;0;0;392;0
WireConnection;0;1;369;0
WireConnection;0;2;710;0
WireConnection;0;4;713;0
ASEEND*/
//CHKSM=27C115E8FE0AB089A90BDD13F5C9E1C3DFCD17D2