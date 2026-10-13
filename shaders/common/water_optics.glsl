#ifndef MINIATURE_WATER_OPTICS
#define MINIATURE_WATER_OPTICS
// RGB approximation inspired by the documented Bedrock concentration controls.
// These are our coefficients, not unpublished Bedrock renderer coefficients.
vec3 waterAbsorptionCoefficients(vec3 biomeTint) {
   vec3 absorption=vec3(0.110,0.036,0.030);
   absorption+=clamp(WATER_CDOM,0.0,15.0)*vec3(0.002,0.012,0.050);
   absorption+=clamp(WATER_CHLOROPHYLL,0.0,10.0)*vec3(0.040,0.004,0.032);
   absorption+=clamp(WATER_SEDIMENT,0.0,300.0)*vec3(0.001,0.003,0.006);
   vec3 dye=pow(clamp(biomeTint,vec3(0.0),vec3(1.0)),vec3(2.2));
   float peak=max(dye.r,max(dye.g,dye.b));
   dye=peak>0.00001 ? dye/peak : vec3(1.0);
   absorption+=-log(max(dye,vec3(0.025)))*0.012*WATER_BIOME_COLOR;
   return absorption*max(WATER_ABSORPTION/0.08,0.0);
}
vec3 waterScatteringCoefficients() {
   return vec3(0.002,0.006,0.010)
         +clamp(WATER_CHLOROPHYLL,0.0,10.0)*vec3(0.001,0.006,0.002)
         +clamp(WATER_SEDIMENT,0.0,300.0)*vec3(0.003,0.002,0.0015);
}
vec3 waterTintExtinction(vec3 biomeTint) {
   return waterAbsorptionCoefficients(biomeTint)+waterScatteringCoefficients();
}
vec3 waterStyledTint(vec3 biomeTint) {
   vec3 color=waterScatteringCoefficients()/max(waterTintExtinction(biomeTint),vec3(0.00001));
   color/=max(max(color.r,max(color.g,color.b)),0.00001);
   return clamp(mix(color,biomeTint,clamp(WATER_BIOME_COLOR,0.0,1.0)),vec3(0.0),vec3(1.0));
}
#endif
