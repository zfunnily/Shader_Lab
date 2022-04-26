
 Shader "Custom/DynamicRimLighting" {  
         //属性域  
        Properties {  
            //纹理颜色  
             _MainColor ("Main Color", Color) = (1,1,1,1)  
              //主纹理属性  
              _MainTex ("Texture", 2D) = "white" {}  
              //法线贴图纹理属性  
              _BumpMap ("Bumpmap", 2D) = "bump" {}  
              //边缘光颜色值  
              _RimColor ("Rim Color", Color) = (1,1,1,1)  
              //边缘光强度值  
              _RimPower ("Rim Power", Range(0.0,1.0)) = 0.5  
              //
              _RimMask("RimMask", 2D) = "white"{}  
                 _RimSpeed("RimSpeed", Range(-10, 10)) = 1.0  
              _Glossiness ("平滑度", Range(0,1)) = 0.5
              _Metallic ("金属性", Range(0,1)) = 0.0
              _Brightness ("亮度", Range(0,3)) = 1.5
              _SpecialBrightness ("变身亮度", Range(0,3)) = 1.5
        }

        SubShader {  
              //标明渲染类型是不透明的物体  
              Tags { "RenderType" = "Opaque" }  
              //标明CG程序的开始  
              CGPROGRAM  
              //声明表面着色器函数  
              #pragma surface surf Standard
              //定义着色器函数输入的参数Input  
              struct Input {  
                  //主纹理坐标值  
                  float2 uv_MainTex;  
                  //法线贴图坐标值  
                  float2 uv_BumpMap;  
                  //视图方向  
                  float3 viewDir;  
              };  
              //声明对属性的引用  
              float4 _MainColor;  
              sampler2D _MainTex;  
              sampler2D _BumpMap;  
              float4 _RimColor;  
              float _RimPower;  
              sampler2D _RimMask;  
              float _RimSpeed;  
              half _Glossiness;
              half _Metallic;
              half _Brightness;
              half _SpecialBrightness;

              //表面着色器函数  
              void surf (Input IN, inout SurfaceOutputStandard o) {  
              fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);  
              fixed rimMask = tex2D(_RimMask, IN.uv_MainTex + float2(0 , _Time.y *_RimSpeed)).r;  
                  //赋值颜色信息  
              o.Metallic = _Metallic;
              o.Smoothness = _Glossiness;
              o.Albedo = tex.rgb *_Brightness* _MainColor.rgb+_RimColor.rgb*_RimPower*(_SpecialBrightness-rimMask); 

              //赋值法线信息  
              o.Normal = UnpackNormal (tex2D (_BumpMap, IN.uv_BumpMap));  
              half rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal)); 
 
              //赋值自发光颜色信息  
              //o.Emission = _RimColor.rgb * pow (rim, _RimPower);  
              o.Emission = _RimColor.rgb *_RimPower*(_SpecialBrightness-rimMask);
              }  
              //标明CG程序的结束  
              ENDCG  
        }
        Fallback "Diffuse"
}