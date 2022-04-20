/*
实现原理：
模板测试
*/
Shader "Custom/OutlineStencil" 
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

            /*Unity的模板缓冲区的默认值是0，因此在外轮廓线之内的片元，我们在第一个Pass中写入到模板缓冲区的值为1，因此第二次Pass中相等，就不会去选择渲染；
            而外轮廓线向外扩张出来的顶点所形成的那些片元，由于第一个Pass并未渲染，模板缓冲区的值为0，因此不相等，就会按第二个Pass的方法得到结果*/
            Stencil 
            {
                Ref 1 //每个片元的参考值 Ref 都设置为1
                Comp Always //Comp NotEqual 即只有当前参考值 Ref 和当前模板缓冲区的值不相等的时候才去渲染片元
                Pass Replace
            }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float4 vert (float4 v : POSITION) : SV_POSITION
            {       
                return UnityObjectToClipPos(v);
            }

            float4 frag() : SV_Target 
            { 
                return float4(1, 1, 1, 1);
            }

            ENDCG
        }

        Pass {
            Stencil
			{
                Ref 1
                Comp NotEqual
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float _Outline;
            fixed4 _OutlineColor;


            struct a2v 
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
            };

            struct v2f 
            {
                float4 pos : SV_POSITION;
            };

            v2f vert (a2v v)
            {
                v2f o;
                float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                normal.z = -0.5;
                pos = pos + float4(normalize(normal), 0) * _Outline;
                o.pos = mul(UNITY_MATRIX_P, pos);
                return o;
            }

            float4 frag(v2f i) : SV_TARGET
            {
                return float4(_OutlineColor.rgb, 1);
            }

            ENDCG
        }
    }
}