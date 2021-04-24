// custom development dir shader_vars file for visual studio (preprocessor defined in lib/shadertoolsconfig.json)
#ifdef EXCLUDE_SHADERVARS_ON_RELEASE
    #include <../shader_vars.h>
#endif

/// *
/// unpack fixed integer uv coordinates
float2 setup_uv_dtex( const float4 i_texcoord )
{
	// fixed-point integer texcoords to float :: int / 2^10 does the same as int >> 10
    float4 fixed_coords = float4(i_texcoord.zx / exp2(10), i_texcoord.zx / exp2(15))
                        + float4(i_texcoord.wy / exp2(2),  i_texcoord.wy / exp2(7));

    float4 fractional_parts = frac(fixed_coords);
    
    // calculate texcoords
    float4  setup;
            setup.xy = fractional_parts.xy * -0.03125 + fractional_parts.zw;
            setup.zw = fixed_coords.zw + -fractional_parts.zw;

            setup    = setup * float4(32, 32, -2, -2) + float4(-15, -15, 1, 1);
            setup.zw = setup.zw * fractional_parts.xy + setup.zw;

    return  setup.zw * exp2(setup.xy);
}


/// *
/// unpack packed vertex normals
float4 setup_normal_dtex( const float4 i_normal )
{
    // unpack normals
    float3  unpacked_normal  =  i_normal.xyz * (1.0f / 127.0f) + float3(-1.0f, -1.0f, -1.0f);
            unpacked_normal *= (i_normal.w   * (1.0f / 255.0f) + (1.0f / 1.328f));

    // return without fog (.w = 1.0)
    float4  world_normal    = mul(unpacked_normal, worldMatrix);
            world_normal.w  = 1.0f;
    
    return  world_normal;
}


/// *
/// calculate fog using world-transformed vertices
float setup_fog_dtex( const float4 i_world_position )
{
    float   fog_var  = sqrt(dot(i_world_position.xyz, i_world_position.xyz)) * fogConsts.z + fogConsts.w;
            fog_var *= 1.442695f;

    return  exp2(saturate(fog_var));
}


/// *
/// transform world-space vertex to clip/camera-space
float4 setup_shadow_lookup( float4 i_world_position )
{
	return mul(i_world_position, shadowLookupMatrix);
}