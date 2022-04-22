// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "UnityShaderBook/Chapter11/Chapter11-Billboard"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color Tine", Color) = (1, 1, 1, 1) 
        _VerticalBillboarding ("Vertical Restraints", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
        LOD 100

        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _VerticalBillboarding;

            v2f vert (appdata v)
            {
                v2f o;
                // Suppose the center in object space is fixed
                float3 center = float3(0, 0, 0);
                float3 viewer = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos, 1));
                float3 normalDir = viewer - center;
                // If _VerticalBillboarding equals 1, we use the desired view dir as the normal dir
                // Which means the normal dir is fixed
                // Or if _VerticalBillboarding equals 0, the y of normal is 0
                // Which means the up dir is fixed
                normalDir.y =normalDir.y * _VerticalBillboarding;
                normalDir = normalize(normalDir);
                // Get the approximate up dir
                // If normal dir is already towards up, then the up dir is towards front
                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
                float3 rightDir = normalize(cross(upDir, normalDir));
                upDir = normalize(cross(normalDir, rightDir));
                float3 centerOffs = v.vertex.xyz - center;
                float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;
                o.vertex = UnityObjectToClipPos(float4(localPos, 1));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 c = tex2D (_MainTex, i.uv);
                c.rgb *= _Color.rgb;
                return c;
            }
            ENDCG
        }
    }
    Fallback "Transparent/VertexLit"
}
