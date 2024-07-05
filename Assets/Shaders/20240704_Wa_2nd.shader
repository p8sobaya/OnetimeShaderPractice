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

            int N() { return 180; }

            uint intize(float x)
            {
                return uint(x + 0.01);
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }


            const float PI = 3.14159265359;

            float2 rotate2d(float2 v, float a)
            {
                float c = cos(a);
                float s = sin(a);
                return float2(v.x * c - v.y * s, v.x * s + v.y * c);
            }

            float cosBetween(float2 va, float2 vb)
            {
                return dot(va, vb) / length(va) / length(vb);
            }

            float angleBetween(float2 va, float2 vb)
            {
                return acos(cosBetween(va, vb));
            }

            float2 orthographicProjection(float2 origin, float2 direction)
            {
                return dot(origin, direction) / dot(direction, direction) * direction;
            }

            float2 suisenNoAshi(float2 left, float2 right, float2 pt)
            {
                float2 dir = right - left;
                float2 ortho = orthographicProjection(pt - left, dir);
                return left + ortho;
            }

            float modifiedSmoothstep(float x, float a)
            {
                float t = saturate(x < a ? (x / a) * 0.5 : 0.5 + (x - a) / (1 - a) * 0.5);
                return t * t * (3 - 2 * t);
            }

            float SignedPow(float x, float p)
            {
                return sign(x) * pow(abs(x), p);
            }

            float2 makeXY(int i, float pace)
            {
                float fi = float(i) * pace;
                float3 size = float3(0.3, 0.3, 0.3);
                float3 ans3d = 0.5 + size * float3(sin(fi * 1.098 + 0.3 * sin(fi)), sin(fi * 0.897 + 0.3 * sin(fi * 1.32)),
                                  sin(fi * 0.797 + 0.3 * sin(fi * 1.212)));

                ans3d.x = SignedPow((ans3d.x - 0.5) / size.x, 1.3) * size.x + 0.5;
                ans3d.y = SignedPow((ans3d.y - 0.5) / size.y, 1.3) * size.y + 0.5;
                ans3d.z = SignedPow((ans3d.z - 0.5) / size.z, 1.3) * size.z + 0.5;

                ans3d.xyz += 0.15 * float3(sin(fi * 0.32) * sin(fi * 0.24), sin(fi * 0.278) * sin(fi * 0.291), sin(fi * 0.292) * sin(fi * 0.214));
                ans3d.xz = rotate2d(ans3d.xz - 0.5, _Time.y * 0.3) + 0.5;

                return ans3d.xy;
            }

            float barcord(float2 uv)
            {
                float val = sin(uv.y * 6.6 + uv.x * 10.32 + _Time.y * 2.1) + sin(uv.y * 8.64 + uv.x * 0.402 + _Time.y * 1.13) + sin(
                        uv.y * 7.26 + uv.x * 0.411 - _Time.y * 0.9)
                    + (0.5 - abs(uv.y * 1)) * 2;
                val = pow(saturate(val * 0.5 + 1.0), 0.6);
                val *= saturate((1.0 - abs(uv.y)) * (1.4 + 1.2 * sin(uv.x * 4)));
                return val;
            }

            float2 segmentUV(float2 left, float2 right, float breadth, float2 p)
            {
                float2 normal = normalize(float2(-right.y + left.y, right.x - left.x));
                float2 ashi = suisenNoAshi(left, right, p);
                float2 uv = float2(dot(ashi - left, right - left) / dot(right - left, right - left), dot(p - ashi, normal));
                uv.y /= breadth;
                return uv;
            }

            float2 arcUV(float2 left, float2 right, float2 center, float2 radius, float breadth, float2 p)
            {
                float angleLR = angleBetween(left - center, right - center);
                float angleLP = angleBetween(left - center, p - center);
                float angleRP = angleBetween(right - center, p - center);
                if (abs(angleLR - angleLP - angleRP) > 0.01) return float2(-1, -1);
                float u = angleLP / angleLR;
                float r = length(p - center);
                float v = (r - radius) / breadth;
                return float2(u, v);
            }

            bool UVIsInQuad(float2 uv)
            {
                return uv.x >= 0 && uv.x <= 1 && uv.y >= -1 && uv.y <= 1;
            }

            float3 section(uint i, float2 phaseStartGoal, float2 p, float pace, int fromBack)
            {
                float2 leftleft = makeXY(i - 1, pace);
                float2 left = makeXY(i, pace);
                float2 right = makeXY(i + 1, pace);
                float2 rightright = makeXY(i + 2, pace);

                float2 lr = right - left;
                float lenLR = length(lr);
                float2 dirLN = normalize(right - leftleft);
                float2 dirRN = normalize(rightright - left);

                float angleTop = angleBetween(dirLN, -dirRN);
                float angleRight = angleBetween(lr, dirRN);
                float lenLeft = lenLR * sin(angleRight) / sin(angleTop);
                float2 pointTop = left + dirLN * lenLeft;
                float lenRight = length(right - pointTop);

                if (lenLeft > lenRight)
                {
                    float2 pM = pointTop + normalize(left - pointTop) * lenRight;
                    float2 pN = (pM + right) * 0.5;
                    float2 pointDown = pointTop + (pN - pointTop) * pow(cos(angleTop / 2), -2);
                    float angleDown = PI - angleTop;
                    float radius = length(pointTop - pointDown) * sin(angleTop / 2);
                    float arcMR = radius * angleDown;

                    float lenSeg = length(pM - left);
                    float lenTotal = lenSeg + arcMR;
                    float ratioSeg = lenSeg / lenTotal;
                    float ratioArc = arcMR / lenTotal;

                    float breadth = 0.03;
                    float2 uvSeg = segmentUV(left, pM, breadth, p);
                    float2 uvArc = radius < 10 ? arcUV(pM, right, pointDown, radius, breadth, p) : segmentUV(pM, right, breadth, p);


                    //float2 uvArc = segmentUV(pM, right, 0.003, p);

                    float2 uv = float2(-1, -2);

                    if (UVIsInQuad(uvSeg)) uv = uvSeg * float2(ratioSeg, 1);
                        //if(UVIsInQuad(uvSeg)) return float3(1,1,1);
                    else if (UVIsInQuad(uvArc)) uv = float2(ratioSeg, 0) + uvArc * float2(ratioArc, 1);
                    //else if (UVIsInQuad(uvArc)) return float3(1,1,1);
                    //if(UVIsInQuad(segmentUV(left,right ,0.003,p))) return float3(1,0,1);

                    uv.y = abs(uv.y);
                    float2 barcordUv = float2(2, uv.y); //(uv + float2(i, 0)) * float2(pace, 1);

                    if (abs(uv.y) < 1.0)
                    {
                        return float3(1, 1, 1) * barcord(barcordUv) * modifiedSmoothstep(float(float(fromBack) / N()), 0.1);
                        // * modifiedSmoothstep(saturate((uv.x + fromBack) / float(N())), 0.1);   
                    }
                    else
                    {
                        return float3(0, 0, 0);
                    }
                }
                else
                {
                    float2 pM = pointTop + normalize(right - pointTop) * lenLeft;
                    float2 pN = (pM + left) * 0.5;
                    float2 pointDown = pointTop + (pN - pointTop) * pow(cos(angleTop / 2), -2);
                    float angleDown = PI - angleTop;
                    float radius = length(pointTop - pointDown) * sin(angleTop / 2);
                    float arcMR = radius * angleDown;

                    float lenSeg = length(pM - right);
                    float lenTotal = lenSeg + arcMR;
                    float ratioArc = arcMR / lenTotal;
                    float ratioSeg = lenSeg / lenTotal;

                    float breadth = 0.03;
                    float2 uvArc = radius < 10 ? arcUV(left, pM, pointDown, radius, breadth, p) : segmentUV(left, pM, breadth, p);
                    float2 uvSeg = segmentUV(pM, right, breadth, p);

                    float2 uv = float2(-1, -2);

                    if (UVIsInQuad(uvSeg)) uv = float2(ratioArc, 0) + uvSeg * float2(ratioSeg, 1);
                    else if (UVIsInQuad(uvArc)) uv = uvArc * float2(ratioArc, 1);

                    uv.y = abs(uv.y);
                    float2 barcordUv = float2(2, uv.y);
                    (uv + float2(i, 0)) * float2(pace, 1);


                    if (abs(uv.y) < 1.0)
                    {
                        return float3(1, 1, 1) * barcord(barcordUv) * modifiedSmoothstep(float(float(fromBack) / N()), 0.1);
                        // * modifiedSmoothstep(saturate((uv.x + fromBack) / float(N())), 0.1);   
                    }
                    else
                    {
                        return float3(0, 0, 0);
                    }
                }
            }

            fixed4 frag(v2f I) : SV_Target
            {
                float2 p = I.uv.xy;
                float4 col = float4(0.45, 0.45, 0.35, 1);
                col *= p.x > 1.9 ? 1 : 0.75 + 0.25 * clamp(simplex3d(float3(p * 6, _Time.y * 0.5)), -1, 1);

                float t = (_Time.y + 0.8 * sin(_Time.y + 0.54 * sin(_Time.y))) * 3;
                float idf = floor(t);

                uint idi = intize(idf);
                float pace = 0.45;
                int n = N();

                for (int i = n - 1; i >= 0; i--)
                {
                    float2 startGoal = float2(0.0, 1.0);
                    if (i == n - 1) startGoal.y = fmod(t, 1.0);
                    if (i == 0) startGoal.x = fmod(t, 1.0);
                    float2 denseLR = float2(0.1, 0.1);
                    col.xyz *= 1 - section(idi + i, startGoal, p, pace, i);
                }


                return col;
            }
            ENDCG
        }
    }
}