Shader "Unlit/mandelbulb" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            #define Pi 3.14159265359
            #define ViewStart 1.6
            #define ViewEnd 4.4
            
            int CameraRaySteps;
            int ShadowRaySteps;
            float MaxTransparency;
            float FocalLength;
            float Density;
            float Anisotropy;
            float3 DirCam;
            float3 PosCam;
            float3 LightColor;
            float3 LightPos;
            float3 VolumeColor;
            float Power;

            float3 powV(float3 v, float p){
                return float3(pow(v.x, p), pow(v.y, p), pow(v.z, p));
            }

            float maxV(float3 v){
                return max(max(v.x, v.y), v.z);
            }

            bool insideShape(float3 pos) {
                float3 z = pos;
                float r;
                float zr;
                float sinTheta;
                float phi;
                float theta;
                for(int i = 0; i < 4; i++) {
                    r = length(z);
                    if(r>1.3) break;
                    theta = acos(z.z/r)*Power;
                    phi = atan(z.y/z.x)*Power;
                    sinTheta = sin(theta);
                    z = pow(r,Power)*float3(sinTheta*float2(cos(phi), sin(phi)), cos(theta)) + pos;
                }
                return r < 1.0 && r > .65;
            }

            float henyeyGreenstein(float3 pos, float3 dir){
                float cosTheta = dot(dir, normalize(LightPos-pos));
                return Pi/4.0 * (1.0-Anisotropy*Anisotropy) / pow(1.0 + Anisotropy*Anisotropy - 2.0*Anisotropy*cosTheta, 3.0/2.0);
            }

            float3 lightReceived(float3 pos, float headStart){
                float LightDist = length(LightPos-pos);
                float3 LightDir = normalize(LightPos-pos);
                float stepSize = LightDist / float(ShadowRaySteps);
                float3 absorption = float3(1,1,1);

                pos += headStart * LightDir * stepSize;
                for(int i = 0; i < ShadowRaySteps; i++){
                    if(insideShape(pos)){
                        absorption *= powV(float3(1,1,1)-VolumeColor, stepSize*Density);
                    }
                    pos += LightDir * stepSize;
                }
                return absorption*LightColor / (LightDist*LightDist);
            }


            float3 rotateZ(float3 p, float angle){
                return float3(
                cos(angle) * p.x + sin(angle) * p.y,
                -sin(angle) * p.x + cos(angle) * p.y,
                p.z);
            }
            
            fixed4 frag (v2f i) : SV_Target {
                LightColor = float3(1.5, 1.5, 1.5);
                VolumeColor = float3(.1, .15, .2);
                FocalLength = 1.0;
                Density = 25.0;
                Anisotropy = .25;
                CameraRaySteps = 128;
                ShadowRaySteps = 16;
                MaxTransparency = .7;

                DirCam = rotateZ(normalize(float3(-1, 0, 0)), -_Time.y/3.0);
                PosCam = rotateZ(float3(3.0, 0, .0), -_Time.y/3.0);
                Power = abs(cos(_Time.y/5.0)) * 7.0 + 1.0;
                LightPos = float3(cos(_Time.y/2.0),-sin(_Time.y/2.0),cos(_Time.y/1.0)) * 1.25;
                
                float2 uv = (i.uv.xy - _ScreenParams.xy/2.0)/_ScreenParams.y;
                
                float3 camX = float3(-DirCam.y, DirCam.x, 0);
                float3 camY = cross(camX, DirCam);
                float3 sensorX = camX * (uv.x/length(camX));
                float3 sensorY = camY * (uv.y/length(camY));
                float3 centerSensor = PosCam - DirCam * FocalLength;
                float3 posOnSensor = centerSensor + sensorX + sensorY;
                float3 dir = normalize(PosCam - posOnSensor);
                
                float3 pos = PosCam + dir*ViewStart;
                float hg = henyeyGreenstein(pos, dir);
                float3 color;
                
                float stepSize = (ViewEnd-ViewStart) / float(CameraRaySteps);
                float3 absorption = float3(1,1,1);
                
                // float headStart = texture(iChannel0, i.uv/float2(1024)).a;
                float headStart = frac(sin(dot(i.uv.xy/1024, float2(12.9898, 4.1414))) * 43758.5453);
                
                pos += headStart * dir * stepSize;
                
                for(int i = 0; i < CameraRaySteps; i++){
                    if(length(LightPos-pos) <.05){
                        color += 10.0*absorption*LightColor;
                        break;
                    }
                    if(insideShape(pos)){
                        color += VolumeColor*absorption*lightReceived(pos, headStart)*hg*stepSize*Density;
                        absorption *= powV(float3(1,1,1)-VolumeColor, stepSize*Density);
                    }
                    pos += dir * stepSize;
                    if(maxV(absorption) < 1.0-MaxTransparency) break;
                }
                
                float4 col = float4(log(color + float3(1,1,1)), 1.0);
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }

            ENDCG
        }
    }
}