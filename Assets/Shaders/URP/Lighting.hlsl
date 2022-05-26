
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

// Light GetMainLight()
// {
//     Light light;
//     light.direction = _MainLightPosition.xyz;
//     light.distanceAttenuation = unity_LightData.z; 
//     light.shadowAttenuation = 1.0;
//     light.color = _MainLightColor.rgb;

//     return light;
// }

/// albedo：反射系数
/// lightColor：光源颜色
/// lightDirectionWS：世界空间下光线方向
/// lightAttenuation：光照衰减
/// normalWS：世界空间下法线
/// viewDirectionWS：世界空间下视角方向
half3 LightingBased(half3 albedo, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS, half3 diffuse, half3 specular, float gloss)
{
    // 兰伯特漫反射计算
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL) * diffuse.rgb;
    // BlinnPhong高光反射
    half3 halfDir = normalize(lightDirectionWS + viewDirectionWS);
    half3 speculart = lightColor * pow(saturate(dot(normalWS, halfDir)), gloss) * specular.rgb;
    
    return(radiance + speculart) * albedo;
}

// 计算漫反射与高光
half3 LightingBased(half3 albedo, Light light, half3 normalWS, half3 viewDirectionWS, half3 diffuse, half3 specular, float gloss)
{
    // 注意light.distanceAttenuation * light.shadowAttenuation，这里已经将距离衰减与阴影衰减进行了计算
    return LightingBased(albedo, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, diffuse, specular, gloss);
}
            