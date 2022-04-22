Shader "Custom/Lightning" {
    Properties {
        _MainTex("Base (RGB)", 2D) = "white" {}
        _MainTex2("Pattern (RGB)", 2D) = "white" {}
        _Alpha("Alpha", Range(0, 1)) = 0.0
        _Color("Tint", Color) = (1, 1, 1, 1)
        _Value1("_Value1", Range(0,1)) = 64
        _Value2("_Value2", Range(0,1)) = 1
        _Value3("_Value3", Range(0,1)) = 1
        _Value4("_Value4", Range(0,1)) = 0
        _Value5("_Value5", Range(0,1)) = 0

        _StencilComp("Stencli Comparison", Float) = 8
        _Stencil("Stencli ID", Float) = 0
        _StencilOp("Stencli Operation", Float) = 0
        _StencilWriteMask("Stencil Write Mask", Float) = 255
        _StencilReadMask("Stencil Read Mask", Float) = 255
        _ColorMask("Color Mask", Float) = 15
    }
    SubShader {
        Tags {"Queue"="Transparent" "IgnoreProjector"="true" "RenderType"="Transparent"}
        ZWrite Off Blend SrcAlpha OneMinusSrcAlpha Cull Off

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 texcoord : TEXCOORD;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                float4 color : COLOR;
            };

            sampler2D _MainTex;
            sampler2D _MainTex2;
            float4 _Color;
            float _Alpha;
            float _Value1;
            float _Value2;
            float _Value3;
            float _Value4;
            float _Value5;

            v2f vert(appdata_t IN)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(IN.vertex);
                o.texcoord = IN.texcoord;
                o.color = IN.color;
                return o;
            }

            float4 frag(v2f IN) : SV_TARGET
            {
                float speed = _Value1;
                float2 uv = IN.texcoord;
                uv += float2(0, 0);
                uv /= 8;

                float tm = _Time;
                uv.x += floor(fmod(tm*speed, 1.0) * 8) / 8;
                uv.y += (1-floor(fmod(tm*speed/8, 1.0)*8)/8);
                float4 t2 = tex2D(_MainTex2, uv);

                uv = IN.texcoord;
                uv /= 8;
                tm += 0.2;
                uv /= 1.0;
                uv.x = floor(fmod(tm*speed, 1.0)*8) / 8;
                uv.y = (1-floor(fmod(tm*speed/8, 1.0) * 8) / 8);
                t2 += tex2D(_MainTex2, uv);

                uv = IN.texcoord;
                uv /= 8;
                tm += 0.6 + _Time;
                uv.x += floor(fmod(tm*speed, 1.0) * 8) / 8;
                uv.y += (1-floor(fmod(tm*speed/8, 1.0)*8)/8);
                t2 += tex2D(_MainTex2, uv);

                float4 t = tex2D(_MainTex, IN.texcoord) * IN.color;
                t2.a = t.a;
                t.rgb += t2 * _Value2;
                
                return float4(t.rgb, t.a * (1-_Alpha));
            }

            ENDCG
        }

    }

    Fallback "Sprites/Default"

}