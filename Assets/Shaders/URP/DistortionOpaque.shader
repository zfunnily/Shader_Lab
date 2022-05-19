/*
热扰动（热扭曲）效果的实现： https://blog.csdn.net/zakerhero/article/details/107635481

_cameraOpaqueTexture does not render any URP sprite:
https://forum.unity.com/threads/scene-color-shadergraph-node-_cameraopaquetexture-with-urp-2d-lighting.757985/

半透明: https://www.bilibili.com/read/cv15512651
*/

Shader "URP/DistortionOpaque" 
{
	Properties {
		_NoiseTex ("Noise Texture (RG)", 2D) = "white" {}
		_HeatTime  ("Heat Time", range (0,1)) = 0.1
		_HeatForce  ("Heat Force", range (0,0.1)) = 0.008
	}

	SubShader {
		Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline"="UniversalPipeline"}
		Blend SrcAlpha OneMinusSrcAlpha
		//AlphaTest Greater .01
		Cull Off 
		Lighting Off 
		//ZTest Off
		ZWrite Off
		Pass {
			Tags { "LightMode" = "UniversalForward"}
			
			HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

				struct appdata_t {
					float4 vertex : POSITION;
					float4 color : COLOR;
					float2 texcoord: TEXCOORD0;
				};

				struct v2f {
					float4 vertex : POSITION;
					float4 uvgrab : TEXCOORD0;
					float2 uvmain : TEXCOORD1;
				};

				float _HeatForce;
				float _HeatTime;
				float4 _NoiseTex_ST;
				sampler2D _NoiseTex;
				SAMPLER(_CameraOpaqueTexture);

				v2f vert (appdata_t v)
				{
					v2f o;
					VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
					o.vertex = vertexInput.positionCS;

					#if UNITY_UV_STARTS_AT_TOP
					float scale = -1.0;
					#else
					float scale = 1.0;
					#endif

					o.uvmain = TRANSFORM_TEX( v.texcoord, _NoiseTex);
					return o;
				}

				half4 frag( v2f i ) : SV_Target
				{
					//noise effect
					half4 offsetColor1 = tex2D(_NoiseTex, i.uvmain + _Time.xz*_HeatTime);
					half4 offsetColor2 = tex2D(_NoiseTex, i.uvmain - _Time.yx*_HeatTime);
					half distortX = ((offsetColor1.r + offsetColor2.r) - 1) * _HeatForce;
					half distorty = ((offsetColor1.g + offsetColor2.g) - 1) * _HeatForce;

					half2 screenUV = (i.vertex.xy / _ScreenParams.xy)+ float2(distortX, distorty);

					half4 col = tex2D(_CameraOpaqueTexture, screenUV);
					col.a = 1.0f;

					return col;
				}
			ENDHLSL
		}
	}
}
