#ifndef VV_BIOME_ATMOSPHERE
#define VV_BIOME_ATMOSPHERE
uniform float vvPaleGarden;
uniform float vvBiomeDesert, vvBiomeMesa, vvBiomeSwamp, vvBiomeJungle, vvBiomeSnow;
vec3 vvPaletteBrightness(vec3 tint,float brightness) {
   return tint*(brightness/max(dot(tint,vec3(0.2126,0.7152,0.0722)),0.00001));
}
vec3 vvBiomeAtmosphereColor(vec3 base,float skyWeight) {
#ifdef BIOME_ATMOSPHERE
#ifdef OVERWORLD
   float strength=clamp(BIOME_ATMOSPHERE_STRENGTH,0.0,1.0);
   float brightness=dot(max(base,vec3(0.0)),vec3(0.2126,0.7152,0.0722));
   float desert=clamp(vvBiomeDesert,0.0,1.0), mesa=clamp(vvBiomeMesa,0.0,1.0);
   float swamp=clamp(vvBiomeSwamp,0.0,1.0), jungle=clamp(vvBiomeJungle,0.0,1.0);
   float snow=clamp(vvBiomeSnow,0.0,1.0), pale=clamp(vvPaleGarden,0.0,1.0);
   float total=desert+mesa+swamp+jungle+snow+pale;
   float ordinary=max(1.0-total,0.0);
   // Build complete endpoint palettes, then interpolate them in one weighted sum.
   // No sequential overlays or normalization of a partially mixed color.
   vec3 desertTint=mix(vec3(1.0,0.86,0.62),vec3(1.0,0.82,0.58),skyWeight);
   vec3 desertColor=mix(base,vvPaletteBrightness(desertTint,brightness),clamp(strength*1.45,0.0,1.0));
   vec3 mesaColor=mix(base,vvPaletteBrightness(mix(vec3(1.0,0.72,0.50),vec3(1.0,0.66,0.45),skyWeight),brightness),clamp(strength*1.2,0.0,1.0));
   vec3 swampColor=mix(base,vvPaletteBrightness(mix(vec3(0.20,0.36,0.16),vec3(0.16,0.32,0.12),skyWeight),brightness*0.65),clamp(strength*1.45,0.0,1.0));
   vec3 jungleTint=mix(vec3(0.65,1.0,0.84),vec3(0.58,0.94,0.83),skyWeight);
   vec3 jungleColor=mix(base,vvPaletteBrightness(jungleTint,brightness),clamp(strength*1.15,0.0,1.0));
   vec3 snowColor=mix(base,vvPaletteBrightness(base*vec3(0.91,1.01,1.14),brightness),strength);
   vec3 paleColor=mix(base,vec3(brightness*0.78),strength);
   return (base*ordinary+desertColor*desert+mesaColor*mesa+swampColor*swamp+jungleColor*jungle+snowColor*snow+paleColor*pale)/max(ordinary+total,0.00001);
#else
   return base;
#endif
#else
   return base;
#endif
}
#endif