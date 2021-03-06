// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
黑洞: https://zhuanlan.zhihu.com/p/32131147

*/

Shader "Custom/BlackHole"
{
    Properties 
    {
        _MainTex("MainTex", 2D) = "white" {}
        _BlackHolePos("Black Hole Pos", Vector) = (1,1,1)
        _Range ("Black Range", Range(0, 10)) = 10
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct a2v
            {
                float4 pos : POSITION;
                float4 uv : TEXCOORD;
                float4 color : COLOR;
            };

            struct v2f 
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD;
                float4 color : COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float3 _BlackHolePos;
            float _Range;

            v2f vert(a2v i)
            {
                v2f o;
                o.color = float4(1,1,1,1);
                // o.color = float4(0, 0, 0, 1);
                //获得模型顶点在世界空间的位置
                fixed4 oriWorldPos = mul(unity_ObjectToWorld, i.pos); 
                //判断与黑洞的位置
                fixed dis = distance (oriWorldPos , _BlackHolePos);
                //设置变化后的新顶点 初始值为原顶点的世界空间坐标
                fixed4 worldPos = oriWorldPos;

                // if(dis<_Range){
			    // //新的顶点位置在靠近黑洞的方向上受到的偏移影响，越靠近黑洞，偏移值越大
			    // 	worldPos.xyz+=normalize(_BlackHolePos-oriWorldPos)*(_Range-dis);
			    // //当变换后的顶点位置超出了黑洞位置时，该顶点位置即为黑洞位置，即完全被吞噬
			    // //这里是通过判断(worldPos-_BlackHolePos)和(_BlackHolePos-oriWorldPos)向量的方向
			    // //来确定是否超过黑洞，若同向则超过，其实自己动手画一下向量关系很直白
			    // 	if(dot((oriWorldPos-_BlackHolePos),(_BlackHolePos-worldPos))>0){
			    // 		worldPos.xyz=_BlackHolePos;
			    // 	}
			    // }

			    //该部分通过lerp函数来避免上面的两次if判断(if判断相对比较耗性能)
			    //_HoleAmount系数是为了使靠近黑洞时受到的吞噬效果更加明显
                // 官方: float lerp(float a, float b, float w) { return a + w*(b-a);}
                //oriWorldPos + (clamp((_Range-dis)*_HoleAmount/_Range,0,1))  * (_BlackHolePos - oriWorldPos);

                // MyExplain: float lerp(float a, float b, float w) { return a(1-w) + b * w; }
                //oriWorldPos(1-  (clamp((_Range-dis)*_HoleAmount/_Range,0,1)) )  + _BlackHolePos * (clamp((_Range-dis)*_HoleAmount/_Range,0,1))
			    worldPos.xyz=lerp(oriWorldPos,_BlackHolePos,clamp((_Range-dis)/_Range,0,1));

                i.pos = mul(unity_WorldToObject, worldPos);
                o.pos = UnityObjectToClipPos(i.pos); 
                o.uv.xy = TRANSFORM_TEX(i.uv,_MainTex);
                return o;
            }

            fixed4 frag(v2f i):SV_Target{ 
                float3 a = tex2D(_MainTex, i.uv) * i.color.rgb;
                return float4(a, 1);
                // fixed3 tangentLightDir=normalize(i.lightDir);
                // fixed3 tangentViewDir=normalize(i.viewDir);
                // fixed3 tangentNormal=UnpackNormal(tex2D(_BumpTex,i.uv.zw));
                // tangentNormal.xy*=_BumpScale;
                // tangentNormal.z=sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                // fixed3 albedo=tex2D(_MainTex,i.uv.xy)*_MainColor.rgb;
                // fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
                // fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(tangentNormal,tangentLightDir));
                // fixed3 halfDir=normalize(tangentLightDir+tangentViewDir);
                // fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(saturate(dot(halfDir,tangentNormal)),_Gloss);
                // return fixed4(ambient+diffuse+specular,1.0);
            }

            ENDCG
        }
    }

    // Fallback ""
}