// custom development dir shader_vars file for visual studio (preprocessor defined in lib/shadertoolsconfig.json)
#ifdef EXCLUDE_SHADERVARS_ON_RELEASE
    #include <../shader_vars.h>
#endif

/// *
/// setup reflection sample coordinates
float3 pixel_setup_reflection_coordinates( const float3 normalized_world_normal, const float3 normalized_world_position, const float NH2 )
{
	return normalized_world_normal * -NH2 + normalized_world_position;
}


/// *
/// calculate sun cosine
float pixel_calculate_cosine_sun( const float3 reflection_probe_coordinates, const float cosine_sample )
{
    float   RdotS = saturate(dot(reflection_probe_coordinates, sunPosition.xyz));
            RdotS += -0.99925;
    
    float   cosine = (exp2(cosine_sample * 9.377518) + 7) * RdotS * 1.442695; // LOG2
    
    return  saturate(exp2(cosine));
}


/// *
/// calculate spotlight cosine
float pixel_calculate_cosine_spot( const float3 reflection_probe_coordinates, const float3 light_direction, const float cosine_sample )
{
    float   RdotL = dot(reflection_probe_coordinates, light_direction);
	        RdotL += -0.99925;
        
	float   cosine = (exp2(cosine_sample * 9.377518) + 7) * RdotL * 1.442695; // LOG2
	
	return	saturate(exp2(cosine));
}

/// *
/// calculate sunlight specular
float3 pixel_calculate_sunlight_specular( const float4 reflection_sample, const float4 specular_sample, const float lightprobe_diffuse_alpha, const float cosine, const float shadow_scalar, const float sunlight_visibility_spec )
{
	return (lightprobe_diffuse_alpha * envMapParms.w * sunSpecular * cosine * shadow_scalar + reflection_sample) 
		   * specular_sample * sunlight_visibility_spec;
}


/// *
/// calculate spotlight specular
float3 pixel_calculate_spotlight_specular( const float4 reflection_sample, const float4 specular_sample, const float4 attenuation, const float cosine, const float spotlight_visibility_spec )
{
	return (attenuation.xyz * envMapParms.w * lightSpecular.xyz * cosine + reflection_sample.xyz)
           * specular_sample.xyz * spotlight_visibility_spec;
}


/// *
/// calculate sunlight diffuse
float3 pixel_calculate_sunlight_diffuse( const float3 normalized_world_normal )
{
	return saturate(dot(sunPosition.xyz, normalized_world_normal)) * sunDiffuse;
}


/// *
/// calculate spotlight diffuse
float3 pixel_calculate_spotlight_diffuse( const float4 attenuation, const float4 lightprobe_diffuse, const float NdotL )
{
	return attenuation.xyz * NdotL * lightDiffuse.xyz + (lightprobe_diffuse.xyz * 2);
}


/// *
/// calculate combined color for lit, lit-sun or lit-sun-shadow variants
float3 pixel_calculate_combined_color_lit_sun_shadow( const float4 color_sample, const float3 sunlight_diffuse, const float3 sunlight_specular, const float4 lightprobe_diffuse, const float shadow_scalar )
{
	return color_sample.xyz * (lightprobe_diffuse.w * sunlight_diffuse * shadow_scalar + (lightprobe_diffuse.xyz * 2)) + sunlight_specular;
}


/// *
/// calculate combined color for lit-spot, lit-spot-shadow variants
float3 pixel_calculate_combined_color_lit_spot_shadow( const float4 color_sample, const float3 spotlight_diffuse, const float3 spotlight_specular )
{
	return color_sample.xyz * spotlight_diffuse + spotlight_specular;
}

/// *
/// add fog to combined color, out as final rgb color
float3 pixel_add_fog_to_final_color( const float3 combined_color, const float fogvar )
{
	return fogvar * (combined_color + -fogColor.xyz) + fogColor.xyz;
}


/// *
/// calculate spotlight settings
float pixel_calculate_spotlight_settings( const float3 light_direction )
{
	float	light_settings = saturate(dot(light_direction, lightSpotDir.xyz) * lightSpotFactors.x + lightSpotFactors.y);
	
	return	(-light_settings >= 0) ? 0 : pow(light_settings, lightSpotFactors.z);
}


