/*

https://blog.csdn.net/a672934675/article/details/103940578
*/
Shader "URP/Explosion"
{
	Properties
	{
		_MainTex("Main Tex", 2D) = "white" {}
		_Color("Color Tint", Color) = (1,1,1,1)
		_Emission1("Emission1", Color) = (1,1,1,1)
		_Emission2("Emission2", Color) = (1,1,1,1)
		_Height("Height", Range(-2.5, 0.5)) = 0
		_TotalHeight("Total Height", Float) = 1
		_Strength("Explosion Strenth", Range(0, 20)) = 2
		_Scale("Scale", Range(0, 5)) = 1
	}
    SubShader
    {
        Tags{"Queue"="Geometry" "RenderType"="Opaque" "IgnoreProjector"="True" "RenderPipeline"="UniversalPipeline"} 
		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			CBUFFER_START(UnityPerMaterial)
				sampler2D _MainTex;
				float4 _MainTex_ST;
				real4 _Color;
				real4 _Emission1;
				real4 _Emission2;
				float _Height;
				float _TotalHeight;
				float _Strength;
				float _Scale;
			CBUFFER_END;
		ENDHLSL
		Pass
		{
			Tags {"LightMode"="UniversalForward"}
			Cull Off
			HLSLPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag


			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 uv : TEXCOORD0;
			};

			struct v2g
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 uv : TEXCOORD0;
			};

			struct g2f
			{
				float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				float4 uv : TEXCOORD0;
			};

			
			float3 randto3D(float3 seed)
			{
				float3 f = sin(float3(dot(seed, float3(127.1, 337.1, 256.2)), dot(seed, float3(129.8, 782.3, 535.3))
				, dot(seed, float3(269.5, 183.3, 337.1))));
				f = -1 + 2 * frac(f * 43785.5453123);
				return f;
			}

			float rand(float3 seed)
			{
				float f = sin(dot(seed, float3(127.1, 337.1, 256.2)));
				f = -1 + 2 * frac(f * 43785.5453123);
				return f;
			}

			float3x3 AngleAxis3x3(float angle, float3 axis)
			{
				float s, c;
				sincos(angle, s, c);
				float x = axis.x;
				float y = axis.y;
				float z = axis.z;
				return float3x3(
					x * x + (y * y + z * z) * c, x * y * (1 - c) - z * s, x * z * (1 - c) - y * s,
					x * y * (1 - c) + z * s, y * y + (x * x + z * z) * c, y * z * (1 - c) - x * s,
					x * z * (1 - c) - y * s, y * z * (1 - c) + x * s, z * z + (x * x + y * y) * c
				);
			}

			float3x3 rotation3x3(float3 angle)
			{
				return mul(AngleAxis3x3(angle.x, float3(0, 0, 1)), mul(AngleAxis3x3(angle.y, float3(1, 0, 0)), AngleAxis3x3(angle.z, float3(0, 1, 0))));
			}

			v2g vert(a2v v)
			{
				v2g o;
				o.vertex = v.vertex;
				o.normal = v.normal;
				o.uv = v.uv;
				return o;
			}

			g2f VertexOutput(float3 pos, float3 normal, float param, float4 uv)
			{
				g2f o;
				o.pos = TransformObjectToHClip(float4(pos, 1));
				o.normal = TransformObjectToWorldNormal(normal);
				o.uv.xy = TRANSFORM_TEX(uv, _MainTex);
				// o.uv.xy = uv;
				o.uv.z = param;
				o.uv.w = 1;
				return o;
			}

			//单个调用的最大顶点个数
			//以一个三角形为单位进行输入（每次同时输入三个顶点）
			//图元输入：point line lineadj triangle triangleadj
			//以线的形式进行输出
			//图元输出：PointStream LineStream TriangleStream
			[maxvertexcount(3)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
			{
				float3 p0 = IN[0].vertex.xyz;
				float3 p1 = IN[1].vertex.xyz;
				float3 p2 = IN[2].vertex.xyz;

				float3 n0 = IN[0].normal;
				float3 n1 = IN[1].normal;
				float3 n2 = IN[2].normal;

				float4 uv1 = IN[0].uv;
				float4 uv2 = IN[1].uv;
				float4 uv3 = IN[2].uv;

				float3 center = (p0 + p1 + p2) / 3;
				float offset = (center.y - _Height) * _TotalHeight;

				if (offset < 0)
				{
					triStream.Append(VertexOutput(p0, n0, -1, uv1));
					triStream.Append(VertexOutput(p1, n1, -1, uv2));
					triStream.Append(VertexOutput(p2, n2, -1, uv3));
					triStream.RestartStrip();
					return;
				}

				else if (offset > 3)
					return;

				float ss_offset = smoothstep(0, 1, offset);

				float3 translation = (n0 + n1 + n2) / 3 * ss_offset * _Strength;
				float3x3 rotationMatrix = rotation3x3(rand(center.zyx));
				float scale = _Scale - ss_offset;

				float3 t_p0 = mul(rotationMatrix, p0 - center) * scale + center + translation;
				float3 t_p1 = mul(rotationMatrix, p1 - center) * scale + center + translation;
				float3 t_p2 = mul(rotationMatrix, p2 - center) * scale + center + translation;
				float3 normal = normalize(cross(t_p1 - t_p0, t_p2 - t_p0));

				triStream.Append(VertexOutput(t_p0, normal, ss_offset, uv1));
				triStream.Append(VertexOutput(t_p1, normal, ss_offset, uv2));
				triStream.Append(VertexOutput(t_p2, normal, ss_offset, uv3));
				triStream.RestartStrip();
			}

			real4 frag(g2f i) : SV_TARGET
			{
				// return real4(0,0,0,1);
				float4 tex_col = tex2D(_MainTex, i.uv);
				// float z = i.uv.z;
				// real4 color = step(0, z) * _Emission1 + step(z, 0) * _Color ;

				// if(z > 0)
				// 	color = lerp(color, _Emission2, z);

				return tex_col;
			}
			ENDHLSL
		}      
    }
    Fallback "Universal Render Pipeline/Particles/Lit"
}

