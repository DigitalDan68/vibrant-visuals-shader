#ifndef VV_BLOOM_SAMPLING
#define VV_BLOOM_SAMPLING
// Iris samples the RGBA16F bloom target with linear filtering and clamp-to-edge.
vec3 vvSmoothBloom(vec2 uv) {
   return texture2D(colortex4,uv).rgb;
}
#endif
