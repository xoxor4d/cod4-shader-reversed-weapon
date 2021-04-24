// custom development dir shader_vars file for visual studio (preprocessor defined in lib/shadertoolsconfig.json)
#ifdef EXCLUDE_SHADERVARS_ON_RELEASE
    #include <../shader_vars.h>
#endif

/// *
/// transform vertex to world-space
float4 transform_object_to_world( float4 i_position )
{
	return mul( i_position, worldMatrix );
}


/// *
/// transform vertex to to clip/camera-space
float4 transform_object_to_clip( float4 i_position )
{
	return mul( i_position, worldViewProjectionMatrix );
}


/// *
/// transform world-space vertex to clip/camera-space
float4 transform_world_to_clip( float4 i_world_position )
{
	return mul( i_world_position, viewProjectionMatrix );
}