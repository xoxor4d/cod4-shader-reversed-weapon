// https://xoxor4d.github.io/
// stock-vs "lp_hsm_sun_s_tc0_dtex_sm3.hlsl"
// LIT SUN SHADOW

#define PC
#define IS_VERTEX_SHADER 1
#define IS_PIXEL_SHADER 0

#define TECH_SHADOW // shader uses shadowmapping
#define FOG         // shader uses fog

#include <shader_vars.h>
#include <lib/vertex_setup_dtex.hlsl>
#include <lib/vertex_transform.hlsl>

struct VS_IN
{
    float4 position : POSITION;
    float4 color : COLOR;
    float4 texcoord : TEXCOORD;
    float4 normal : NORMAL;
};

struct VS_OUT
{
    float4 position : POSITION;
    float4 color : COLOR;
    float2 texcoord : TEXCOORD;
    float4 world_normal : TEXCOORD1;
#ifdef TECH_SHADOW
    float4 world_shadows : TEXCOORD4;
#endif
    float3 world_pos : TEXCOORD5;
    float3 light_coords : TEXCOORD6;
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
    
    // unpack and setup uv coordinates
    o.texcoord = setup_uv_dtex(i.texcoord);
    
    // unpack and setup normals
    o.world_normal  = setup_normal_dtex(i.normal);
#ifdef FOG
    // calculate fogvar
    o.world_normal.w = setup_fog_dtex(world_pos);
#endif
    
#ifdef TECH_SHADOW
    // setup shadow lookup
    o.world_shadows = setup_shadow_lookup(world_pos);
#endif
    
    // worldpos and lighting coordinates passthrough
    o.world_pos = world_pos;
    o.light_coords = baseLightingCoords;

    return o;
}