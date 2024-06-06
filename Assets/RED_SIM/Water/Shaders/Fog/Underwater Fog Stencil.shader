// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "RED_SIM/Water/Underwater Fog Stencil"
{
	Properties
	{
		[IntRange][Header(Stencil)]_StencilMask("Stencil Mask", Range( 0 , 255)) = 228
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "AlphaTest+1" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		ZWrite Off
		ZTest GEqual
		Stencil
		{
			Ref [_StencilMask]
			Comp Always
			Pass Replace
			Fail Keep
			ZFail Keep
		}
		Blend One One
		
		CGPROGRAM
		#pragma target 5.0
		#pragma surface surf Unlit keepalpha noshadow nofog 
		struct Input
		{
			half filler;
		};

		uniform float _StencilMask;

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float3 temp_cast_0 = (( _StencilMask * 0.0 )).xxx;
			o.Emission = temp_cast_0;
			o.Alpha = 1;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=17500
1927;31;1906;987;1171.457;276.1823;1;True;False
Node;AmplifyShaderEditor.RangedFloatNode;3;-430.8724,42.2753;Inherit;False;Property;_StencilMask;Stencil Mask;1;1;[IntRange];Create;True;0;0;False;1;Header(Stencil);228;228;0;255;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;5;-151.8724,47.2753;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;0,0;Float;False;True;-1;7;ASEMaterialInspector;0;0;Unlit;RED_SIM/Water/Underwater Fog Stencil;False;False;False;False;False;False;False;False;False;True;False;False;False;False;True;False;False;False;False;False;False;Back;2;False;9;4;False;-1;False;0;False;-1;0;False;-1;False;7;Custom;0.5;True;False;1;True;Opaque;;AlphaTest;All;14;all;True;True;True;True;0;False;-1;True;228;True;3;255;False;3;255;False;3;7;False;-1;3;False;-1;1;False;-1;1;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;4;1;False;-1;1;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;5;0;3;0
WireConnection;0;2;5;0
ASEEND*/
//CHKSM=3CB1A94A286BC9322A8581CB41D3CD3E0E82264F