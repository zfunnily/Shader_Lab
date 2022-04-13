Shader "Unity Shaders Book/Chapter 15/Dissolve01" {
	Properties {
		_BurnAmount ("Burn Amount", Range(0.0, 1.0)) = 0.0
		_LineWidth("Burn Line Width", Range(0.0, 0.2)) = 0.1
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_BurnFirstColor("Burn First Color", Color) = (1, 0, 0, 1)
		_BurnSecondColor("Burn Second Color", Color) = (1, 0, 0, 1)
		_BurnMap("Burn Map", 2D) = "white"{}
	}
	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		Pass {
			Tags { "LightMode"="ForwardBase" }
			Cull Off//消融会导致裸露模型内部的构造，只渲染正面会出现错误的结果。
			CGPROGRAM
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
			fixed _BurnAmount;//控制消融程度，1—完全消融
			fixed _LineWidth;//控制模拟烧焦效果时的线宽，越大，火焰边缘的蔓延范围越广
			sampler2D _MainTex;
			sampler2D _BumpMap;
			fixed4 _BurnFirstColor;//火焰边缘的两种颜色
			fixed4 _BurnSecondColor;
			sampler2D _BurnMap;//噪声纹理
			float4 _MainTex_ST;
			float4 _BumpMap_ST;
			float4 _BurnMap_ST;
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uvMainTex : TEXCOORD0;
				float2 uvBumpMap : TEXCOORD1;
				float2 uvBurnMap : TEXCOORD2;
				float3 lightDir : TEXCOORD3;
				float3 worldPos : TEXCOORD4;
				SHADOW_COORDS(5)
			};
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uvMainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uvBumpMap = TRANSFORM_TEX(v.texcoord, _BumpMap);
				o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);
				TANGENT_SPACE_ROTATION;
  				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
  				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
  				TRANSFER_SHADOW(o);
				return o;
			}
			fixed4 frag(v2f i) : SV_Target {
				fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;//噪声纹理采样
				clip(burn.r - _BurnAmount);//小于阈值则会被剔除
				float3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uvBumpMap));
				fixed3 albedo = tex2D(_MainTex, i.uvMainTex).rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));
				//t=1：该像素位于消融的边界处，t=0：该像素为正常的模型颜色
				fixed t = 1 - smoothstep(0.0, _LineWidth, burn.r - _BurnAmount);//在[0.0, _LineWidth]得到平滑过度的值
				fixed3 burnColor = lerp(_BurnFirstColor, _BurnSecondColor, t);//用t来混合两种火焰颜色
				burnColor = pow(burnColor, 5);//烧焦的颜色
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				//* step(0.0001, _BurnAmount)保证_BurnAmount为0时，不显示任何消融效果。
				fixed3 finalColor = lerp(ambient + diffuse * atten, burnColor, t * step(0.0001, _BurnAmount));
				return fixed4(finalColor, 1);
			}
			ENDCG
		}
		//使用透明度测试的物体的阴影需要特别处理，被剔除的区域不会再向其他物体投射阴影。
		// Pass to render object as a shadow caster
		Pass {
			Tags { "LightMode" = "ShadowCaster" }//用于投射阴影的pass
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"
			fixed _BurnAmount;
			sampler2D _BurnMap;
			float4 _BurnMap_ST;
			struct v2f {
				V2F_SHADOW_CASTER;//定义阴影投射需要定义的变量
				float2 uvBurnMap : TEXCOORD1;
			};
			v2f vert(appdata_base v) {
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)//填充变量
				o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);
				return o;
			}
			fixed4 frag(v2f i) : SV_Target {
				fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;//噪声纹理采样
				clip(burn.r - _BurnAmount);//小于阈值则会被剔除
				SHADOW_CASTER_FRAGMENT(i)//阴影投射，把结果输出到深度图和阴影映射纹理中。
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}