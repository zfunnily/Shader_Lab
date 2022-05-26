
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

float3 SpecularAndDiffuse(float3  worldNormal, float3 worldPos, float gloss)
{
	/* 首先计算基础信息 */
    Light light = GetMainLight();
    half3 lightDir = normalize(TransformObjectToWorldDir(light.direction));
    half3 viewDir =  normalize( GetCameraPositionWS() - worldPos);
    half3 reflectDir = normalize(reflect(lightDir,worldNormal));

    /* 计算漫反射 */
    half3 diffuse = saturate(dot(lightDir, worldNormal)) * _MainLightColor.rgb ;
       
    /* 计算高光 */
    float3 spec = pow(saturate(dot(viewDir,-reflectDir)), gloss) * _MainLightColor.rgb;
	return spec * diffuse;
}

// Light GetMainLight()
// {
//     Light light;
//     light.direction = _MainLightPosition.xyz;
//     light.distanceAttenuation = unity_LightData.z; 
//     light.shadowAttenuation = 1.0;
//     light.color = _MainLightColor.rgb;

//     return light;
// }