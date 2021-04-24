// https://xoxor4d.github.io/
// stock-ps "l_omni_r0c0.hlsl"
// LIGHT OMNI

#define PC
#define IS_VERTEX_SHADER 0
#define IS_PIXEL_SHADER 1

#define FOG // shader uses fog

#include <shader_vars.h>
#include <lib/pixel_setup_dtex.hlsl>

struct PS_IN
{
    float4 color        : COLOR;
    float2 texcoord     : TEXCOORD;
    float4 world_normal : TEXCOORD1;
    float3 world_pos    : TEXCOORD5;
};

float4 ps_main(PS_IN i) : COLOR
{
    // shader output
    float4 color;
    
    // normalize shader input
    float3  nrm_world_normal = normalize(i.world_normal.xyz); // xyz / length(xyz)

    // color sample
	float4  color_sample      = tex2D(colorMapSampler, i.texcoord);
	        color_sample.rgb *= i.color.rgb;
    
	float3  color_combined;
    
    // omni light
    float3  omni_direction  = lightPosition.xyz + -i.world_pos;
    float   omni_distance   = length(omni_direction); // sqrt(dot(v,v));
    
            omni_direction  = omni_direction * (1 / omni_distance);
    
    float3  omni_diffuse    = saturate(dot(omni_direction, nrm_world_normal)) * lightDiffuse.rgb;
    float4  attenuation     = tex2D(attenuationSampler, saturate(omni_distance * lightPosition.w));
            
            color_combined  = color_sample.rgb * attenuation.rgb * omni_diffuse;
    
    // ---------

    #ifdef FOG
        color.xyz = pixel_add_fog_to_final_color(color_combined, i.world_normal.w);
    #else // IF NOT FOG
        color.xyz = color_combined;
    #endif

    #ifdef SHADER_DEBUG
        color.r -= 0.2f;
        color.g -= 0.4f;
        color.b += 0.5f;
    #endif
    
	color.w = 1.0f;
    
	return color;
}
