/*
实现原理：
    基于观察角度和表面法线
    通过视角方向和表面法线点乘结果来得到轮廓线信息。
    简单快速，但局限性大。
*/
Shader "Custom/OutlineViewNormal" 
{
    Properties 
    {
        _Outline ("Outline", Range(0, 1)) = 0.1
    }
    SubShader 
    {
        Pass 
        {
            Cull Back

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float _Outline;

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed4 color : COLOR;
            };

			/*
			函数解释:
			UnityObjectToClipPos:  通过模型顶点坐标转换为剪裁空间的顶点坐标
			ObjSpaceViewDir() 模型空间中的顶点坐标 -> 模型空间从这个点到摄像机的观察方向
			normalize(x): 归一化向量
			step(a, x):  如果 a>x，返回 0；否则，返回 1。
			dot(A, B): 返回A和B的点积 投影
			*/
            v2f vert (appdata_base v)
            {       
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                float3 ObjViewDir = normalize(ObjSpaceViewDir(v.vertex));
                float3 normal = normalize(v.normal);
                float factor = step(_Outline, dot(normal, ObjViewDir));
                o.color = float4(1, 1, 1, 1) * factor;
                return o;
            }

            float4 frag(v2f i) : SV_Target 
            { 
                return i.color;
            }

            ENDCG
        }
    }
}