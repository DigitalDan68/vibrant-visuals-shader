#ifdef COLORED_BLOCK_LIGHTING
#ifndef ENABLE_SHADOWS
// Iris schedules source collection only if an active program consumes a
// shadow target. Keep that dependency even when visible shadows are disabled.
uniform sampler2D shadowtex0;
#endif
#include "/common/transformations.glsl"
#include "/common/block_light_volume.glsl"
#endif
// LambDynamicLights lightmaps carry intensity only. Recover known held-source
// hues without adding light energy; both hands participate in the tint.
#ifdef LAMB_DYNAMIC_LIGHTS
uniform int heldItemId,heldItemId2;
float heldSourceLevel(int id) {
 if(id==10528 || id==42001) return 10.0;
 if(id==10604) return 7.0;
 if(id==43215) return 5.0;
 if(id==42013 || id==42015) return 8.0;
 if(id==43001 || id==43002) return 6.0;
 if(id==10496 || id==10984 || id==10652 || id==10656 ||
    (id>=42002 && id<=42006) || (id>=42008 && id<=42012) || id==42014 ||
    (id>=43111 && id<=43113)) return 15.0;
 return 0.0;
}
vec3 heldSourceHue(int id) {
 if(id==10528 || id==10656 || id==42001) return vec3(0.12,0.65,1.0);
 if(id==10604 || id==42013 || id==43215) return vec3(1.0,0.025,0.01);
 if(id==10984 || id==42014 || (id>=43111 && id<=43113)) return vec3(0.2,1.0,0.55);
 if(id==42002 || id==42006 || id==42008) return vec3(0.45,0.85,1.0);
 if(id==42010 || id==43002) return vec3(0.65,1.0,0.35);
 if(id==42011) return vec3(1.0,0.45,0.8);
 if(id==43001) return vec3(1.0,0.08,0.25);
 return TORCH_INNER_COLOR;
}
vec3 lambHeldTint(vec3 feetPos,float nativeLight,vec3 original) {
 float distanceToPlayer=length(feetPos-vec3(0.0,1.62,0.0));
 float falloff=max(0.0,1.0-distanceToPlayer/7.75);
 float a=heldSourceLevel(heldItemId)*falloff/15.0;
 float b=heldSourceLevel(heldItemId2)*falloff/15.0;
 float strongest=max(a,b);
 if(strongest<=0.0) return original;
 // Continuous energy weighting avoids switching between source winners.
 float influence=clamp((a+b)/max(nativeLight,0.000001),0.0,1.0);
 vec3 hue=(heldSourceHue(heldItemId)*a+heldSourceHue(heldItemId2)*b)/max(a+b,0.000001);
 return mix(original,hue,influence);
}
#endif
vec3 getTorchColor(float torchLight, vec3 ambient, vec3 feetPos, vec3 surfaceNormal) {
#ifdef COLORED_BLOCK_LIGHTING
   #ifndef ENABLE_SHADOWS
   // A valid depth target is nonnegative. This runtime guard keeps the
   // sampler active in the driver so Iris retains the voxel capture pass.
   if (texture2D(shadowtex0,vec2(0.5)).r < 0.0) return vec3(0.0);
#endif
   if (insideDetailedBlockLightGrid(feetPos)) {
   // Colored voxel lighting replaces native lighting only inside this field.
   float emissionBoost;
   vec3 shaderOnlyRadiance;
   vec3 irradiance=sampleColoredBlockLight(feetPos,surfaceNormal,emissionBoost,shaderOnlyRadiance)*COLORED_LIGHT_STRENGTH;
   // Bound static voxel light to the native lightmap brightness curve.
   // Keep its RGB hue, while matching the brightness/falloff of native light.
   float nativeStrength=rescale(torchLight,TORCH_UV_SCALE.x,TORCH_UV_SCALE.y);
   nativeStrength=mix(nativeStrength*nativeStrength,smoothe(nativeStrength),screenBrightness);
   nativeStrength=mix(nativeStrength*nativeStrength,nativeStrength,max(1.0-screenBrightness,eyeBrightnessSmooth.y/240.0));
   float nativeBrightness=max(0.0,1.0-luma(ambient))*nativeStrength;
   float peak=max(irradiance.r,max(irradiance.g,irradiance.b));
   float nativeLimit=pow(nativeBrightness,2.2)*COLORED_LIGHT_STRENGTH*emissionBoost;
   irradiance*=min(1.0,nativeLimit/max(peak,0.000001));
   #ifdef LAMB_DYNAMIC_LIGHTS
   // Blend source hues in linear space, then preserve the lightmap energy.
   // A held source must participate even where a placed source is brighter.
   float nativeEnergy=pow(nativeBrightness,2.2)*COLORED_LIGHT_STRENGTH;
   float staticPeak=max(irradiance.r,max(irradiance.g,irradiance.b));
   float heldFalloff=max(0.0,1.0-length(feetPos-vec3(0.0,1.62,0.0))/7.75);
   float heldA=heldSourceLevel(heldItemId)*heldFalloff/15.0;
   float heldB=heldSourceLevel(heldItemId2)*heldFalloff/15.0;
   // Never manufacture energy where the mod's lightmap supplies none.
   float nativeRaw=rescale(torchLight,TORCH_UV_SCALE.x,TORCH_UV_SCALE.y);
   heldA=min(heldA,max(nativeRaw,0.0));
   heldB=min(heldB,max(nativeRaw,0.0));
   vec3 hueA=pow(heldSourceHue(heldItemId),vec3(2.2));
   vec3 hueB=pow(heldSourceHue(heldItemId2),vec3(2.2));
   float energyA=pow(heldA,2.2)*COLORED_LIGHT_STRENGTH;
   float energyB=pow(heldB,2.2)*COLORED_LIGHT_STRENGTH;
   vec3 blended=irradiance+hueA/max(max(hueA.r,max(hueA.g,hueA.b)),0.000001)*energyA
      +hueB/max(max(hueB.r,max(hueB.g,hueB.b)),0.000001)*energyB;
   float unknownEnergy=max(0.0,nativeEnergy-max(staticPeak,max(energyA,energyB)));
   vec3 neutral=pow(TORCH_INNER_COLOR,vec3(2.2));
   blended+=neutral/max(max(neutral.r,max(neutral.g,neutral.b)),0.000001)*unknownEnergy;
   float blendPeak=max(blended.r,max(blended.g,blended.b));
   float targetEnergy=max(nativeEnergy,staticPeak);
   irradiance=blended*(targetEnergy/max(blendPeak,0.000001));
   #endif
   // Shader-only emitters have no native lightmap value to cap against.
   irradiance+=shaderOnlyRadiance*COLORED_LIGHT_STRENGTH;
   #if HAND_DYNAMIC_LIGHTING >= 0 && !defined LAMB_DYNAMIC_LIGHTS
      // Held-item dynamic light remains separate from static world lighting.
      float heldStrength=rescale(float(heldBlockLightValue)-SQRT_2*length(feetPos),0.0,15.0);
      irradiance=max(irradiance,pow(TORCH_INNER_COLOR*heldStrength,vec3(2.2)));
   #endif
   return pow(max(irradiance,vec3(0.0)),vec3(1.0/2.2));
   }
#endif
   // Outside the detailed grid use the same native light path as other profiles.
   float strength = rescale(torchLight, TORCH_UV_SCALE.x, TORCH_UV_SCALE.y);

   #if HAND_DYNAMIC_LIGHTING >= 0 && !defined LAMB_DYNAMIC_LIGHTS

      strength = max(strength, rescale(float(heldBlockLightValue) - SQRT_2 * length(feetPos), 0.0, 15.0));

   #endif

   strength = mix(strength*strength, smoothe(strength), screenBrightness);
   strength = mix(strength*strength, strength, max(1.0 - screenBrightness, eyeBrightnessSmooth.y/240.0));

   vec3 localColor = mix(
      mix(TORCH_OUTER_COLOR, TORCH_MIDDLE_COLOR, strength),
      TORCH_INNER_COLOR,
      slopeTo1(strength, 8.0)
   );
   #ifdef LAMB_DYNAMIC_LIGHTS
   localColor=lambHeldTint(feetPos,rescale(torchLight,TORCH_UV_SCALE.x,TORCH_UV_SCALE.y),localColor);
   #endif
   return max(0.0,1.0-luma(ambient))*strength*localColor;
}
// Untextured geometry and particles have no reliable surface normal.
vec3 getTorchColor(float torchLight, vec3 ambient, vec3 feetPos) {
   return getTorchColor(torchLight,ambient,feetPos,vec3(0.0));
}
