// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "RED_SIM/Water/Underwater Fog"
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
			float4 lerpResult14 = lerp( float4( hsvTorgb26 , 0.0 ) , lerpResult12 , temp_output_15_0);
			float3 hsvTorgb69 = RGBToHSV( ( lerpResult14 + ( _StencilMask * 0.0 ) ).rgb );
			float3 hsvTorgb72 = HSVToRGB( float3(hsvTorgb69.x,( hsvTorgb69.y * _ColorSaturation ),hsvTorgb69.z) );
			o.Emission = CalculateContrast(_ColorContrast,float4( hsvTorgb72 , 0.0 )).rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=17500
1925;31;1906;987;-119.0459;887.8076;2.086465;True;False
Node;AmplifyShaderEditor.RangedFloatNode;3;-929.0142,54.68321;Float;False;Property;_FogDepth;Fog Depth;4;0;Create;True;0;0;False;1;Header(Depth Settings);0.374;1.92;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;1;-959.5709,-22.73474;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;8;-738.7921,0.06058526;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;16;-724.7006,193.1168;Float;False;Property;_FogGradation;Fog Gradation;6;0;Create;True;0;0;False;0;0;0.516;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;64;-449.3161,191.6917;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.0001;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;9;-530.1303,2.794655;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;15;-295.499,32.55543;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;30;-78.0406,-104.4592;Inherit;False;Property;_DepthSaturation;Depth Saturation;5;0;Create;True;0;0;False;0;1;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;13;-58.47787,-466.4052;Inherit;False;Global;_GrabWater;GrabWater;1;0;Create;True;0;0;False;0;Object;-1;True;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;28;-76.13652,-172.3118;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RGBToHSVNode;25;128.6529,-458.2219;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;29;193.7859,-171.0587;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;11;-430.5082,-267.4655;Float;False;Property;_ColorFar;Color Far;0;0;Create;True;0;0;False;1;Header(Color Settings);0.1176471,0.3333333,0.4039216,0;0.1176463,0.3570241,0.4039208,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;10;-421.7459,-440.2226;Float;False;Property;_ColorClose;Color Close;1;0;Create;True;0;0;False;0;0.1960784,0.6,0.8392157,0;0.1415975,0.571576,0.7132353,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;27;449.7531,-410.1221;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;65;851.8067,-93.27044;Inherit;False;Property;_StencilMask;Stencil Mask;7;1;[IntRange];Create;True;0;0;False;1;Header(Stencil);228;228;0;255;0;1;FLOAT;0
Node;AmplifyShaderEditor.HSVToRGBNode;26;709.7528,-433.5219;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;12;-74.89443,-294.1148;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;14;1053.143,-305.518;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;66;1132.807,-88.27044;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;67;1313.052,-297.0311;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;75;1418.287,-50.22781;Inherit;False;Property;_ColorSaturation;Color Saturation;2;0;Create;True;0;0;False;0;1;1.0714;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RGBToHSVNode;69;1662.612,-278.5303;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;76;1419.13,25.05942;Inherit;False;Property;_ColorContrast;Color Contrast;3;0;Create;True;0;0;False;0;1;1.25;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;71;1917.41,-243.4293;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.HSVToRGBNode;72;2078.61,-269.4294;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WireNode;77;2267.846,-49.47736;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleContrastOpNode;74;2324.311,-268.1304;Inherit;False;2;1;COLOR;0,0,0,0;False;0;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;2754.083,-306.5802;Float;False;True;-1;7;ASEMaterialInspector;0;0;Unlit;RED_SIM/Water/Underwater Fog;False;False;False;False;False;False;False;False;False;True;False;False;False;False;True;False;False;False;False;False;False;Front;2;False;-1;4;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;False;-2;True;Opaque;;Transparent;ForwardOnly;14;all;True;True;True;True;0;False;-1;True;228;True;65;255;False;-1;255;False;-1;6;False;-1;1;False;-1;1;False;-1;1;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;8;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;8;0;1;0
WireConnection;8;2;3;0
WireConnection;64;0;16;0
WireConnection;9;0;8;0
WireConnection;15;0;9;0
WireConnection;15;1;64;0
WireConnection;28;0;15;0
WireConnection;25;0;13;0
WireConnection;29;0;28;0
WireConnection;29;2;30;0
WireConnection;27;0;25;2
WireConnection;27;1;29;0
WireConnection;26;0;25;1
WireConnection;26;1;27;0
WireConnection;26;2;25;3
WireConnection;12;0;10;0
WireConnection;12;1;11;0
WireConnection;12;2;15;0
WireConnection;14;0;26;0
WireConnection;14;1;12;0
WireConnection;14;2;15;0
WireConnection;66;0;65;0
WireConnection;67;0;14;0
WireConnection;67;1;66;0
WireConnection;69;0;67;0
WireConnection;71;0;69;2
WireConnection;71;1;75;0
WireConnection;72;0;69;1
WireConnection;72;1;71;0
WireConnection;72;2;69;3
WireConnection;77;0;76;0
WireConnection;74;1;72;0
WireConnection;74;0;77;0
WireConnection;0;2;74;0
ASEEND*/
//CHKSM=B5E63ABB56D1FA62C69D563D143EFC6174C77DA6