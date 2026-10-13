#ifndef VV_DRY_BIOME_FOG
#define VV_DRY_BIOME_FOG
#include "/common/biome_atmosphere.glsl"
uniform float vvDryBiomeDust;
uniform float vvRedSandBiome;
vec3 vvStormSandTint() {
   return mix(vec3(1.0,0.77,0.46),vec3(1.0,0.55,0.18),clamp(vvRedSandBiome,0.0,1.0));
}
vec3 vvDryBiomeFogColor(vec3 base) {
   base=vvBiomeAtmosphereColor(base,0.0);
#ifdef OVERWORLD
   float brightness = dot(max(base,vec3(0.0)),vec3(0.2126,0.7152,0.0722));
   vec3 tint = vvStormSandTint();
   vec3 sand = tint*(brightness/max(dot(tint,vec3(0.2126,0.7152,0.0722)),0.01));
   return mix(base,sand,clamp(vvDryBiomeDust,0.0,1.0)*0.85);
#else
   return base;
#endif
}
#endif