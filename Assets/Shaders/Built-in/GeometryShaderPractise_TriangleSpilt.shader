/*
GeometryShader几何着色器学习（二）——UnityShader学习笔记:
https://blog.csdn.net/ezcome11/article/details/119598413?spm=1001.2014.3001.5502
*/
Shader "Built-in/GeometryShaderPractise_TriangleSpilt"
{
    Properties
    {
       [HDR]_TriangleColor ("TriangleColor",Color)=(0,0,1,1)
       [HDR]_LineColor ("LineColor",Color)=(0,1,0,1)
       [HDR]_PointColor ("PointColor",Color)=(1,0,0,1) 
       _MainTex("MainTex",2D) = "white"{}
       _NoiseTex("NoiseTex",2D) = "white"{}
       _NoiseIntensity("NoiseIntensity",Float)=0
       _Offset("ScaleTriangle",Float) =0
       _ScaleSpeed("ScaleSpeed",Range(0.9,1)) = 1
       _ExtendDirection("_ExtendDirection",Vector)=(0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
        //输出三角形的pass
            NAME "TRIANGLE PASS"
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            //几何着色器声明
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            float4 _TriangleColor;
            float _Offset;
            float4 _ExtendDirection;
            float _ScaleSpeed;
            float _NoiseIntensity;

            sampler2D _MainTex;
            float4 _MainTex_ST;   
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float3 normal : NORMAL;
            };
            //几何着色器需要传递的数据
            struct v2g 
            {
                float4 pos : POSITION;
                float2 uvG : TEXCOORD0;
                float2 uvG2 : TEXCOORD1;
                float3 normal : TEXCOORD2;
            };
            //再从几何着色器变化过的数据传到片元着色器的结构      所以可以不用v2f 不过一个名字 想怎么取随便 自己别忘了就行
            struct g2f
            {
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 posf : SV_POSITION;
            };

        //取代原本v2f 将顶点结构传入到结合着色器需要的结构中
            v2g  vert (a2v v)
            {
                v2g o = (v2g)0;
                o.pos =v.vertex;
                o.normal = v.normal;
                o.uvG = v.texcoord;
                o.uvG2 = v.texcoord1;
                
                return o;
            }

	//几何着色器 是在顶点着色器和片元着色器之间 vs 的输出作为gs的输入      vs 顶点着色器  gs 几何着色器
            //最大调用顶点数，三角形因为是三个顶点，因此最小输入3个顶点进入
			[maxvertexcount(50)]
			//输入 point line triangle lineadj triangleadj----输出: PointStream只显示点，LineStream只显示线，TriangleStream三角形
			void geom (triangle v2g input[3], inout TriangleStream<g2f> g)
			{
                g2f o = (g2f)0;
                //算出两条边的向量   并用两边叉乘算求得面的朝向的原理 算出三角形的法线方向
                float3 edge1 = input[1].pos - input[0].pos;
                float3 edge2 = input[2].pos - input[0].pos;
                float3 triangleNormal = normalize(cross(edge1,edge2));
                //算出三角形的中心点    
                float4 centerTri = (input[0].pos+input[1].pos+input[2].pos)/3;
                //算出沿三角形法线方向要移动的方向和距离
                float3 newDir = triangleNormal * (centerTri+_ExtendDirection.xyz)*_Offset;
                //3个顶点 就要计算三次。 如果输入的是一个顶点 就计算一次  不用循环写三次也是可以的

                for (int i = 0; i<3; i++)
                {

                    o.uv = input[i].uvG;
                    o.uv2 = input[i].uvG2;
                    //采样一张贴图做噪声 一切无限可能  记得是2U
                    half noise = tex2Dlod (_NoiseTex,float4(o.uv2,0,0)).r*_NoiseIntensity;
                    float4 transformPos = input[i].pos+float4(newDir,0)*(0.5*_Offset+noise);
                    o.posf = lerp(transformPos,centerTri,_ScaleSpeed*saturate(_Offset*noise));
                    o.posf = UnityObjectToClipPos(o.posf);
                    g.Append(o);
                }  
                    g.RestartStrip();
            }

      
            half4 frag (g2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex,i.uv);
                return col*_TriangleColor;
            }
            ENDCG
        }
    }
}
