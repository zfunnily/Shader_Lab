//https://blog.csdn.net/qq_42115447/article/details/104161500
//函数：  https://blog.csdn.net/u012722551/article/details/103926660
Shader "Custom/RenderImage/ScreenBroken" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
		_BrokenNormalMap("BrokenNormal Map",2D)="bump"{}
		_BrokenScale("BrokenScale",Range(0,1))=1.0
	}
	SubShader {
		Pass{
			Tags { "LightMode"="ForwardBase" }
 
			CGPROGRAM
 
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
 
			#pragma vertex vert
			#pragma fragment frag
 
			//这一部分参数的定义要根据Properties
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BrokenNormalMap;
			float4 _BrokenNormalMap_ST;
			float _BrokenScale;

			struct a2v{
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
 
			//输出部分要和输入部分对应起来,而输出部分又要由片元着色器里的计算模型来确定
			struct v2f{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
			};
 
			v2f vert(a2v v){
				v2f o;
				o.pos=UnityObjectToClipPos(v.vertex);
				
				o.uv.xy=TRANSFORM_TEX(v.texcoord,_MainTex);
				o.uv.zw=TRANSFORM_TEX(v.texcoord, _BrokenNormalMap);
				return o;
			}
 
			fixed4 frag(v2f i) : SV_Target{

				 //读取片元对应法线贴图的颜色
				fixed4 packedNormal = tex2D(_BrokenNormalMap,i.uv.zw);

				//将颜色转换成法线方向
				fixed3 tangentNormal;
				tangentNormal=UnpackNormal(packedNormal);
				
				//将法线方向按照原来倾斜的方向倾斜更多
				tangentNormal.xy*=_BrokenScale;
				float2 offset = tangentNormal.xy;
 
				fixed3 lightColor = fixed3(1,1,1);

				//如果没有offset 则每个片元则按照
                //自己在主帖图的原uv位置读取颜色值
                //加了offset表示的意思是原uv位置基础上
                //加上片元对应玻璃破碎法线贴图上法线偏移值来
                //读取颜色值
                //一般法线贴图除了碎痕，某个片区都是一边倒的
                //因为一个片区的颜色一般都一致 所以片区的法线的xy值是一致的
                //这样就呈现出了片区的图像是原图往一个方向偏移的效果
				fixed3 col=tex2D(_MainTex,i.uv.xy+offset).rgb;
				
				//取得片元本身颜色的平均值
                //片元本身颜色值越深 其平均值越大
				fixed luminance = (col.r + col.g + col.b) / 3;

				//将颜色的rgb值变得一样
                //rgb值一致的时候 颜色是属于白灰黑色系
                //值越小越偏黑 越偏大越偏白 中间过渡阶段是各种灰色
				fixed3 gray = fixed3(luminance,luminance,luminance);

				//lerp函数使得
                //finalCol的范围在gray和col之间
                //_LuminanceScale为0的时候是gray
                //_LuminanceScale为1的时候是col
				fixed3 finalCol = lerp(col,gray,0.25);
					
				//这里如果不需要有灰度值变化，也可以直接使用col作为输出
				return fixed4(col,1.0f);
			}
			ENDCG
		}
		
	
	FallBack "Diffuse"
}



/*

// Broken picture - by JiepengTan - 2018
// jiepengtan@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//you can modify the "MoveOffset" function to get better explode effect

#define NUM 30	// chip center point num
#define DRAW_POINTS 0 // draw the center points
#define DRAW_GAP_LINE 1 // draw the gap line
// xy  is center point's coord
// zw  is chip 's move offset
vec4 chipInfo[NUM];//
// crack's offset
vec2 center =vec2(.0,-.0);//creak center pos

float rnd(vec2 s)
{
    return 1.-2.*fract(sin(s.x*253.13+s.y*341.41)*589.19);
}
float rand(float x)
{
    return fract(sin(x*873.15)*519.19);
}
//find the nearest point
int GetNearPos(vec2 p){
    vec2 v = chipInfo[0].xy;
    int idx = 0;
	for(int c=0;c<NUM;c++)
    {
        vec2 vc=chipInfo[c].xy;
        vec2 vp2 =vc-p;
        vec2 vp = v-p;
        if(dot(vp2,vp2)<dot(vp,vp))
        {
	        v=vc;
            idx = c;
        }
    }
    return idx;
}

// calculate the ith chip's move offset
vec2 MoveOffset(int idx,float t){
    vec2 offset = vec2(0.);
    float radVal  =rand(float(idx+1))+0.1;
    vec2 centerPos = chipInfo[idx].xy;
    vec2 diff = centerPos -center;
    float dist = length(diff);
    if(t>0.0)
    {
        //init velocity
        vec2 initVel = normalize(diff)*dist*1.;
        //add gravity
        offset = initVel*t + vec2(0.,1.)* t*t*-0.5;	
    }
    return offset;
}

// ref https://www.shadertoy.com/view/XdBSzW
float GetGapFactor(vec2 p){
	vec2 v=vec2(1E3);
    vec2 v2=vec2(1E4);
    //find the most near pos v and v2
    for(int c=0;c<NUM;c++)
    {
        vec2 vc=chipInfo[c].xy;
        if(length(vc-p)<length(v-p))
        {
            v2=v;
            v=vc;
        }
        else if(length(vc-p)<length(v2-p))
        {
            v2=vc;
        }
    }
    //check for whether p is at the middle of v and v2
    float factor= abs(length(dot(p-v,normalize(v-v2)))-length(dot(p-v2,normalize(v-v2))))
        +.002*length(p-center);
    factor=7E-4/factor;
    if(length(v-v2)<4E-3) factor=0.;
    if(factor<.01) factor = 0.;
    return factor;

}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p=(fragCoord.xy*2.-iResolution.xy)/iResolution.x;
    
    vec2 center=vec2(.0,-.0);
    float isNear = 0.;
  
    float modT = mod(iTime,5.);
    float time = modT-3.;
    
    for(int c=0;c<NUM;c++)
    {
        //1.generate Random point 
        float angle=floor(rnd(vec2(float(c),387.44))*16.)//-15~15
            *3.1415*.4-.5;
        float dist=pow(rnd(vec2(float(c),78.21)),2.)*.5;//0~0.5
        vec2 vc=vec2(center.x+cos(angle)*dist,
                     center.y+sin(angle)*dist);
        chipInfo[c].xy= vc.xy;
        //2.compute each chip's move offset
        chipInfo[c].zw = MoveOffset(c,time);
    }
    int belongIdx = -1;
    for(int c=0;c<NUM;c++)
    {
        //3.get raw pos 
        vec2 rawPos = p - chipInfo[c].zw;
        //4.compute which chip the rawPos locate at
        int idx = GetNearPos(rawPos);
        if(idx == c){
            belongIdx = c;
        	break;
        }
    }
    vec3 finalCol = vec3(0.);
    // if this fragment is belong to any chip
    if(belongIdx != -1){
        vec2 moveOffset = chipInfo[belongIdx].zw;
        //calc the raw pos before the picture is broken
        vec2 rawPos = p - moveOffset;
        //5.calc the uv from the raw pos
        vec2 rawCoord = (rawPos*iResolution.x + iResolution.xy)* 0.5;
        rawCoord.y =iResolution.y-rawCoord.y;
        // simulate the reflect effect 
        vec2 brokenOffset = vec2(rnd(vec2(belongIdx))*.006);
        vec2 uv =(rawCoord.xy)/iResolution.xy + brokenOffset;
        
        vec4 tex=texture(iChannel0,uv);
        finalCol = tex.xyz;
        
        //if uv is out of window then get black color
        if(time>0.){
            if(uv.x>1.||uv.x<0.||uv.y>1.||uv.y<0.){
                finalCol = vec3(0.);
            }
        }
    }
    #if DRAW_GAP_LINE
    if(time<0.)
    {
        //draw Gap line
        float gapFactor = GetGapFactor(p);
        finalCol=gapFactor*vec3(1.-finalCol.xyz)+(1.-gapFactor)*finalCol.xyz;
        //draw the points
        #if  DRAW_POINTS
        float isNear = 0.;
        for(int c=0;c<NUM;c++)
        {
            vec2 vc = chipInfo[c].xy;
            //get raw pos 
            if(length(vc-p)<0.01){
                isNear = 1.;
            }
        }
        finalCol = finalCol *(1.-isNear);
        #endif
    }
    #endif
  
    fragColor = vec4(finalCol,1.);
}
*/