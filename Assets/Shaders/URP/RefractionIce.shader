Shader "URP/RefractionICE"
{
	Properties
	{
		_RefractionPower("RefractionPower", Float) = 0
		[Header(Refraction)]
		_ChromaticAberration("Chromatic Aberration", Range( 0 , 0.3)) = 0.1
		_Diffuse("Diffuse", 2D) = "white" {}
		_FresnelColor("FresnelColor", Color) = (0,0,0,0)
		_EmissionColor("EmissionColor", Color) = (0,0,0,0)
		_DiffuseColor("DiffuseColor", Color) = (0,0,0,0)
		_FresnelPower("FresnelPower", Float) = 0
		_Opacity("Opacity", Float) = 0
		_RefractionTex("RefractionTex", 2D) = "white" {}
		_FresnelScale("FresnelScale", Float) = 0
		_EmissionPower("EmissionPower", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"   "RenderPipeline"="UniversalPipeline"}
		Cull Back
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

		// GrabPass{ "RefractionGrab1" }
		Pass 
		{
			Tags{"LightMode" = "Grab"}
			HLSLPROGRAM
			#pragma multi_compile _ALPHAPREMULTIPLY_ON
			#pragma exclude_renderers xbox360 xboxone ps4 psp2 n3ds wiiu 
			// #pragma surface surf StandardSpecular keepalpha finalcolor:RefractionF noshadow exclude_path:deferred nolightmap  nodynlightmap nodirlightmap 
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord: TEXCOORD0;
				float4 worldPos : TEXCOORD1;
				float4 screenPos : TEXCOORD2;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 vertex : POSITION;
				float2 uvmain : TEXCOORD0;
				float4 worldPos : TEXCOORD1;
				float4 screenPos : TEXCOORD2;
				float3 normal : NORMAL;
			};

			uniform sampler2D _Diffuse;
			uniform float4 _Diffuse_ST;
			uniform float4 _DiffuseColor;
			uniform float4 _EmissionColor;
			uniform float _EmissionPower;
			uniform float _FresnelScale;
			uniform float _FresnelPower;
			uniform float4 _FresnelColor;
			uniform float _Opacity;
			uniform float _ChromaticAberration;
			uniform sampler2D _RefractionTex;
			uniform float4 _RefractionTex_ST;
			uniform float _RefractionPower;
			SAMPLER(_SourceTex);

			inline float4 Refraction( v2f i, float indexOfRefraction, float chomaticAberration ) {
				float3 worldNormal = i.normal;
				float4 screenPos = i.screenPos;
				#if UNITY_UV_STARTS_AT_TOP
					float scale = -1.0;
				#else
					float scale = 1.0;
				#endif
				float halfPosW = screenPos.w * 0.5;
				screenPos.y = ( screenPos.y - halfPosW ) * _ProjectionParams.x * scale + halfPosW;
				#if SHADER_API_D3D9 || SHADER_API_D3D11
					screenPos.w += 0.00000000001;
				#endif
				float2 projScreenPos = ( screenPos / screenPos.w ).xy;
				float3 worldViewDir = normalize( GetCameraPositionWS() - i.worldPos  );
				float3 refractionOffset = ( ( ( ( indexOfRefraction - 1.0 ) * mul( UNITY_MATRIX_V, float4( worldNormal, 0.0 ) ) ) * ( 1.0 / ( screenPos.z + 1.0 ) ) ) * ( 1.0 - dot( worldNormal, worldViewDir ) ) );
				float2 cameraRefraction = float2( refractionOffset.x, -( refractionOffset.y * _ProjectionParams.x ) );
				float4 redAlpha = tex2D(_SourceTex, ( projScreenPos + cameraRefraction ) );
				float green = tex2D( _SourceTex, ( projScreenPos + ( cameraRefraction * ( 1.0 - chomaticAberration ) ) ) ).g;
				float blue = tex2D( _SourceTex, ( projScreenPos + ( cameraRefraction * ( 1.0 + chomaticAberration ) ) ) ).b;
				return float4( redAlpha.r, green, blue, redAlpha.a );
			}

			v2f vert (appdata_t v)
			{
				v2f o;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
				o.vertex = vertexInput.positionCS;

				o.uvmain = TRANSFORM_TEX( v.texcoord, _Diffuse);
				o.normal = TransformObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex);
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}

			
			half4 frag( v2f i ) : SV_Target
			{
				float2 uv_Diffuse = i.uvmain * _Diffuse_ST.xy + _Diffuse_ST.zw;
				float3 albedo = ( tex2D( _Diffuse, uv_Diffuse ) * _DiffuseColor ).rgb; //1
				float3 ase_worldViewDir = normalize( GetCameraPositionWS() - i.worldPos);
				float3 ase_worldNormal = i.normal;
				float fresnelNdotV10 = dot( ase_worldNormal, ase_worldViewDir );
				float fresnelNode10 = ( 0.0 + _FresnelScale * pow( 1.0 - fresnelNdotV10, _FresnelPower ) );
				float3 Emission = ( ( _EmissionColor * _EmissionPower ) + ( fresnelNode10 * _FresnelColor ) ).rgb; //2
				float Alpha = _Opacity; //3

				float2 screenPos = i.screenPos.xy/i.screenPos.w;
    			screenPos.xy *= _ScreenParams.xy;
				float2 normal = i.normal + 0.00001 * screenPos * i.worldPos; //4

				float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;				
				float3 worldLightDir = normalize(_MainLightPosition.xyz - i.worldPos);
				float3 diffuse = _MainLightColor.rgb * albedo * max(0, dot(normal, worldLightDir));

				float4 color = 0;
				color.rgb += diffuse.rgb;
				color.rgb += Emission.rgb;

				float2 uv_RefractionTex = i.uvmain * _RefractionTex_ST.xy + _RefractionTex_ST.zw;
				float4 tex2DNode17 = tex2D( _RefractionTex, uv_RefractionTex );
				float4 appendResult18 = (float4(tex2DNode17.r , tex2DNode17.g , 0.0 , 0.0));
				color.rgb = color.rgb + Refraction( i, ( appendResult18 * _RefractionPower ).x, _ChromaticAberration ) * ( 1 - color.a );
				color.a = 1;
				return color;
			}

			ENDHLSL
		}
		
	}
	CustomEditor "ASEMaterialInspector"
}