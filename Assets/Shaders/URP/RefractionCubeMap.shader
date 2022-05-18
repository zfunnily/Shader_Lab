Shader "URP/RefractionCubeMap" {
	Properties {
		_Color("Color Tint", Color) = (1,1,1,1)
		_RefractColor("Refraction Color", Color) = (1,1,1,1)
		_RefractAmount("Refraction Amount", Range(0, 1)) = 0.5
		_RefractRatio("Refraction Ration", Range(0, 1)) = 0.5
		_Cubemap("Cube Map", Cube) = "_Skybox" {}
	}
 
	SubShader {
		Tags {
			"RenderPipeline"="UniversalPipeline"
			"Queue"="Geometry" "RenderType"="Opaque"
		}
 
		Pass {
			Tags {"LightMode"="UniversalForward"}
 
			HLSLPROGRAM
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
 
			#pragma vertex vert
			#pragma fragment frag
			// #pragma multi_compile_fwdbase
 
CBUFFER_START(UnityPerMaterial)
			half4 _Color;
			half4 _RefractColor;
			half _RefractAmount;
			half _RefractRatio;
CBUFFER_END
 
			TEXTURECUBE(_Cubemap);
			SAMPLER(sampler_Cubemap);
 
			struct a2v {
				float4 vertex : POSITION;
				half3 normal : NORMAL;
			};
 
			struct v2f {
				float4 pos : SV_POSITION;
				half3 worldPos : TEXCOORD0;
				half3 worldNormal : TEXCOORD1;
				half3 worldViewDir : TEXCOORD2;
				half3 worldRefr : TEXCOORD3;
				// SHADOW_COORDS(4)
			};
 
			v2f vert(a2v v) {
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.worldNormal = TransformObjectToWorldNormal(v.normal).xyz;
				o.worldPos = mul(UNITY_MATRIX_M, v.vertex).xyz;
				o.worldViewDir = _WorldSpaceCameraPos.xyz - o.worldPos;
				o.worldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractRatio);	// ������
 
				// TRANSFER_SHADOW(o);
				return o;
			}
 
			half4 frag(v2f i) : SV_Target {
				half3 worldNormal = normalize(i.worldNormal);
				// half3 viewDir = normalize(i.worldViewDir);
				// half3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				float4 shadowCoord = TransformWorldToShadowCoord(i.worldPos);
				Light mainLight = GetMainLight(shadowCoord);
				half3 lightDir = normalize(mainLight.direction);
 
				half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
				half3 refraction = SAMPLE_TEXTURECUBE(_Cubemap, sampler_Cubemap, i.worldRefr).rgb * _RefractColor.rgb;
				half3 diffuse = mainLight.color.rgb * _Color.rgb * saturate(dot(i.worldNormal, lightDir));
				// UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				half3 color = ambient + lerp(diffuse, refraction, _RefractAmount);
				return half4(color, 1);
			}
 
			ENDHLSL
		}
	}
 
	// FallBack "Reflective/VertexLit"
	// ��֪��URP��ʲôfallback����
	FallBack "Universal Render Pipeline/Simple Lit"
}