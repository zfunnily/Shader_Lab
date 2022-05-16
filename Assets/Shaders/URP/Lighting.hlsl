
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

float3 Diffuse(float3 normal)
{
	//精度转换 法线归一
	float3 worldNormal = normalize(TransformObjectToWorldNormal(normal));
    //世界光照的方向 
    float3 worldLightDir = normalize(_MainLightPosition.xyz);
    //环境
    float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
	//根据兰伯特模型计算像素的光照信息，小于0的部分理解为看不见，置为0
	float3 lambert = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
	return _MainLightColor.rgb * lambert + ambient;
}