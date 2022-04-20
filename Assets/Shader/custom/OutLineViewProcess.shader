/*
实现原理：
    其实就是把前面的模板测试换成了剔除操作。
    正常渲染的时候剔除背面渲染正面，第二次顶点扩张之后剔除正面渲染背面，
    这样渲染背面时由于顶点外扩的那一部分就将被我们所看见， 而原来的部分则由于是背面且不透明所以不会被看见，形成轮廓线渲染原理。
    因此从原理上也能看出，这里得到的轮廓线不单单是外轮廓线
*/
Shader "Custom/OutlineProcess" 
{
    Properties 
    {
        _Outline ("Outline", Range(0, 1)) = 0.1
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
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

            float4 vert (float4 v : POSITION) : SV_POSITION
            {
                return UnityObjectToClipPos(v);
            }

            float4 frag () : SV_TARGET
            {
                return float4(1, 1, 1, 1);
            }

            ENDCG
        }

        Pass 
        {
            Cull Front

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float _Outline;
            float4 _OutlineColor;

            struct a2v 
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed4 color : COLOR;
            };

            v2f vert (a2v v)
            {       
                v2f o;
                float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                normal.z = -0.5;

                pos += float4(normalize(normal), 0) * _Outline;
                o.pos = mul(UNITY_MATRIX_P, pos);
                return o;
            }

            float4 frag(v2f i) : SV_Target 
            { 
                return float4(_OutlineColor.rgb, 1);
            }

            ENDCG
        }
    }
}