/*
纹理颜色: https://www.jianshu.com/p/d8b535efa9db
*/
Shader "URP/DissolveVert"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("Noise", 2D) = "white" {}
		_RampTex("Gradual Texture", 2D) = "white" {}
		_Threshold("Threshold", Range(-5.0, 5.0)) = 0 
		_EdgeLength("Edge Length", Range(0.0, 0.2)) = 0.1
		// [Toggle]_X("X 轴", Int) = 0
		[Toggle]_ModelToggle("Model Toggle", Int) = 0
		[KeywordEnum(NX, X, NY, Y, NS, S)] _Dissolve ("消融方向", Float) = 0.0

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		HLSLINCLUDE
		#pragma vertex vert
		#pragma fragment frag
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
		#pragma shader_feature _MODELTOGGLE_ON
		#pragma multi_compile _DISSOLVE_NX _DISSOLVE_X  _DISSOLVE_NY _DISSOLVE_Y _DISSOLVE_NS _DISSOLVE_S 

		CBUFFER_START(UnityPerMaterial)
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			sampler2D _RampTex;
			float4 _RampTex_ST;

			float _Threshold;
			float _EdgeLength;
			float4 _EdgeColor;
			float4 _EdgeFirstColor;
			float4 _EdgeSecondColor;

		CBUFFER_END

		ENDHLSL

		Pass
		{
			// Cull Off //要渲染背面保证效果正确

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal: NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uvMainTex : TEXCOORD0;
				float3 uvNoiseTex : TEXCOORD1;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex);
				o.uvMainTex = TRANSFORM_TEX(v.uv, _MainTex);
				o.uvNoiseTex.xy = TRANSFORM_TEX(v.uv, _NoiseTex);

				//因为模型空间中y值范围为(-0.5,0.5)，所以还需要进行偏移以保证裁剪的正确
				float4 udef = o.vertex;
				#if _MODELTOGGLE_ON
				udef = v.vertex;
				#endif

				#if _DISSOLVE_NX
				o.uvNoiseTex.z = _Threshold - udef.x; 
				#elif _DISSOLVE_X
				o.uvNoiseTex.z = _Threshold + udef.x; //调整这里来改变消失轴向 
				#elif _DISSOLVE_NY
				o.uvNoiseTex.z = _Threshold + udef.y; 
				#elif _DISSOLVE_Y
				o.uvNoiseTex.z = _Threshold - udef.y; 
				#elif _DISSOLVE_NS
				o.uvNoiseTex.z = _Threshold - udef.z;
				#elif _DISSOLVE_S
				o.uvNoiseTex.z = _Threshold + udef.z;
				#endif
				
				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				float cutout = tex2D(_NoiseTex, i.uvNoiseTex.xy).r;
				float z = lerp(i.uvNoiseTex.z, cutout, 0.3); //按方向消融 + 噪声图
				// z = i.uvNoiseTex.z; //按方向消融 没有噪声图
				// z = _Threshold-cutout; //四散消融
				clip(z);

				//用两个颜色 来控制消融
				// float degree = saturate((_Threshold - cutout) / _EdgeLength); //需要保证在[0,1]以免后面插值时颜色过亮
				// float4 edgeColor = lerp(_EdgeFirstColor, _EdgeSecondColor, degree);

				//渐变色
				float degree = saturate(z / _EdgeLength);
				float4 edgeColor = tex2D(_RampTex, float2(degree, degree));

				float4 col = tex2D(_MainTex, i.uvMainTex);

				float4 finalColor = lerp(edgeColor, col, degree);
				return float4(finalColor.rgb, 1);
			}

			ENDHLSL
		}
	}
}
