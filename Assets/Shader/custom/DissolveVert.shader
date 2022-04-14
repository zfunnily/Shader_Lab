Shader "Custom/DissolveVert"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("Noise", 2D) = "white" {}
		_RampTex("RampTex", 2D) = "white" {}
		_Threshold("Threshold", Range(0.0, 1.0)) = 0.5

		_EdgeLength("Edge Length", Range(0.0, 0.2)) = 0.1
		_EdgeFirstColor("First Edge Color", Color) = (1,1,1,1)
		_EdgeSecondColor("Second Edge Color", Color) = (1,1,1,1)

		_DisappearOffset ("Disappear Offset",Range(-0.5,0.5)) = 0.5
		_Direction("Direction", Int) = 1 //1表示从X正方向开始，其他值则从负方向
		_MinBorderX("Min Border X", Float) = -0.5 //可从程序传入
        _MaxBorderX("Max Border X", Float) = 0.5  //可从程序传入
		_StartPoint("Start Point", Vector) = (0, 0, 0, 0) //消融开始的点
		_MaxDistance("Max Distance", Float) = 1
		_DistanceEffect("Distance Effect", Range(0.0, 1.0)) = 0.5
	}
	SubShader
	{
		Tags { "Queue"="Geometry" "RenderType"="Opaque" }

		Pass
		{
			Cull Off //要渲染背面保证效果正确

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
				float2 uvNoiseTex : TEXCOORD1;
				float4 objPosX: TEXCOORD2;
				float4 objStartPos: TEXCOORD3;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			sampler2D _RampTex;
			float _Threshold;

			float _EdgeLength;
			fixed4 _EdgeFirstColor;
			fixed4 _EdgeSecondColor;

			int _Direction;
 			float _MinBorderX;
            float _MaxBorderX;
			half4 _StartPoint;
			float _MaxDistance;
			float _DistanceEffect;
			float _DisappearOffset;


			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uvMainTex = TRANSFORM_TEX(v.uv, _MainTex);
				o.uvNoiseTex = TRANSFORM_TEX(v.uv, _NoiseTex);

				//把点都转移到模型空间
				o.objPosX = v.vertex.x;
				o.objStartPos = mul(unity_WorldToObject, _StartPoint);
				
				// o.uvMainTex.z = _DisappearOffset - v.vertex.y;

				return o;
			}
			/*常用函数
			1. saturate 当你想将颜色值规范到0~1之间时，你可能会想到使用saturate函数（saturate(x)的作用是如果x取值小于0，则返回值为0。如果x取值大于1，则返回值为1。若x在0到1之间，则直接返回x的值.）
			2. lerp 一个混合公式，他们俗称插值， 只不过w相当于以第二个参数为源，第一个参数为目标。 
			3. tex2D, 这是CG程序中用来在一张贴图中对一个点进行采样的方法 返回一个float4 . 即找到贴图上 对应的uv点，直接使用颜色信息来进行着色
			*/
			
			// fixed4 frag (v2f i) : SV_Target
			// {
			// 	//求出片元到开始点的距离
			// 	float dist = length(i.objPos.xyz - i.objStartPos);
			// 	float normalizedDist = saturate(dist/_MaxDistance);

			// 	// fixed cutout = tex2D(_NoiseTex, i.uvNoiseTex).r;
			// 	// clip(cutout - _Threshold);
			// 	fixed cutout = tex2D(_NoiseTex, i.uvNoiseTex).r * (1 - _DistanceEffect) + normalizedDist * _DistanceEffect;
			// 	clip(cutout - _Threshold);

			// 	float degree = saturate((cutout - _Threshold) / _EdgeLength);
			// 	fixed4 edgeColor = tex2D(_RampTex, float2(degree, degree));

			// 	fixed4 col = tex2D(_MainTex, i.uvMainTex);

			// 	fixed4 finalColor = lerp(edgeColor, col, degree);
			// 	return fixed4(finalColor.rgb, 1);
			// }

			fixed4 frag (v2f i) : SV_Target
            {
				// clip(i.uvMainTex.z);

                float range = _MaxBorderX - _MinBorderX;
                float border = _MinBorderX;
                if(_Direction == 1) //1表示从X正方向开始，其他值则从负方向
                    border = _MaxBorderX;

                float dist = abs(i.objPosX - border);
                float normalizedDist = saturate(dist / range);

                fixed cutout = tex2D(_NoiseTex, i.uvNoiseTex).r * (1 - _DistanceEffect) + normalizedDist * _DistanceEffect;

                clip(cutout - _Threshold);

                float degree = saturate((cutout - _Threshold) / _EdgeLength);

                fixed4 edgeColor = tex2D(_RampTex, float2(degree, degree));

                fixed4 col = tex2D(_MainTex, i.uvMainTex.xy);
                fixed4 finalColor = lerp(edgeColor, col, degree);
                return fixed4(finalColor.rgb, 1);

            }
			ENDCG
		}
	}
}
