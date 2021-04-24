// https://xoxor4d.github.io/
// stock-ps "lp_hsm_sun_r0c0s0_sm3.hlsl"
// LIT SUN SHADOW

#define PC
#define IS_VERTEX_SHADER 0
#define IS_PIXEL_SHADER 1

#define TECHSET_HSM // if using a hsm techset (hardware shadowmapping)
#define FOG         // shader uses fog

#define TECH_LIT            // lit shader
#define TECH_SUN            // lit sun shader, needs the above
#define TECH_SHADOW_SUN     // shader uses shadowmapping
//#define TECH_SPOT           // spotlight shader
//#define TECH_SHADOW_SPOT    // spotlight shader + spotlight shadows

// ---- 
#ifdef TECH_LIT 
    #define LIT
    #ifdef TECH_SUN
        #define SUN
    #endif
#endif

#ifdef TECH_SPOT
    #define SPOT
#endif
// ----

#include <shader_vars.h>
#include <lib/pixel_setup_dtex.hlsl>

struct PS_IN
{
    float3 color        : COLOR;
    float2 texcoord     : TEXCOORD;
    float4 world_normal : TEXCOORD1;
    
#if defined(TECH_SHADOW_SUN) || defined(TECH_SHADOW_SPOT)
    float4 world_shadows : TEXCOORD4;
#endif
    
    float3 world_pos    : TEXCOORD5;
    float3 light_coords : TEXCOORD6;
};

