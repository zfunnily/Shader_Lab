Shader "Custom/BrokenPictureDDDD"
{
	Properties{
	//Properties
        _MainTex ("Main Tex", 2D) = "white" {}
		_BrokenNormalMap("BrokenNormal Map",2D)="bump"{}
		_BrokenScale("BrokenScale",Range(0,2.5))=1.0
		_RotateSpeed("_RotateSpeed",Range(0,2.5))=1.0
	}

	SubShader
	{
        LOD 200		
	    Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
	Pass
    {
        Tags { "LightMode"="ForwardBase" }

    	ZWrite Off
    	Blend SrcAlpha OneMinusSrcAlpha

    	CGPROGRAM
    	#pragma vertex vert
    	#pragma fragment frag
        #pragma enable_d3d11_debug_symbols
        #pragma target 3.0
    	#include "UnityCG.cginc"

        sampler2D _MainTex;
		float4 _MainTex_ST;
		sampler2D _BrokenNormalMap;
		float4 _BrokenNormalMap_ST;
		float _BrokenScale;
		float _RotateSpeed;

    	struct VertexInput {
            float4 vertex : POSITION;
    	    float4 uv:TEXCOORD0;
            float4 tangent : TANGENT;
            float3 normal : NORMAL;
    	};


    	struct VertexOutput {
    	    float4 pos : SV_POSITION;
    	    float4 uv:TEXCOORD0;
    	};

    	// Variables
    	// Broken picture - by JiepengTan - 2018
        // jiepengtan@gmail.com
        // License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

        // you can fmodify the "MoveOffset" function to get better explode effect

        #define NUM 30	// chip center point num
        #define DRAW_POINTS 0 // draw the center points
        #define DRAW_GAP_LINE 1 // draw the gap line
        // xy  is center point's coord
        // zw  is chip 's move offset
        fixed4 chipInfo[NUM];//
        // crack's offset
        fixed2 center =fixed2(.0,-.0);//creak center pos

        float rnd(fixed2 s)
        {
            return 1.-2.*frac(sin(s.x*253.13+s.y*341.41)*589.19);
        }
        float rand(fixed x)
        {
            return frac(sin(x*873.15)*519.19);
        }
        //find the nearest point
        int GetNearPos(fixed2 p){
            fixed2 v = chipInfo[0].xy;
            int idx = 0;
        	[unroll(100)]
            for(int c=0;c<NUM;c++)
            {
                fixed2 vc=chipInfo[c].xy;
                fixed2 vp2 =vc-p;
                fixed2 vp = v-p;
                if(dot(vp2,vp2)<dot(vp,vp))
                {
        	        v=vc;
                    idx = c;
                }
            }
            return idx;
        }

        // calculate the ith chip's move offset
        fixed2 MoveOffset(int idx,fixed t){
            fixed2 offset = fixed2(0.,0.);
            fixed radVal  =rand(fixed(idx+1))+0.1;
            fixed2 centerPos = chipInfo[idx].xy;
            fixed2 diff = centerPos -center;
            fixed dist = length(diff);
            if(t>0.0)
            {
                //init velocity
                fixed2 initVel = normalize(diff)*dist*1.;
                //add gravity
                offset = initVel*t + fixed2(0.,1.)* t*t*-0.5;	
            }
            return offset;
        }

        // ref https://www.shadertoy.com/view/XdBSzW
        fixed GetGapFactor(fixed2 p){
        	fixed2 v=fixed2(1E3,1E3);
            fixed2 v2=fixed2(1E4,1E4);
            //find the most near pos v and v2
            [unroll(100)]
            for(int c=0;c<NUM;c++)
            {
                fixed2 vc=chipInfo[c].xy;
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
            fixed factor= abs(length(dot(p-v,normalize(v-v2)))-length(dot(p-v2,normalize(v-v2))))
                +.002*length(p-center);
            factor=7E-4/factor;
            if(length(v-v2)<4E-3) factor=0.;
            if(factor<.01) factor = 0.;
            return factor;
        }

        //围绕x旋转
        float4x4 doTwistX(float angle)
        {
            float cosAngle = cos(angle);
            float sinAngle = sin(angle);
            return float4x4(1, 0, 0, 0,
                            0, cosAngle, -sinAngle, 0,
                            0, sinAngle, cosAngle, 0,
                            0, 0, 0, 1);
        }

        //围绕y旋转
        float4x4 doTwistY(float angle)
        {
            float cosAngle = cos(angle);
            float sinAngle = sin(angle);
            return float4x4(cosAngle, 0, sinAngle, 0,
                            0, 1, 0, 0,
                            -sinAngle, 0, cosAngle, 0, 
                            0, 0, 0, 1);
        }

        //围绕z旋转
        float4x4 doTwistZ(float angle)
        {
            float cosAngle = cos(angle);
            float sinAngle = sin(angle);
            return float4x4(cosAngle, -sinAngle, 0, 0,
                            sinAngle, cosAngle, 0, 0,
                            0, 0, 1, 0,
                            0, 0, 0, 1);
        }

        VertexOutput vert (VertexInput v)
        {
            VertexOutput o;
            // fixed4 rotPos = mul(doTwistX(_RotateSpeed*_BrokenScale),v.vertex);
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv.xy =TRANSFORM_TEX(v.uv,_MainTex);
            o.uv.z = v.uv.z;

            // float2 pivot = float2(0.5, 0.5);         //中心点
            // float2x2 rot = doTwistX(_RotateSpeed*_BrokenScale);  //确定以x轴旋转
            // uv = uv - pivot;
            // uv = mul(rot, uv);           //旋转矩阵相乘变换坐标
            // uv += pivot;

            //VertexFactory
            return o;
        }

        fixed4 frag(VertexOutput i) : SV_TARGET
        {
            // fixed2 p=(i.uv.xy*2.-_ScreenParams.xy)/_ScreenParams.x;
           fixed2 p=(i.uv.xy*2.-1)/1;
           fixed2 center=fixed2(.0,.0);
           fixed isNear = 0.;
    
           fixed fmodT = fmod(_Time.y,5.);
        //    fixed time = fmodT-3.;
            fixed time = _BrokenScale;

           [unroll(100)]
           for(int c=0;c<NUM;c++)
           {
                //1.generate Random point 
                fixed angle=floor(rnd(fixed2(fixed(c),387.44))*16.)//-15~15
                    *3.1415*.4-.5;
                fixed dist = pow(rnd(fixed2(fixed(c),78.21)),2.)*.5;//0~0.5
                fixed2 vc = fixed2(center.x+cos(angle)*dist, center.y+sin(angle)*dist);
                chipInfo[c].xy= vc.xy;
                //2.compute each chip's move offset
                chipInfo[c].zw = MoveOffset(c,time);
           }

           int belongIdx = -1;
           for (int c = 0; c < NUM; c ++)
           {
               //3 get raw pos
               fixed2 rawPos = p - chipInfo[c].zw;
               //4. compute which chip the rawPos local at
               int idx = GetNearPos(rawPos);
               if (idx == c)
               {
                   belongIdx = c;
                   break;
               }
           }

           fixed3 finalCol = fixed3(0.,0.,0.);
           // if this fragment is belong to any chip
           fixed a = 0.0;
           if (belongIdx != -1)
           {
               fixed2 moveOffset = chipInfo[belongIdx].zw;
               //calc the raw pos before the picture is broken
               fixed2 rawPos = moveOffset - p;
               //5. calc the uv from the raw pos
               fixed2 rawCoord = (rawPos*_ScreenParams.x + _ScreenParams.xy) * 0.5;
               rawCoord.y = _ScreenParams.y - rawCoord.y;
               // simulat the reflect effect
               fixed2 brokenOffset = fixed2(rnd(fixed2(belongIdx, 0.))*0.006, 0.);

               float4 uv;
               uv.xy = (rawCoord.xy)/_ScreenParams.x + brokenOffset;
               uv.z = i.uv.z;
               uv.w = 1;

               uv.xy = uv.xy - float2(.5, .5);
               uv = mul(doTwistX(_RotateSpeed*_BrokenScale), uv);
               uv.xy = uv.xy + float2(.5, .5);

               fixed4 tex = tex2D(_MainTex, uv);
               finalCol = tex.xyz;
               a = 1.0;

               // if uv is out of window the get black color
               if (time>0.)
               {
                   if (uv.x>1. || uv.x<0. || uv.y>1. ||uv.y<0.) {
                       finalCol = fixed3(0.,0.,0.);
                       a = 0.0;
                   }
               }
           }

           if (time < 0.)
           {
               //draw gap line
               fixed gapFactor = GetGapFactor(p);
               finalCol = gapFactor*fixed3(1.-finalCol.xyz) + (1.-gapFactor)*finalCol.xyz;
               //draw the points
               float isNear = 0.;
               for (int c=0; c < NUM; c++)
               {
                   fixed2 vc = chipInfo[c].xy;
                   // get raw pos
                   if (length(vc-p) < 0.01)
                   {
                       isNear = 1.;
                   }
               }

               finalCol = finalCol*(1.-isNear);
               a = 1.0;
            }

            return fixed4(finalCol, a);
        }
        ENDCG
        }
    // FallBack Off
    }
}