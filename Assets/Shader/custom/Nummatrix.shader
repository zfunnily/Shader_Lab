 Shader "Custom/NumberMatrix"
 {
     Properties
     {
         //主纹理属性  
         _MainTex ("Main Texture", 2D) = "white" {}  

         _TintColor ("Tint Color", Color) = (1,1,1,1)
         _RandomTex ("Random Tex", 2D) = "white" {}
         _FlowingTex ("Flowing Tex", 2D) = "white" {}
         _NumberTex ("Number Tex", 2D) = "white" {}
         _CellSize ("格子大小,只取XY", Vector) = (0.03, 0.04, 0.03, 0)
         _TexelSizes ("X:Random Tex宽度,Y:Flowing Tex宽度,Z:Number Tex数字个数(这些数值根据图片更改)", Vector) = (0.015625, 0.00390625, 10, 0)
         _Speed ("X:图片下落速度,Y:数字变化速度", Vector) = (1,5,0,0)
         _Intensity ("Global Intensity", Float) = 1

        _Brightness("Brightness", Float) = 5	//调整亮度
		_Saturation("Saturation", Float) = 2	//调整饱和度
		_Contrast("Contrast", Float) = 1		//调整对比度
     }
 
     Subshader
     {
         Tags
         {
             "RenderType"="Transparent"
             "Queue"="Transparent"
             "IgnoreProjector"="True"
         }
         Pass {
             
            CGPROGRAM 
             #pragma vertex vert
             #pragma fragment frag
             #pragma target 3.0
             #include "UnityCG.cginc"
             sampler2D _MainTex;
             float4 _MainTex_ST;


             struct appdata_v
             {
                 float4 vertex : POSITION;
                 float2 uv : TEXCOORD0;
             };
 
             struct v2f
             {
                 float4 pos : POSITION;
                 float2 uvMainTex : TEXCOORD0;
             };
 
             v2f vert (appdata_v v)
             {
                 v2f o;
                 o.pos = UnityObjectToClipPos (v.vertex);
                 o.uvMainTex = TRANSFORM_TEX(v.uv, _MainTex);
                 return o;
             }
             
             fixed4 frag (v2f i) : SV_TARGET
             {
                return tex2D(_MainTex, i.uvMainTex);
             }
            ENDCG
         }

         Pass
         {
             Fog { Mode Off }
             Lighting Off
             Blend One One
             Cull Off
             ZWrite Off //关闭深度写入
 
             CGPROGRAM
             #pragma vertex vert
             #pragma fragment frag
             #pragma target 3.0
             #include "UnityCG.cginc"
             
             float4 _TintColor;
             sampler2D _RandomTex;
             sampler2D _FlowingTex;
             sampler2D _NumberTex;
             float4 _CellSize;
             float4 _TexelSizes;
             float4 _Speed;
             float _Intensity;

            half _Brightness;
		    half _Saturation;
		    half _Contrast;
             
             #define _RandomTexelSize (_TexelSizes.x)
             #define _FlowingTexelSize (_TexelSizes.y)
             #define _NumberCount (_TexelSizes.z)
             #define T (_Time.y)
             #define EPSILON (0.00876)
 
             struct appdata_v
             {
                 float4 vertex : POSITION;
                 float2 uv : TEXCOORD0;
                 half4 color : COLOR;
             };
 
             struct v2f
             {
                 float4 pos : POSITION;
                 float3 texc : TEXCOORD1;
                 half4 color : COLOR;
             };
 
             v2f vert (appdata_v v)
             {
                 v2f o;
                 o.pos = UnityObjectToClipPos (v.vertex);
                 o.color = v.color;
                 o.texc = v.vertex.xyz;
                 return o;
             }
             
             fixed4 frag (v2f i) : COLOR
             {
                float3 cellc = i.texc.xyz / _CellSize + EPSILON;
                float speed = tex2D(_RandomTex, cellc.xz * _RandomTexelSize).g * 3 + 1;
                cellc.y += T*speed*_Speed.x;
                float intens = tex2D(_FlowingTex, cellc.xy * _FlowingTexelSize).r;
                
                float2 nc = cellc;
                nc.x += round(T*_Speed.y*speed);
                float number = round(tex2D(_RandomTex, nc * _RandomTexelSize).r * _NumberCount) / _NumberCount;
                
                float2 number_tex_base = float2(number, 0);
                float2 number_tex = number_tex_base + float2(frac(cellc.x/_NumberCount), frac(cellc.y));
                fixed4 ncolor = tex2Dlod(_NumberTex, float4(number_tex, 0, 0)).rgba;
                
                fixed4 col = ncolor * pow(intens,3) * _Intensity * _TintColor;

                fixed4 renderTex = col * i.color;
                //brigtness亮度直接乘以一个系数，也就是RGB整体缩放，调整亮度
                fixed3 finalColor = renderTex * _Brightness;
                //saturation饱和度：首先根据公式计算同等亮度情况下饱和度最低的值：
			    fixed gray = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
                fixed3 grayColor = fixed3(gray, gray, gray);
                //根据Saturation在饱和度最低的图像和原图之间差值
                finalColor = lerp(grayColor, finalColor, _Saturation);
                //contrast对比度：首先计算对比度最低的值
                fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
                //根据Contrast在对比度最低的图像和原图之间差值
                finalColor = lerp(avgColor, finalColor, _Contrast);
                //返回结果，alpha通道不变
                return fixed4(finalColor, renderTex.a);


             }
             ENDCG
         }
     }

     FallBack Off
 }