// ------------------ SAMPLE -------------------------

/// *
/// probe lighting for models
float4 pixel_sample_probelighting( const float3 normalized_world_normal, const float3 i_light_coordinates)
{
	float3 absNormal		= abs(normalized_world_normal);
	float  longestSide		= max(absNormal.x, max(absNormal.y, absNormal.z));
	float3 lightingCoords	= normalized_world_normal * lightingLookupScale.xyz / longestSide + i_light_coordinates;
	
	return tex3D(modelLightingSampler, lightingCoords);
}


/// *
/// sample reflections
float4 pixel_sample_reflection( const float3 reflection_probe_coordinates, const float cosine_sample)
{
	float4	reflection_sample  = texCUBElod(reflectionProbeSampler, float4(reflection_probe_coordinates, cosine_sample * -8 + 6));
			reflection_sample *= reflection_sample.w;
	
	return	reflection_sample;
}


/// *
/// sample sun shadows
float pixel_sample_sunshadow( const float4 i_world_shadows, const float lightprobe_diffuse_alpha)
{
	float shadow_scalar = 1;
	
	if (i_world_shadows.w <= 1.0)
	{
		float4 shadow_sample;
	
		// pre calculate the Quotient as the shader compiler fails to get us the result we need
		//shadow_sample.x = tex2Dlod(shadowmapSamplerSun, float4(i_world_shadows.xy + float2( 1/4096,  1/4096), i_world_shadows.z, 0)).x;
		//shadow_sample.y = tex2Dlod(shadowmapSamplerSun, float4(i_world_shadows.xy + float2(-1/4096, -1/4096), i_world_shadows.z, 0)).x;
		//shadow_sample.z = tex2Dlod(shadowmapSamplerSun, float4(i_world_shadows.xy + float2( 1/2048, -1/8192), i_world_shadows.z, 0)).x;
		//shadow_sample.w = tex2Dlod(shadowmapSamplerSun, float4(i_world_shadows.xy + float2(-1/2048,  1/8192), i_world_shadows.z, 0)).x;
	
		shadow_sample.x = tex2Dlod(shadowmapSamplerSun, float4(i_world_shadows.xy + float2(0.0002441406, 0.0002441406), i_world_shadows.z, 0)).x;
		shadow_sample.y = tex2Dlod(shadowmapSamplerSun, float4(i_world_shadows.xy + float2(-0.0002441406, -0.0002441406), i_world_shadows.z, 0)).x;
		shadow_sample.z = tex2Dlod(shadowmapSamplerSun, float4(i_world_shadows.xy + float2(0.0004882813, -0.0001220703), i_world_shadows.z, 0)).x;
		shadow_sample.w = tex2Dlod(shadowmapSamplerSun, float4(i_world_shadows.xy + float2(-0.0004882813, 0.0001220703), i_world_shadows.z, 0)).x;
	
	#ifndef TECHSET_HSM
		// if not a hsm shader
		shadow_sample += float4(-i_world_shadows.z, -i_world_shadows.z, -i_world_shadows.z, -i_world_shadows.z);
		shadow_sample  = (shadow_sample >= 0) ? 1 : 0;
	#endif
        
		shadow_scalar = dot(shadow_sample, 0.25);
		 
		if (i_world_shadows.w > 0.75)
		{
			float4 shadow_sample_sp;
			float2 shadow_sp_coords = i_world_shadows.xy * shadowmapSwitchPartition.ww + shadowmapSwitchPartition.xy;
		 
			//hsm adds 1 to i_world_shadows.z
			shadow_sample_sp.x = tex2Dlod(shadowmapSamplerSun, float4(shadow_sp_coords + float2(0.0002441406, 0.0002441406), 1 + i_world_shadows.z, 0)).x;
			shadow_sample_sp.y = tex2Dlod(shadowmapSamplerSun, float4(shadow_sp_coords + float2(-0.0002441406, -0.0002441406), 1 + i_world_shadows.z, 0)).x;
			shadow_sample_sp.z = tex2Dlod(shadowmapSamplerSun, float4(shadow_sp_coords + float2(0.0004882813, -0.0001220703), 1 + i_world_shadows.z, 0)).x;
			shadow_sample_sp.w = tex2Dlod(shadowmapSamplerSun, float4(shadow_sp_coords + float2(-0.0004882813, 0.0001220703), 1 + i_world_shadows.z, 0)).x;
		 
	#ifndef TECHSET_HSM
            // hsm does not do this
			shadow_sample_sp += float4(-i_world_shadows.z, -i_world_shadows.z, -i_world_shadows.z, -i_world_shadows.z);
			shadow_sample_sp  = (shadow_sample_sp >= 0) ? 1 : 0;
	#endif
			shadow_scalar = lerp(shadow_scalar, dot(shadow_sample_sp, 0.25), i_world_shadows.w * 4 + -3);
		}
	}
	else
	{
		float2	shadow_sp_coords = i_world_shadows.xy * shadowmapSwitchPartition.ww + shadowmapSwitchPartition.xy;
		float	shadow_max = max(abs(shadow_sp_coords.x + -0.5) * shadowmapScale.x, abs(shadow_sp_coords.y + -0.75) * shadowmapScale.y);
	
		if (shadow_max >= 8)
		{
			shadow_scalar = lightprobe_diffuse_alpha;
		}
		else
		{
			float4 shadow_sample_sp;
	    
			//hsm adds 1 to i_world_shadows.z
			shadow_sample_sp.x = tex2Dlod(shadowmapSamplerSun, float4(shadow_sp_coords + float2(0.0002441406, 0.0002441406), 1 + i_world_shadows.z, 0)).x;
			shadow_sample_sp.y = tex2Dlod(shadowmapSamplerSun, float4(shadow_sp_coords + float2(-0.0002441406, -0.0002441406), 1 + i_world_shadows.z, 0)).x;
			shadow_sample_sp.z = tex2Dlod(shadowmapSamplerSun, float4(shadow_sp_coords + float2(0.0004882813, -0.0001220703), 1 + i_world_shadows.z, 0)).x;
			shadow_sample_sp.w = tex2Dlod(shadowmapSamplerSun, float4(shadow_sp_coords + float2(-0.0004882813, 0.0001220703), 1 + i_world_shadows.z, 0)).x;
	
	#ifndef TECHSET_HSM
            // hsm does not do this
			shadow_sample_sp += float4(-i_world_shadows.z, -i_world_shadows.z, -i_world_shadows.z, -i_world_shadows.z);
			shadow_sample_sp  = (shadow_sample_sp >= 0) ? 1 : 0;
	#endif            
            
			shadow_scalar = lerp(dot(shadow_sample_sp, 0.25), lightprobe_diffuse_alpha, shadow_max + -7);
		}
	}
    
	return shadow_scalar;
}


/// *
/// sample spot shadows
float pixel_sample_spotshadow(const float4 i_world_shadows, const float lightprobe_diffuse_alpha)
{
	float4	spotshadow_sample;
	
			spotshadow_sample.x = tex2Dproj(shadowmapSamplerSpot, float4(i_world_shadows.w * spotShadowmapPixelAdjust.xy + i_world_shadows.xy, i_world_shadows.zw)).x;
			spotshadow_sample.y = tex2Dproj(shadowmapSamplerSpot, float4(i_world_shadows.w * -spotShadowmapPixelAdjust.xy + i_world_shadows.xy, i_world_shadows.zw)).x;
			spotshadow_sample.z = tex2Dproj(shadowmapSamplerSpot, float4(i_world_shadows.w * spotShadowmapPixelAdjust.zw + i_world_shadows.xy, i_world_shadows.zw)).x;
			spotshadow_sample.w = tex2Dproj(shadowmapSamplerSpot, float4(i_world_shadows.w * -spotShadowmapPixelAdjust.zw + i_world_shadows.xy, i_world_shadows.zw)).x;
	    
	return	lerp(lightprobe_diffuse_alpha, dot(spotshadow_sample, 0.25), lightSpotFactors.w);
}