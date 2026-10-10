#ifdef COLORED_BLOCK_LIGHTING
#include "/common/block_light_volume.glsl"
vec3 coloredBlockIrradiance(vec2 uv,vec3 receiver) {
 vec3 normal=normalize(screen2ndc(texture2D(colortex6,uv).xyz));
 return sampleColoredBlockLight(view2feet(receiver),normal)*COLORED_LIGHT_STRENGTH;
}
#endif
