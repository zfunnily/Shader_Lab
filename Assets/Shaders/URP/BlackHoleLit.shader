/*
黑洞: https://zhuanlan.zhihu.com/p/32168185
阴影: https://blog.csdn.net/lvcoc/article/details/113859756
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
	}
SubShader{
	Tags{"Queue"="Transparent" "RenderType"="Opaque" "IgnoreProjector"="True" "RenderPipeline"="UniversalPipeline"}
	HLSLINCLUDE
		#pragma vertex vert
		#pragma fragment frag
		#include "Lighting.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"

		CBUFFER_START(UnityPerMaterial)
			float4 _MainColor;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Plane;
		CBUFFER_END
	ENDHLSL

	Pass{
		Tags {"LightMode"="UniversalForward"}

		// LOD 100
		Blend SrcAlpha OneMinusSrcAlpha
		HLSLPROGRAM
		//控制是否开启、关闭接受功能的 变体
		// #pragma multi_compile _ _MAIN_LIGHT_SHADOWS 
		// #pragma multi_compile _ _SHADOWS_SOFT
		
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
		};


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
            o.color = Diffuse(v.normal);
			return o;
		}

		float4 frag(v2f i): SV_Target {
			//采样颜色值
            float4 albedo = tex2D(_MainTex, i.uv);
			float4 finalCol = float4(i.color * albedo.rgb , albedo.a);
			return finalCol;
		}
		ENDHLSL
	}
}
    Fallback "Diffuse"
}