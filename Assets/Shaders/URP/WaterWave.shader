Shader "URP/WaterWave" 
{
	Properties {
		_NoiseTex ("Noise Texture (RG)", 2D) = "white" {}
		_HeatTime  ("Heat Time", range (-1,1)) = 0.1
		//波纹幅度
		_WaveScale ("WaveScale", Vector) = (50, 50, 1, 1)
		//折射偏移方向
		[KeywordEnum(X,Y, XY, YX)] _OffsetDirection("OffsetDirection", Float) = 0.0
		//波纹强度
		_HeatForce  ("Heat Force", range (-0.1,0.1)) = 0.008
	}

	SubShader {
		Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline"="UniversalPipeline"}
		Blend SrcAlpha OneMinusSrcAlpha
		//AlphaTest Greater .01
		Cull Off 
		//Lighting Off 
		ZTest Off
		ZWrite Off
		Pass {
			//Tags { "LightMode" = "UniversalForward"}
			Tags { "LightMode" = "Grab"}
			
			HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest
				#pragma multi_compile _OFFSETDIRECTION_X _OFFSETDIRECTION_Y _OFFSETDIRECTION_XY _OFFSETDIRECTION_YX

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

				struct appdata_t {
					float4 vertex : POSITION;
					float2 texcoord: TEXCOORD0;
				};

				struct v2f {
					float4 vertex : POSITION;
					float2 uvmain : TEXCOORD0;
				};


				float4 _WaveScale;
				float _HeatForce;
				float _HeatTime;
				float4 _NoiseTex_ST;
				sampler2D _NoiseTex;
				//SAMPLER(_CameraOpaqueTexture);
				//SAMPLER(_AfterPostProcessTexture);
				//SAMPLER(_CameraColorTexture);
				//SAMPLER(_CameraColorAttachmentA);
				SAMPLER(_SourceTex);

				v2f vert (appdata_t v)
				{
					v2f o;
					VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
					o.vertex = vertexInput.positionCS;

					o.uvmain = TRANSFORM_TEX( v.texcoord, _NoiseTex);
				
					return o;
				}

				half4 frag( v2f i ) : SV_Target
				{
					i.uvmain -= float2(.5,.5);
					i.uvmain = i.uvmain * _WaveScale.xy;
					i.uvmain += float2(.5,.5);

					float offsetDirectionX = 0.0f;
					float offsetDirectionY = 0.0f;
					#if _OFFSETDIRECTION_X
						offsetDirectionX = 1.0f;
					#elif _OFFSETDIRECTION_Y
						offsetDirectionY = 1.0f;
					#elif _OFFSETDIRECTION_XY
						offsetDirectionX = 1.0f;
						offsetDirectionY = 1.0f;
					#elif _OFFSETDIRECTION_YX
						offsetDirectionX = 1.0f;
						offsetDirectionY = -1.0f;
					#endif

					//noise effect
					half4 offsetColor1 = tex2D(_NoiseTex,  i.uvmain + _Time.xz*_HeatTime);
					half4 offsetColor2 = tex2D(_NoiseTex, i.uvmain - _Time.yx*_HeatTime);
					half distortX = ((offsetColor1.r + offsetColor2.r) - 1) * _HeatForce * offsetDirectionX;
					half distortY = ((offsetColor1.g + offsetColor2.g) - 1) * _HeatForce * offsetDirectionY;

					half2 screenUV = (i.vertex.xy / _ScreenParams.xy)+ float2(distortX, distortY);

					half4 col = tex2D(_SourceTex, screenUV);
					col.a = 1.0f;

					return col;
				}
			ENDHLSL
		}
	}
}
