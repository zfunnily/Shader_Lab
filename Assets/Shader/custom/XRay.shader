/*
https://blog.csdn.net/linxinfa/article/details/105975216
Pass1：关闭深度写入（ZWrite Off），深度测试渲染较远的物体，即模型被物体遮挡的部分（ztest greater）。

Pass2：开启深度写入，正常渲染。
*/
Shader "Custom/XRay"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_XRayPower("XRay Power",Range(0.1,10)) = 1
		_XRayColor("XRay Color",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "Queue" = "Geometry+1000" "RenderType"="Opaque" }
        LOD 100

		Pass//XRay
		{
			ZTest Greater // 表示大于的时候显示（目的显示墙后面的物体）
			// ZWrite Off
			ZWrite On
			Blend SrcAlpha One

			CGPROGRAM
            // Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members color)
            #pragma exclude_renderers d3d11

			#pragma vertex vert
			#pragma fragment frag
			#include"UnityCG.cginc"

			float _XRayPower;
			float4 _XRayColor;

			struct v2f
			{
				float4 vertex:SV_POSITION;
                fixed4 color : COLOR;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
                //视线与法线垂直的部分（点乘为0）即是外轮廓，加重描绘
                float rim = 1 - saturate(dot(normalize(v.normal),viewDir));
                o.color = _XRayColor * pow(rim, _XRayPower);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return i.color;
			}

			ENDCG
		}

        Pass
        {
            ZWrite on
            ZTest Less 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return tex2D(_MainTex, i.uv);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}