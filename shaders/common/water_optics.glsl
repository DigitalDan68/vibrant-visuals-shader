#ifndef MINIATURE_WATER_OPTICS
#define MINIATURE_WATER_OPTICS
// Preserve the biome hue in transmission as well as in scattered light.
// Darker tint channels absorb more; the dominant channel retains clear-water loss.
vec3 waterTintExtinction(vec3 biomeTint) {
   vec3 linearTint = pow(clamp(biomeTint,vec3(0.0),vec3(1.0)),vec3(2.2));
   float peak = max(linearTint.r,max(linearTint.g,linearTint.b));
   vec3 relativeTint = peak > 0.00001 ? linearTint/peak : vec3(1.0);
   return vec3(0.018)-0.018*log(max(relativeTint,vec3(0.025)));
}
#endif
