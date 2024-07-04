Shader "Unlit/20240704_Wa"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"
            #include "SimplexNoise.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            int N(){return 120;}

            uint intize(float x)
            {
                return uint(x+0.01);
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }












            

            float2 rotate2d(float2 v, float a)
            {
                float c = cos(a);
                float s = sin(a);
                return float2(v.x*c - v.y*s, v.x*s + v.y*c);
            }

            float2 orthographicProjection(float2 origin, float2 direction)
            {
                return dot(origin, direction)/dot(direction, direction)*direction;
            }

            float2 suisenNoAshi(float2 left, float2 right, float2 pt)
            {
                float2 dir = right - left;
                float2 ortho = orthographicProjection(pt - left, dir);
                return left + ortho;
            }

            float modifiedSmoothstep(float x, float a)
            {
                
                float t = saturate(x<a ? (x/a)*0.5 : 0.5 + (x-a)/(1-a)*0.5);
                return t*t*(3-2*t);
            }

            float SignedPow(float x, float p)
            {
                return sign(x)*pow(abs(x),p);
            }

            float2 makeXY(int i,float pace)
            {
                float fi = float(i)*pace;
                float3 size = float3(0.45,0.45,0.45);
                float3 ans3d = 0.5 + size*float3(sin(fi*1.098 + 0.3*sin(fi)),sin(fi*0.897 + 0.3*sin(fi*1.32)),sin(fi*0.797 + 0.3*sin(fi*1.212)));
                float2 ans2d = ans3d.xy;
                ans3d.x = SignedPow((ans3d.x-0.5)/size.x, 2.1)*size.x + 0.5;
                ans3d.y = SignedPow((ans3d.y-0.5)/size.y, 2.1)*size.x + 0.5;
                ans3d.z = SignedPow((ans3d.z-0.5)/size.z, 2.1)*size.x + 0.5;
                ans3d.xz = rotate2d(ans3d.xz-0.5, _Time.y*0.3) + 0.5;
                
                return ans3d.xy;
            }

            float barcord(float2 uv)
            {
                float val = sin(uv.y*13.6 + uv.x*10.32) + sin(uv.y*14.64 + uv.x*0.402) + sin(uv.y*6.26 + uv.x*0.411) + (0.5-abs(uv.y*1))*2;
                val = pow(saturate(val*0.5+1.0),0.6);
                val *= saturate((1.0 - abs(uv.y))*(2+1.2*sin(uv.x*4)));
                return val;
            }

            float3 segment(uint i, float2 phaseStartGoal, float2 p, float pace, int fromBack)
            {
                float2 left = makeXY(i, pace);
                float2 right = makeXY(i+1, pace);
                float2 dir = right - left;
                float2 normal = normalize(float2(-dir.y, dir.x));
                float2 ashi = suisenNoAshi(left, right, p);
                //if(length(p-ashi)<0.03) return float3(1,0,0);
                float2 uv = float2(dot(ashi-left,dir)/dot(dir,dir), dot(p-ashi, normal));
                float breadth = 0.03 + 0.01*sin(i+uv.x);
                uv.y /= breadth;
                return phaseStartGoal.x < uv.x && uv.x < phaseStartGoal.y && abs(uv.y)<1.0 ?
                    float3(1,1,1) * barcord((uv+float2(i,0))*float2(pace,1)) * modifiedSmoothstep(saturate((uv.x+fromBack)/float(N())), 0.1):
                    float3(0,0,0);
            }

            fixed4 frag(v2f I) : SV_Target
            {
                float2 p = I.uv.xy;
                float4 col = float4(0.45, 0.45, 0.35, 1);
                col *= p.x>1.9 ? 1 : 0.75+0.25*clamp(simplex3d(float3(p*6,_Time.y*0.5)),-1,1);

                float t = (_Time.y + 0.8*sin(_Time.y + 0.54*sin(_Time.y)))*3;
                float idf = floor(t);

                uint idi = intize(idf);
                float pace = 0.22;
                int n = N();

                for(int i=n-1; i>=0; i--)
                {
                    float2 startGoal = float2(0.0,1.0);
                    if(i==n-1) startGoal.y = fmod(t,1.0);
                    if(i==0) startGoal.x = fmod(t,1.0);
                    float2 denseLR = float2(0.1,0.1);
                    col.xyz *= 1-segment(idi+i, startGoal, p, pace, i);
                }

                
                
                

                

                return col;
            }
            ENDCG
        }
    }
}