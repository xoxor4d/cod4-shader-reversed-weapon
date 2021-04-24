// https://xoxor4d.github.io/
// stock-vs "vertcol_simple_fog_dtex.hlsl"
// UNLIT

#define PC
#define IS_VERTEX_SHADER 1
#define IS_PIXEL_SHADER 0

#define FOG         // shader uses fog

#include <shader_vars.h>
#include <lib/vertex_setup_dtex.hlsl>
#include <lib/vertex_transform.hlsl>

struct VS_IN
{
    float4 position : POSITION;
    float4 color    : COLOR;
    float4 texcoord : TEXCOORD;
};

struct VS_OUT
{
    float4 position : POSITION;
    float4 color    : COLOR;
    
#if defined(FOG)
    float3 texcoord : TEXCOORD;
#else
    float2 texcoord : TEXCOORD;
#endif
};

VS_OUT vs_main(VS_IN i)
{
    VS_OUT o;
    
    // transform vertices to world-space
    float4 world_pos = transform_object_to_world(float4(i.position.xyz, 1.0f));

    // transform vertices to clip
    o.position = transform_world_to_clip(world_pos);
    
    // color passthrough
    o.color = i.color;
    
    o.texcoord.xy = setup_uv_dtex(i.texcoord);
    
#if defined(FOG)
    o.texcoord.z  = setup_fog_dtex(world_pos);
#endif

    return o;
}