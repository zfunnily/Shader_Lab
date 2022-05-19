/*
from Distrtion.shader
*/

Shader "URP/PrismRefraction" 
{
	Properties {
		  _MainTex ("Main Texture", 2D) = "white" {}
         //这里的法线贴图用于计算折射产生的扭曲
         _BumpMap("Normal Map",2D)="bump"{}
		 [HDR]_SpColor("Sp Color", Color) = (1.0,1.0,1.0,1.0)
		_Distortion("Distortion",range(0,100))=10
          //一个折射系数，用于控制折射和反射的占比
        _RefractAmount("Refract Amount",range(0,1))=1


		//侧面厚度
		_FenierEdge("Fenier Range", Range(-2, 2)) = 0.0
		_FenierIntensity("Fenier intensity", Range(0, 10)) = 2.0
	}

	SubShader {
		Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline"="UniversalPipeline"}
		Blend SrcAlpha OneMinusSrcAlpha
		//AlphaTest Greater .01
		Cull Off 
		Lighting Off 
		// ZTest Off
		ZWrite Off
		Pass {
			//Tags { "LightMode" = "UniversalForward"}
			Tags { "LightMode" = "Grab"}
			
			HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

				struct appdata_t {
					float4 vertex : POSITION;
					float2 texcoord : TEXCOORD0;
					float3 normal : NORMAL;
                  	float4 tangent:TANGENT;
				};

				struct v2f {
					float4 vertex : POSITION;
					float4 uvmain : TEXCOORD0;
                  	float4 TtoW0:TEXCOORD1;
                  	float4 TtoW1:TEXCOORD2;
                  	float4 TtoW2:TEXCOORD3;
				};
 				sampler2D _MainTex;
             	float4 _MainTex_ST;
 				sampler2D _BumpMap;
             	float4 _BumpMap_ST;

				float4 _SpColor;
              	float _Distortion;
              	float _RefractAmount;

				SAMPLER(_SourceTex);

				// float2 MatCapUV (in float3 N,in float3 viewPos)
				// {

				//     float3 viewNorm = mul((float3x3)UNITY_MATRIX_V, N);
				//     float3 viewDir = normalize(viewPos);
				//     float3 viewCross = cross(viewDir, viewNorm);
				//     viewNorm = float3(-viewCross.y, viewCross.x, 0.0);
				//     float2 matCapUV = viewNorm.xy * 0.5 + 0.5;
				//     return matCapUV; 
				// }

				// float EdgeThickness (in float NoV)
				// {
				// 	float ET = saturate((NoV-_FenierEdge)*_FenierIntensity);
				// 	return ET;
				// }
				// //_BaseColor添加一个自定义的颜色参数，就可以自由控制玻璃本体色彩
				// float2 RFLerpColor (in float3 rfmatCap,in float Thickness)
				// {
				//   float2 c1 = _BaseColor.rgb*0.5;
				//   float2 c2 = rfmatCap*_BaseColor.rgb;
				//   float cMask = Thickness;
				//     return lerp(c0,c2,cMask ); //这里也可以 *v.color.rgb 用顶点色来控制玻璃局部色彩，制作出彩色玻璃的效果
				// }

				v2f vert (appdata_t v)
				{
					v2f o;
					VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
					o.vertex = vertexInput.positionCS;
					o.uvmain.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
					o.uvmain.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

					float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                  	float3 worldNormal = TransformObjectToWorldNormal(v.normal);
                  	float3 worldTangent = TransformObjectToWorldDir(v.tangent.xyz);
                  	float3 worldBinormal = cross(worldTangent, worldNormal)*v.tangent.w;
  
                  	o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                  	o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                  	o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
					return o;
				}

				half4 frag( v2f i ) : SV_Target
				{

					// float3 thicknessTex= tex2D(_MaskTex, i.uv);
					// float sThickness = thicknessTex.r * i.color.r; //杯体本身实心玻璃部分
					// float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
					// float NoV = dot(N,V);

					// float Refintensity = Thickness*_Refintensity;
					// float3 rfmatCap = tex2D(_RfCapTex,matCapuv+Refintensity);
					// float3 rfmatColor= RFLerpColor(rfmatCap,Thickness)

					// float alpha = saturate(max(spmatCap.r*_SpColor.a ,Thickness)*_BaseColor.a);
					// //_SpColor 是给高光颜色单独一个色彩控制项
					// //alpha这里的计算是为了可以分别控制高光的透明度，以及整体杯子的透明度
					// col.rgb = rfColor+spColor;//反射与折射合并
					// col.a = alpha;					
					// return col;


					float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                  	float3x3 TtoW = float3x3(i.TtoW0.xyz, i.TtoW1.xyz, i.TtoW2.xyz);
  
                  	float3 worldViewDir = normalize(GetCameraPositionWS()-worldPos);

                  	float3 tanNormal = UnpackNormal(tex2D(_BumpMap, i.uvmain.zw));
                  	float3 worldNormal = mul(TtoW, tanNormal);
                  	//对采集的屏幕图像进行关于法线方向上的扭曲和偏移，也就是模拟折射的效果
					half2 screenUV = (i.vertex.xy / _ScreenParams.xy);
                  	half2 offset = tanNormal.xy*_Distortion*screenUV;
                  	screenUV += offset;
                  	float4 refractCol = tex2D(_SourceTex, screenUV);
                  	//这一块用来模拟反射的效果，反射越强，也就是透光度越低，越能看到主贴图纹理以及周围环境反射的残影
                  	float3 reflectDir = reflect(-worldViewDir, worldNormal);
                  	float4 mainTexCol = tex2D(_MainTex, i.uvmain.xy);
                  	// float4 cubemapCol = texCUBE(_Cubemap, reflectDir);
                  	float3 reflectCol = mainTexCol.rgb;//*cubemapCol.rgb;
                 	//最后将折射和反射进行一个综合叠加，_RefractAmount可以认为是透光率，当它为1时，就是全透过而没有反射，为0时就是全反射跟镜子一样
                 	float4 color;
					color.rgb = refractCol.rgb * _RefractAmount + reflectCol * (1 - _RefractAmount);
					color.a = 1.0f;
					return color;

				}
			ENDHLSL
		}
	}
}
