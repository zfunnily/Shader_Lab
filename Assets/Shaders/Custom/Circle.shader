// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Circle" {
Properties {
_Color ("Color", Color) = (1,1,1,1)
_Width("RoundWidth", float) = 0.03
}
 
SubShader {
Pass {
ZTest Off
ZWrite Off
ColorMask 0
}
 
Pass {
Blend SrcAlpha OneMinusSrcAlpha
CGPROGRAM
 
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
 
struct v2f {
    float4 pos : SV_POSITION;
    float4 uv : TEXCOORD1;
};
fixed4 _Color;
int _Width;
 
 
 
float4 _MainTex_ST;
    v2f vert (appdata_base v){
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    return o;
}
 
fixed4 frag(v2f i) : COLOR{

    float dis = sqrt(i.uv.x * i.uv.x + i.uv.y * i.uv.y);
    if(dis>0.5){
        c = float4(1, 1, 1, 1);
        discard;
    }else if(dis<_Border && dis<_Border-_Width){
        c = float4(1, 1, 1, 1);
    }else{
        c = float4(1, 0, 0, 1);
    }
    return c;
    float maxDistance = 0.05;
    if(dis > 0.5){
        discard;
    }else{
        float ringWorldRange = unity_ObjectToWorld[0][0];
        float minDistance =(ringWorldRange * 0.43 - _Width)/ringWorldRange * 0.9;
        if(dis < minDistance){
            discard;
        }
    _Color.a = (dis - minDistance)/(1 - minDistance) * 0.9;
    }
    return _Color;
}
 
ENDCG
}
}
 
FallBack "Diffuse"
 
 
}