Shader "Unity Shaders Book/Chapter 10/Refraction" {
	Properties {
		_Color("Color Tint", Color) = (1,1,1,1)
		_RefractColor("Refraction Color", Color) = (1,1,1,1)
		_RefractAmount("Refraction Amount", Range(0, 1)) = 0.5
		_RefractRatio("Refraction Ration", Range(0, 1)) = 0.5
		_Cubemap("Cube Map", Cube) = "_Skybox" {}
	}
 
	SubShader {
		Tags {"Queue"="Geometry" "RenderType"="Opaque"}
 
		Pass {
			Tags {"LightMode"="ForwardBase"}
 
			CGPROGRAM
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
 
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
 
			fixed4 _Color;
			fixed4 _RefractColor;
			fixed _RefractAmount;
			fixed _RefractRatio;
			samplerCUBE _Cubemap;
 
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
 
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				fixed3 worldViewDir : TEXCOORD2;
				fixed3 worldRefr : TEXCOORD3;
				SHADOW_COORDS(4)
			};
 
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				o.worldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractRatio);
 
				TRANSFER_SHADOW(o);
				return o;
			}
 
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 viewDir = normalize(i.worldViewDir);
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
 
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 refraction = texCUBE(_Cubemap, i.worldRefr).rgb * _RefractColor.rgb;
				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * saturate(dot(i.worldNormal, lightDir));
 
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
 
				fixed3 color = ambient + lerp(diffuse, refraction, _RefractAmount) * atten;
				return fixed4(color, 1);
			}
 
			ENDCG
		}
	}
	FallBack "Reflective/VertexLit"
	// FallBack "Refraction/vertexLit"
}