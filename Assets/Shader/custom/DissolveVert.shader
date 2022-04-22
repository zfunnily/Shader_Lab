Shader "Custom/DissolveVert"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("Noise", 2D) = "white" {}
		_Threshold("Threshold", Range(-2.0, 2.0)) = 0.5

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }

		Pass
		{
			// Cull Off //要渲染背面保证效果正确

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
				float4 vertex : SV_POSITION;
				float2 uvMainTex : TEXCOORD0;
				float3 uvNoiseTex : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			float _Threshold;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uvMainTex = TRANSFORM_TEX(v.uv, _MainTex);
				o.uvNoiseTex.xy = TRANSFORM_TEX(v.uv, _NoiseTex);

				//因为模型空间中y值范围为(-0.5,0.5)，所以还需要进行偏移以保证裁剪的正确
				o.uvNoiseTex.z = _Threshold - o.vertex.y ; //调整这里来改变消失轴向 

				return o;
			}
			/*常用函数
			1. saturate 当你想将颜色值规范到0~1之间时，你可能会想到使用saturate函数（saturate(x)的作用是如果x取值小于0，则返回值为0。如果x取值大于1，则返回值为1。若x在0到1之间，则直接返回x的值.）
			2. lerp 一个混合公式，他们俗称插值， 只不过w相当于以第二个参数为源，第一个参数为目标。 
			3. tex2D, 这是CG程序中用来在一张贴图中对一个点进行采样的方法 返回一个float4 . 即找到贴图上 对应的uv点，直接使用颜色信息来进行着色
			*/
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed cutout = tex2D(_NoiseTex, i.uvNoiseTex.xy).r;
				//clip(_Threshold - cutout); //四散消融
				clip(lerp(i.uvNoiseTex.z, cutout, -1)); //按方向消融 + 噪声图
				// clip(i.uvNoiseTex.z);//按方向消融 没有噪声图

				return tex2D(_MainTex, i.uvMainTex);
			}

			ENDCG
		}
	}
}
