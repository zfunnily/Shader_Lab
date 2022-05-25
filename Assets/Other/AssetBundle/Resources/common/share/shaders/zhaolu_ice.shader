// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "zhaolu/ice"
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
		Tags{ "RenderType" = "Custom"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		ZWrite On
		Blend SrcAlpha OneMinusSrcAlpha
		
		GrabPass{ "RefractionGrab1" }
		CGPROGRAM
		#pragma target 3.0
		#pragma multi_compile _ALPHAPREMULTIPLY_ON
		#pragma exclude_renderers xbox360 xboxone ps4 psp2 n3ds wiiu 
		#pragma surface surf StandardSpecular keepalpha finalcolor:RefractionF noshadow exclude_path:deferred nolightmap  nodynlightmap nodirlightmap 
		struct Input
		{
			float2 uv_texcoord;
			float3 worldPos;
			float3 worldNormal;
			INTERNAL_DATA
			float4 screenPos;
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
		uniform sampler2D RefractionGrab1;
		uniform float _ChromaticAberration;
		uniform sampler2D _RefractionTex;
		uniform float4 _RefractionTex_ST;
		uniform float _RefractionPower;

		inline float4 Refraction( Input i, SurfaceOutputStandardSpecular o, float indexOfRefraction, float chomaticAberration ) {
			float3 worldNormal = o.Normal;
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
			float3 worldViewDir = normalize( UnityWorldSpaceViewDir( i.worldPos ) );
			float3 refractionOffset = ( ( ( ( indexOfRefraction - 1.0 ) * mul( UNITY_MATRIX_V, float4( worldNormal, 0.0 ) ) ) * ( 1.0 / ( screenPos.z + 1.0 ) ) ) * ( 1.0 - dot( worldNormal, worldViewDir ) ) );
			float2 cameraRefraction = float2( refractionOffset.x, -( refractionOffset.y * _ProjectionParams.x ) );
			float4 redAlpha = tex2D( RefractionGrab1, ( projScreenPos + cameraRefraction ) );
			float green = tex2D( RefractionGrab1, ( projScreenPos + ( cameraRefraction * ( 1.0 - chomaticAberration ) ) ) ).g;
			float blue = tex2D( RefractionGrab1, ( projScreenPos + ( cameraRefraction * ( 1.0 + chomaticAberration ) ) ) ).b;
			return float4( redAlpha.r, green, blue, redAlpha.a );
		}

		void RefractionF( Input i, SurfaceOutputStandardSpecular o, inout half4 color )
		{
			#ifdef UNITY_PASS_FORWARDBASE
			float2 uv_RefractionTex = i.uv_texcoord * _RefractionTex_ST.xy + _RefractionTex_ST.zw;
			float4 tex2DNode17 = tex2D( _RefractionTex, uv_RefractionTex );
			float4 appendResult18 = (float4(tex2DNode17.r , tex2DNode17.g , 0.0 , 0.0));
			color.rgb = color.rgb + Refraction( i, o, ( appendResult18 * _RefractionPower ).x, _ChromaticAberration ) * ( 1 - color.a );
			color.a = 1;
			#endif
		}

		void surf( Input i , inout SurfaceOutputStandardSpecular o )
		{
			o.Normal = float3(0,0,1);
			float2 uv_Diffuse = i.uv_texcoord * _Diffuse_ST.xy + _Diffuse_ST.zw;
			o.Albedo = ( tex2D( _Diffuse, uv_Diffuse ) * _DiffuseColor ).rgb;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float fresnelNdotV10 = dot( ase_worldNormal, ase_worldViewDir );
			float fresnelNode10 = ( 0.0 + _FresnelScale * pow( 1.0 - fresnelNdotV10, _FresnelPower ) );
			o.Emission = ( ( _EmissionColor * _EmissionPower ) + ( fresnelNode10 * _FresnelColor ) ).rgb;
			o.Alpha = _Opacity;
			o.Normal = o.Normal + 0.00001 * i.screenPos * i.worldPos;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=16301
428;332;1310;700;1030.644;239.0405;1.480937;True;True
Node;AmplifyShaderEditor.CommentaryNode;15;-1608.02,228.1976;Float;False;829.5336;472.9204;Fresnel;5;13;10;12;14;50;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;49;-1419.09,-226.8954;Float;False;549.0504;398.9614;Emission;3;46;47;48;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;21;-694.6648,286.1;Float;False;858.5377;407.6543;Refraction;4;17;18;20;19;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;50;-1572.235,303.0745;Float;False;Property;_FresnelScale;FresnelScale;11;0;Create;True;0;0;False;0;0;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;14;-1577.489,420.6814;Float;False;Property;_FresnelPower;FresnelPower;8;0;Create;True;0;0;False;0;0;1.64;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;9;-707.2333,-566.5928;Float;False;736.1809;553.4761;Diffuse;3;8;7;4;;1,1,1,1;0;0
Node;AmplifyShaderEditor.FresnelNode;10;-1357.821,292.3537;Float;True;Standard;WorldNormal;ViewDir;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;17;-642.6073,342.2691;Float;True;Property;_RefractionTex;RefractionTex;10;0;Create;True;0;0;False;0;None;ac2f7aa9408068546a1c967104dc7103;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;46;-1381.266,-149.5198;Float;False;Property;_EmissionColor;EmissionColor;6;0;Create;True;0;0;False;0;0,0,0,0;0,0.7412872,0.9433962,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;12;-1327.779,526.6697;Float;False;Property;_FresnelColor;FresnelColor;5;0;Create;True;0;0;False;0;0,0,0,0;0.9103774,0.9871967,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;47;-1364.12,25.45544;Float;False;Property;_EmissionPower;EmissionPower;12;0;Create;True;0;0;False;0;0;0.3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;7;-528.4725,-209.0695;Float;False;Property;_DiffuseColor;DiffuseColor;7;0;Create;True;0;0;False;0;0,0,0,0;0,0.05696545,0.4528302,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;4;-575.6886,-461.9683;Float;True;Property;_Diffuse;Diffuse;3;0;Create;True;0;0;False;0;None;d13dfc3e368ca45c191b1f5104f6643b;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;48;-1075.056,-143.7713;Float;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;13;-986.696,289.7719;Float;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;18;-266.2883,371.0586;Float;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;19;-264.2313,578.7545;Float;False;Property;_RefractionPower;RefractionPower;0;0;Create;True;0;0;False;0;0;-2.51;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;8;-145.9748,-332.6257;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;28;-273.1013,138.7082;Float;False;Property;_Opacity;Opacity;9;0;Create;True;0;0;False;0;0;0.55;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;11;-630.2085,30.08561;Float;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;11.32532,371.0579;Float;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;341.8593,-87.40053;Float;False;True;2;Float;ASEMaterialInspector;0;0;StandardSpecular;zhaolu/ice;False;False;False;False;False;False;True;True;True;False;False;False;False;False;True;False;False;False;False;False;Back;1;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;False;0;True;Custom;;Transparent;ForwardOnly;True;True;True;True;True;True;True;False;False;False;False;False;False;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;2;5;False;-1;10;False;-1;0;5;False;-1;10;False;-1;0;False;-1;0;False;-1;1;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;4;-1;1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;10;2;50;0
WireConnection;10;3;14;0
WireConnection;48;0;46;0
WireConnection;48;1;47;0
WireConnection;13;0;10;0
WireConnection;13;1;12;0
WireConnection;18;0;17;1
WireConnection;18;1;17;2
WireConnection;8;0;4;0
WireConnection;8;1;7;0
WireConnection;11;0;48;0
WireConnection;11;1;13;0
WireConnection;20;0;18;0
WireConnection;20;1;19;0
WireConnection;0;0;8;0
WireConnection;0;2;11;0
WireConnection;0;8;20;0
WireConnection;0;9;28;0
ASEEND*/
//CHKSM=CC4C6197678A697470F543EA93D61A83AD7C1715