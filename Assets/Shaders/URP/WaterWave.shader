Shader "URP/WaterWave" 
{
	Properties {
		_NoiseTex ("Noise Texture (RG)", 2D) = "white" {}
		//折射偏移方向
		_OffsetDirection("_OffsetDirection", Vector) = (1, 1, 1, 1)
		//波纹幅度
		_WaveScaleX("WaveScaleX", range (.0,0.1)) = 0.008
		_WaveScaleY("WaveScaleY", range (.0,0.1)) = 0.008
		_HeatTimeX  ("Heat TimeX", range (-1,1)) = 0.1
		_HeatTimeY  ("Heat TimeY", range (-1,1)) = 0.1
		//波纹强度
		_HeatForce  ("Heat Force", range (-0.1,0.1)) = 0.008
		//波纹方向
		// [KeywordEnum(X, NX, Y, NY)] _WaveDirection("WaveDirection", Float) = 0.0
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
				// #pragma multi_compile _WAVEDIRECTION_X _WAVEDIRECTION_NX _WAVEDIRECTION_Y _WAVEDIRECTION_NY

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


				float4 _OffsetDirection;
				float _WaveScaleX;
				float _WaveScaleY;
				float _HeatTimeX;
				float _HeatTimeY;
				float _HeatForce;
				float4 _NoiseTex_ST;
				sampler2D _NoiseTex;
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
					i.uvmain = i.uvmain / float2(_WaveScaleX, _WaveScaleY);
					i.uvmain += float2(.5,.5);

					i.uvmain = i.uvmain +  float2(_HeatTimeX, _HeatTimeY) * _Time.yz;

					//noise effect
					half4 offsetColor1 = tex2D(_NoiseTex,  i.uvmain + _Time.xz * _HeatTimeX);
					half4 offsetColor2 = tex2D(_NoiseTex, i.uvmain + _Time.yz * _HeatTimeY);
					half distortX = ((offsetColor1.r + offsetColor2.r) - 1) * _HeatForce;
					half distortY = ((offsetColor1.g + offsetColor2.g) - 1) * _HeatForce;

					half2 screenUV = (i.vertex.xy / _ScreenParams.xy) + float2(distortX, distortY) ; //
					screenUV +=  _OffsetDirection.xy / _ScreenParams.xy;


					half4 col = tex2D(_SourceTex, screenUV);
					col.a = 1.0f;

					return col;
				}
			ENDHLSL
		}
	}
}
