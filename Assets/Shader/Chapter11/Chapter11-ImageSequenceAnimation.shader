// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "UnityShaderBook/Chapter11/Chapter11-ImageSequenceAnimation"
{
    Properties
    {
        _Color ("Color Tine", Color) = (1, 1, 1, 1)
        _MainTex ("Image Sequence", 2D) = "white" {}
        _HorizontalAmount ("Horizontal Amount", Float) = 4
        _VerticalAmount ("Vertical Amount", Float) = 4
        _Speed ("Speed", Range(1, 100)) = 30
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

        Pass {
            Tags { "LightMode"="ForwardBase" }
            ZWrite Off //关闭深度写入
            Blend SrcAlpha OneMinusSrcAlpha //开启混合模式
        
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            half4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HorizontalAmount;
            float _VerticalAmount;
            float _Speed;

            struct a2v {
                float4 vertex : POSITION;
                float4 texcoord:TEXCOORD0;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
    	    };


            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv:TEXCOORD0;
            };

            v2f vert (a2v v) {  
                v2f o;  
                //从模型空间获取剪裁空间的顶点坐标
                o.pos = UnityObjectToClipPos(v.vertex);  
                //获取纹理的uv坐标
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);  
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                //_Time.y就是自该场景加载后所经过的时间

                //得到模拟的时间
                float time = floor(_Time.y * _Speed);  
                //求的行
                float row = floor(time / _HorizontalAmount);
                //求的列
                float column = time - row * _HorizontalAmount;

            //  half2 uv = float2(i.uv.x /_HorizontalAmount, i.uv.y / _VerticalAmount);
            //  uv.x += column / _HorizontalAmount;
            //  uv.y -= row / _VerticalAmount;
                half2 uv = i.uv + half2(column, -row);
                uv.x /=  _HorizontalAmount;
                uv.y /= _VerticalAmount;

                fixed4 c = tex2D(_MainTex, uv);
                c.rgb *= _Color;

                return c;
            }

            ENDCG
        }
    }
    Fallback "Transparent/VertexLit"
}
