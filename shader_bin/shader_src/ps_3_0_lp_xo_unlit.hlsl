// https://xoxor4d.github.io/
// stock-ps "vertcol_shaded_fog.hlsl"
// UNLIT

#define PC
#define IS_VERTEX_SHADER 0
#define IS_PIXEL_SHADER 1

#define FOG         // shader uses fog

#include <shader_vars.h>
#include <lib/pixel_setup_dtex.hlsl>

struct PS_IN
{
    float4 color    : COLOR;
    
#if defined(FOG)
    float3 texcoord : TEXCOORD;
#else
    float2 texcoord : TEXCOORD;
#endif
};

float4 ps_main(PS_IN i) : COLOR
{
    // shader output
    float4 color;
    
    // color sample
	float4  color_sample    = tex2D(colorMapSampler, i.texcoord.xy);
    float4  material_col    = i.color * -color_sample + materialColor;
    
    float4  color_combined;
	        color_combined.rgb = materialColor.a * material_col + (color_sample * i.color);
            color_combined.a   = (color_sample.a * i.color.a);

    #ifdef FOG
        color.rgb = pixel_add_fog_to_final_color(color_combined.rgb, i.texcoord.z);
    #else // IF NOT FOG
        color.rgb = color_combined;
    #endif

    #ifdef SHADER_DEBUG
        color.r += 0.4f;
        color.b += 0.2f;
    #endif
    
	color.a = color_combined.a;

	return color;
}
