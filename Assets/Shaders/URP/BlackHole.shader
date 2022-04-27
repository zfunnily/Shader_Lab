/*
黑洞: https://zhuanlan.zhihu.com/p/32168185

*/

Shader "URP/BlackHole"
{
    Properties{
	_MainTex("MainTex",2D)="white"{}
	// _MainColor("MainColor",Color)=(1,1,1,1)

	//设置开始受影响的范围
   _Range("Range",Float)=15
   //靠近黑洞位置的影响系数
   _HoleAmount("HoleAmount",Range(1.0,2.0))=1.5
   _BlackHolePos("Black Hole Pos", Vector) = (1,1,1, 1)

   [Header(Shadow)]
   _GroundHeight ("_GroundHeight", Float) = 0
   _ShadowColor ("_ShadowColor", Color) = (0, 0, 0, 1)
   _ShadowFalloff ("_ShadowFalloff", Range(0, 1)) = 0.05
}
SubShader{
	Tags{"Queue"="Transparent" "LightMode"="UniversalForward" "RenderType"="Opaque" "IgnoreProjector"="True" "RenderPipeline"="UniversalPipeline"}
	Pass{
		// LOD 100
		Blend SrcAlpha OneMinusSrcAlpha
		HLSLPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"

		float4 _MainColor;
		sampler2D _MainTex;
		float4 _MainTex_ST;

		float _Range;
		half _HoleAmount; 
		float3 _BlackHolePos;


		struct a2v{
			float4 vertex:POSITION;
			float4 texcoord:TEXCOORD0;	
            float3 normal:NORMAL;
            float3 color:COLOR;
		};

		struct v2f{
			float4 pos:SV_POSITION;
			float4 uv:TEXCOORD0;
            float3 color:COLOR;
			float4 shadowCoord : TEXCOORD1; // jave.lin : shadow recieve 在给到 fragment 时，要有阴影坐标
		};

		float3 Diffuse(a2v v)
		{
			//精度转换 法线归一
            float3 worldNormal = normalize(TransformObjectToWorldNormal(v.normal));
            //世界光照的方向 
            float3 worldLightDir = normalize(_MainLightPosition.xyz);
            //环境
            float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
			//根据兰伯特模型计算像素的光照信息，小于0的部分理解为看不见，置为0
			float3 lambert = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
			return _MainLightColor.rgb * lambert + ambient;
		}

		v2f vert(a2v v){
			v2f o;
			//获得模型顶点在世界空间的位置
			float4 oriWorldPos=mul(unity_ObjectToWorld,v.vertex);
			//判断与黑洞的距离
			float dis=distance(oriWorldPos,_BlackHolePos);
			//设置变化后的新顶点，初始值为原顶点的世界空间坐标
			float4 worldPos=oriWorldPos;
			worldPos.xyz=lerp(oriWorldPos,_BlackHolePos,clamp((_Range-dis)*_HoleAmount/_Range,0,1));
			
			o.pos=mul(UNITY_MATRIX_VP,worldPos);
			o.uv.xy=TRANSFORM_TEX(v.texcoord,_MainTex);

			
			//漫反射 光照模型
            o.color = Diffuse(v);

			//阴影
			 o.shadowCoord = TransformWorldToShadowCoord(worldPos); 
			return o;
		}

		float4 frag(v2f i): SV_Target {
			//采样颜色值
            float4 albedo = tex2D(_MainTex, i.uv);
			float4 finalCol = float4(i.color * albedo.rgb , albedo.a);
			// return finalCol;

			float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
			float shadow = MainLightRealtimeShadow(i.shadowCoord); 
			finalCol.rgb = lerp(finalCol.rgb * ambient.rgb, finalCol.rgb, shadow);
			// finalCol.rgb *= shadow;
            return finalCol;
		}
		ENDHLSL
	}
	//阴影pass
        Pass
        {
            Name "PlanarShadow"
           Tags{ "LightMode" = "SRPDefaultUnlit" } //URP不支持多pass，这样可以多pass
            
            //用使用模板测试以保证alpha显示正确
            Stencil
            {
                Ref 0
                Comp equal
                Pass incrWrap
                Fail keep
                ZFail keep
            }
            
            Cull Off
            
            //透明混合模式
            Blend SrcAlpha OneMinusSrcAlpha
            
            //关闭深度写入
            ZWrite off
            
            //深度稍微偏移防止阴影与地面穿插
            Offset -1, 0
            
            HLSLPROGRAM
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 vertex: SV_POSITION;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            half _GroundHeight;
            half4 _ShadowColor;
            half _ShadowFalloff;
            CBUFFER_END
            
            float3 ShadowProjectPos(float3 positionOS)
            {
                float3 positionWS = TransformObjectToWorld(positionOS);
                
                //灯光方向
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                
                //阴影的世界空间坐标（低于地面的部分不做改变）
                float3 shadowPos;
                shadowPos.y = min(positionWS.y, _GroundHeight);
                shadowPos.xz = positionWS.xz - lightDir.xz * max(0, positionWS.y - _GroundHeight) / lightDir.y;
                
                return shadowPos;
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                //得到阴影的世界空间坐标
                float3 shadowPos = ShadowProjectPos(input.positionOS.xyz);
                
                //转换到裁切空间
                output.vertex = TransformWorldToHClip(shadowPos);
                
                //得到中心点世界坐标
                float3 center = float3(unity_ObjectToWorld[0].w, _GroundHeight, unity_ObjectToWorld[2].w);
                //计算阴影衰减
                float falloff = 1 - saturate(distance(shadowPos, center) * _ShadowFalloff);

                output.color = _ShadowColor;
                output.color.a *= falloff;
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                return input.color;
            }
            ENDHLSL
            
        }
}
    Fallback "Diffuse"
}