float4 ps_main(PS_IN i) : COLOR
{
    // shader output
    float4 color;
    
    // normalize shader input
    float3  nrm_world_pos    = normalize(i.world_pos);
    float3  nrm_world_normal = normalize(i.world_normal.xyz); // xyz / length(xyz)

    // probe lighting (see CoD2 reference)
    float4  lightprobe_diffuse = pixel_sample_probelighting(nrm_world_normal, i.light_coords);

    // sample specularmap
	float4  specular_sample = tex2D(specularMapSampler, i.texcoord);

    // reflect
    float   NdotV = dot(nrm_world_normal, nrm_world_pos);
    float   NH2   = NdotV * 2;
            NdotV = -abs(NdotV) + 1;

    // setup reflectionprobe coords + sample
    float3  reflection_probe_coords = pixel_setup_reflection_coordinates(nrm_world_normal, nrm_world_pos, NH2);
    float4  reflection_sample       = pixel_sample_reflection(reflection_probe_coords, specular_sample.w);

    #if defined(SUN) || defined(LIT)
    
        // Phong_SpecularVisibility (CoD2)
		float sunlight_visibility_spec = lerp(envMapParms.x, envMapParms.y, pow(NdotV, envMapParms.z));
	
    #endif

    // -----------------------------------------------------------------
    
    #if defined(TECH_SHADOW_SUN)
    
        // sample shadow
	    float shadow_scalar = pixel_sample_sunshadow(i.world_shadows, lightprobe_diffuse.w);

    #endif
    
    #if defined(TECH_SHADOW_SPOT)
    
        float   shadow_scalar;
        float4  spotshadow_sample;
        
                spotshadow_sample.x = tex2Dproj(shadowmapSamplerSpot, float4(i.world_shadows.w *  spotShadowmapPixelAdjust.xy + i.world_shadows.xy, i.world_shadows.zw)).x;
                spotshadow_sample.y = tex2Dproj(shadowmapSamplerSpot, float4(i.world_shadows.w * -spotShadowmapPixelAdjust.xy + i.world_shadows.xy, i.world_shadows.zw)).x;
                spotshadow_sample.z = tex2Dproj(shadowmapSamplerSpot, float4(i.world_shadows.w *  spotShadowmapPixelAdjust.zw + i.world_shadows.xy, i.world_shadows.zw)).x;
                spotshadow_sample.w = tex2Dproj(shadowmapSamplerSpot, float4(i.world_shadows.w * -spotShadowmapPixelAdjust.zw + i.world_shadows.xy, i.world_shadows.zw)).x;
        
                shadow_scalar = lerp(lightprobe_diffuse.w , dot(spotshadow_sample, 0.25), lightSpotFactors.w);
    
    #endif
    
    
    // color sample
	float4  color_sample = tex2D(colorMapSampler, i.texcoord);
	        color_sample.xyz *= i.color;
    
	float3  color_combined;
    
    
    #ifdef SPOT
    
        // setup spotlight
	    float3  position_to_light_source = lightPosition.xyz + -i.world_pos;
	    float   distance = length(position_to_light_source); // sqrt(dot(v,v));
                
	            position_to_light_source = position_to_light_source * (1 / distance);

	    float4  attenuation = tex2D(attenuationSampler, saturate(distance * lightPosition.w));
        
	    float   light_settings = saturate(dot(position_to_light_source, lightSpotDir.xyz) * lightSpotFactors.x + lightSpotFactors.y);
	            light_settings = (-light_settings >= 0) ? 0 : pow(light_settings, lightSpotFactors.z);
        
	            attenuation.xyz *= light_settings;
        
        #ifdef TECH_SHADOW_SPOT
	            attenuation.xyz *= shadow_scalar;
        #else
                attenuation.xyz *= lightprobe_diffuse.w;
        #endif
	            
        
        // cosine
	    float   NdotL = saturate(dot(position_to_light_source, nrm_world_normal));
	    float   RdotL = dot(reflection_probe_coords, position_to_light_source);
	            RdotL += -0.99925;
        
	    float   cosine = (exp2(specular_sample.w * 9.377518) + 7) * RdotL * 1.442695; // LOG2
	            cosine = saturate(exp2(cosine));
        
        // spotlight specular
	    float   spotlight_visibility_spec = lerp(envMapParms.x, envMapParms.y, pow(NdotV, envMapParms.z));
	    float3  spotlight_specular = (attenuation.xyz * envMapParms.w * lightSpecular.xyz * cosine + reflection_sample.xyz)
                                     * specular_sample.xyz * spotlight_visibility_spec;
        
	    float3  spotlight_diffuse = attenuation.xyz * NdotL * lightDiffuse.xyz + (lightprobe_diffuse.xyz * 2);
	            color_combined = color_sample.xyz * spotlight_diffuse + spotlight_specular;
    
    #else // IF NOT SPOT
    
        // calculate sun cosine
        float cosine = pixel_calculate_cosine_sun(reflection_probe_coords, specular_sample.w);
	
    #endif
    
    // -----------------------------------------------------------------
    
    #if defined(LIT) || defined(SUN)
        // lit, lit-sun or lit-sun-shadow variants

        #if !defined(LIT) && defined(SUN)
            // "disable" lightprobe scalar if not a lit-only shader
	        lightprobeDiffuse.w = 1.0; 
        #endif
    
        #if !defined(TECH_SHADOW_SUN) && !defined(TECH_SHADOW_SPOT)
            // "disable" shadow scalar for non shadow shaders
    		float shadow_scalar = 1;
        #endif
    
        float3 sunlight_specular = pixel_calculate_sunlight_specular(reflection_sample, specular_sample, lightprobe_diffuse.w, cosine, shadow_scalar, sunlight_visibility_spec);
        float3 sunlight_diffuse  = pixel_calculate_sunlight_diffuse(nrm_world_normal);
    
        color_combined = pixel_calculate_combined_color_lit_sun_shadow(color_sample, sunlight_diffuse, sunlight_specular, lightprobe_diffuse, shadow_scalar);
	
    #endif 

    // -----------------------------------------------------------------

    #ifdef FOG
        color.xyz = pixel_add_fog_to_final_color(color_combined, i.world_normal.w);
    #else // IF NOT FOG
        color.xyz = color_combined;
    #endif

    #ifdef SHADER_DEBUG
        color.r += 1.0f;
        color.g += 1.0f;
    #endif
    
	color.w = 1.0f;
    
	return color;
}
