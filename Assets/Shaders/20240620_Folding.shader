Shader "Unlit/20240620_Folding"
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

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }


           
            float3 originalPicture(float2 uv,int depth)
            {
                float interval = 1.0/64.0;
                bool lines = fmod(uv.x+uv.y+interval*0.25*sqrt(2), interval) < interval/3.0;
                bool circles = fmod(length(uv)+interval/4.0, interval) < interval/2.0;
                return circles ? float3(1,0.4+0.2*(depth%3)*0,0) : float3(0,0,0);
            }

            float2 foldByDepth(float2 uv, int depth)
            {
                float2 result = uv;
                float freq = float(1 << depth);
                float size = 1.0 / freq;
                result.x = fmod(result.x, size);
                result.x = result.x < size / 2.0 ? result.x : size - result.x;
                //result.x = result.x * freq;
                result.y = fmod(result.y, size);
                result.y = result.y < size / 2.0 ? result.y : size - result.y;
                return result;
            }

            float2 leftDownByDepth(float2 uv, int depth)
            {
                float2 result = uv;

                float freq = float(1 << depth);
                float size = 1.0 / freq;

                result.x -= fmod(result.x, size);
                result.y -= fmod(result.y, size);
                
                return result;
            }

            float2 rotate2d(float2 v, float a)
            {
                float c = cos(a);
                float s = sin(a);
                return float2(v.x*c - v.y*s, v.x*s + v.y*c);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float4 col = float4(0, 0, 0, 1);

                float2 p = i.uv;
                p = rotate2d(p-0.5, _Time.y*0.2)+ 0.5;
                p += 0.5;
                p += 0.00*float2(simplex3d(float3(i.uv+_Time.y*0.03, _Time.y*0.21)), simplex3d(float3(i.uv.yx+_Time.y*0.03, _Time.y*0.181+100.0)));

                float2 toSee = p;

                int depth = 0;
                for (int j = 0; j < 6; j++)
                {
                    float2 uv = p;

                    float r = simplex3d(float3(leftDownByDepth(p,j)*10.0,0) + float3(j*10, j*10, _Time.y/(j+1)))*0.5+0.5;
                    if (r < pow(0.05*j,0.35)+0.02)
                    {
                        break;
                    }
                    depth++;
                }

                toSee = foldByDepth(toSee, depth);
                col.xyz = originalPicture(toSee, depth);
                return col;
            }
            ENDCG
        }
    }
}