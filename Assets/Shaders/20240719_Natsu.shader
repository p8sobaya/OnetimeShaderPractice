Shader "Unlit/20240719_Natsu"
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

            struct Point
            {
                int id;
                int state;
                float life;
                float3 pos;
                float3 dir;
                float3 col;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;


            float _pa0;
            float _pa1;
            float _pa2;
            float _pa3;
            float _pa4;
            float _pa5;

            float3 _v0;
            float3 _v1;
            float3 _v2;
            float3 _v3;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            /////
            //
            //
            //
            //
            //
            /////

            float RatioInnerForOuter() { return 0.8; }
            float RatioRefraction() { return 0.7; }

            float2 rotate2d(float2 v, float a)
            {
                float c = cos(a);
                float s = sin(a);
                return float2(v.x * c - v.y * s, v.x * s + v.y * c);
            }

            float3 orthographicProjection(float3 origin, float3 direction)
            {
                return dot(origin, direction) / dot(direction, direction) * direction;
            }

            float3 suisenNoAshi(float3 left, float3 right, float3 pt)
            {
                float3 dir = right - left;
                float3 ortho = orthographicProjection(pt - left, dir);
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

            float3 reflect3(float3 dir, float3 n)
            {
                return dir - 2 * dot(dir, n) * n;
            }

            float4 reflact3(float3 dir, float3 n, float ratio)
            {
                float3 verti = orthographicProjection(dir, n);
                float3 horz = dir - verti;
                float3 prevTan = length(horz) / length(verti);
                float3 prevSin = prevTan / sqrt(1 + prevTan * prevTan);
                float3 nextSin = prevSin * ratio;

                if (nextSin >= 1.0) return float4(reflect3(dir, normalize(n)), -1);

                float3 nextTan = nextSin / sqrt(1 - nextSin * nextSin);
                float3 nextDir = normalize(verti + horz * (nextTan / prevTan));
                return float4(nextDir, 1.0);
            }

            float4 centerRads(int id)
            {
                switch (id)
                {
                case 0:
                    return float4(2, -1, 4, 1);
                case 1:
                    return float4(-2.5, 1, 3, 1);
                case 2:
                    return float4(2, 2, 2, 1);
                case 3:
                    return float4(-1, 1, 4, 1);
                case 4:
                    return float4(0, 0.5, 5, 1);
                case 5:
                    return float4(0, 0, 3, 1);
                default:
                    return 0.0;
                }
            }

            float4 distUntilSphere(Point po, int id)
            {
                float3 h = suisenNoAshi(po.pos, po.pos + po.dir, centerRads(id).xyz);
                float d = length(h - centerRads(id).xyz);

                float r = centerRads(id).w;
                if (r <= d) return float4(0, 0, 0, 999999);

                float layLen = length(po.pos - h) - sqrt(r * r - d * d);
                float3 next = po.dir * layLen + po.pos;
                return float4(next, layLen);
            }

            float4 distUntilInner(Point po, int id)
            {
                float4 cr = centerRads(po.id);
                float3 h = suisenNoAshi(po.pos, po.pos + po.dir, cr.xyz);
                float d = length(h - cr.xyz);

                float r = cr.w * RatioInnerForOuter();
                if (r <= d) return float4(0, 0, 0, 1e8);

                float layLen = length(po.pos - h) - sqrt(r * r - d * d);
                float3 next = po.dir * layLen + po.pos;
                return float4(next, layLen);
            }

            float3 nextDir0To1(int id, float3 dir, float3 pos)
            {
                float3 center = centerRads(id).xyz;
                float3 nextDir = reflact3(dir, normalize(pos - center), RatioRefraction());
                return nextDir;
            }

            Point nextPointFrom1(Point po)
            {
                float4 cr = centerRads(po.id);
                float h = suisenNoAshi(po.pos, po.pos + po.dir, cr.xyz);

                float4 nl = distUntilInner(po, po.id);

                if (nl.w > 9999)
                {
                    po.state = 0;
                    float3 nextPos = po.pos + 2 * (h - po.pos);
                    float3 nextN = normalize(nextPos - cr.xyz);
                    float3 verti = orthographicProjection(po.dir, nextN);
                    float3 hori = po.dir - verti;

                    float prevSin = length(hori) / length(po.dir);
                    float nextSin = prevSin / 0.7;
                    float nextTan = sqrt(nextSin * nextSin / (1 - nextSin * nextSin));
                    po.dir = normalize(verti + hori * nextTan);

                    po.pos = po.pos + 2 * (h - po.pos);

                    po.col += po.life * 0.05 * float3(0.4, 0.4, 1);
                    po.life *= 0.95;
                    return po;
                }
                else
                {
                    float3 n = normalize(nl.xyz - cr.xyz);
                    float3 verti = orthographicProjection(po.dir, n);
                    float3 hori = po.dir - verti;

                    float prevSin = length(hori) / length(po.dir);
                    float nextSin = prevSin / 0.7;
                    if (nextSin >= 1.0)
                    {
                        po.state = 1;
                        po.dir = reflect(po.dir, n);
                        po.pos = nl.xyz;
                        po.col += po.life * 0.05 * float3(0.4, 0.4, 1);
                        po.life *= 0.95;
                        return po;
                    }
                    else
                    {
                        float nextTan = sqrt(nextSin * nextSin / (1 - nextSin * nextSin));
                        po.dir = normalize(verti + hori * nextTan);
                        po.pos = nl.xyz;
                        po.state = 2;
                        po.col += po.life * 0.05 * float3(0.4, 0.4, 1);
                        po.life *= 0.95;
                        return po;
                    }
                }
            }

            float3 surfaceCol(int id, float3 pos)
            {
                return normalize(pos + 1.0);
            }


            float3 bgcolor(float3 dir)
            {
                return dir.y < 0 ? float3(0.2, 0.3, 0) : float3(0.6, 0.5, 0.4) * (1 - dir.y) + float3(0.3, 0.5, 0.7) * dir.y;
            }

            float4 frag(v2f ii) : SV_Target
            {
                float4 col = float4(0, 0, 0, 1);
                float2 p = ii.uv * 2.0 - 1.0;

                float3 cam = float3(0, 0, 5 * sin(_Time.y));
                float3 camU = float3(1, 0, 0);
                float3 camV = float3(0, 1, 0);
                float3 fwd = float3(0, 0, 1);
                float3 scrP = cam + p.x * camU + p.y * camV + fwd * 1;
                float3 dir = normalize(scrP - cam);

                Point po = (Point)0;
                po.id = -1;
                po.life = 1.0;
                po.pos = scrP;
                po.dir = dir;
                po.state = 0; // 0:out 1:glass 2:in
                po.col = float3(0, 0, 0);

                for (int i = 0; i < 40; i++)
                {
                    if (po.state == 0)
                    {
                        float nearest = 10000;
                        int idxNearest = -1;
                        Point pn = (Point)0;

                        for (int j = 0; j < 6; j++)
                        {
                            if (dot(po.dir, centerRads(j).xyz - po.pos) < 0) continue;

                            float4 next = distUntilSphere(po, j);

                            if (next.w < nearest)
                            {
                                nearest = next.w;
                            }
                        }

                        if (idxNearest == -1)
                        {
                            po.col += po.life * bgcolor(po.dir);
                            break;
                        }
                        else
                        {
                            int j = idxNearest;
                            float4 cr = centerRads(j);
                            pn.id = j;
                            pn.pos = next.xyz;
                            pn.state = 1;

                            pn.dir = nextDir0To1(j, po.dir, po.pos);
                            pn.col = po.col;
                            pn.col += po.life * 0.15 * surfaceCol(j, (pn.pos - cr.xyz) / cr.w);
                            pn.col += po.life * 0.15 * bgcolor(pn.dir);
                            pn.life = po.life * 0.7;
                        }

                        po = pn;
                    }
                    else if (po.state == 1)
                    {
                        po = nextPointFrom1(po);
                    }
                    else
                    {
                        float3 h = suisenNoAshi(po.pos, po.pos + po.dir, centerRads(po.id).xyz);
                        float3 nextPos = 2 * (h - po.pos) + po.pos;
                        float3 nextN = normalize(nextPos - centerRads(po.id).xyz);
                        float3 verti = orthographicProjection(po.dir, nextN);
                        float3 hori = po.dir - verti;

                        float prevSin = length(hori) / length(po.dir);
                        float nextSin = prevSin * 0.7;
                        float nextTan = sqrt(nextSin * nextSin / (1 - nextSin * nextSin));
                        po.dir = normalize(verti + hori * nextTan);
                        po.pos = nextPos;
                        po.state = 1;
                        // col,life
                    }
                }

                col.xyz = po.col;
                return col;
            }
            ENDCG
        }
    }
}