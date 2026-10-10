#ifdef COLORED_BLOCK_LIGHTING
#ifndef ENABLE_SHADOWS
// Iris schedules source collection only if an active program consumes a
// shadow target. Keep that dependency even when visible shadows are disabled.
uniform sampler2D shadowtex0;
#endif
#include "/common/transformations.glsl"
#include "/common/block_light_volume.glsl"
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
   // Shader-only emitters have no native lightmap value to cap against.
   irradiance+=shaderOnlyRadiance*COLORED_LIGHT_STRENGTH;
   #if HAND_DYNAMIC_LIGHTING >= 0
      // Held-item dynamic light remains separate from static world lighting.
      float heldStrength=rescale(float(heldBlockLightValue)-SQRT_2*length(feetPos),0.0,15.0);
      irradiance=max(irradiance,pow(TORCH_INNER_COLOR*heldStrength,vec3(2.2)));
   #endif
   return pow(max(irradiance,vec3(0.0)),vec3(1.0/2.2));
   }
#endif
   // Outside the detailed grid use the same native light path as other profiles.
   float strength = rescale(torchLight, TORCH_UV_SCALE.x, TORCH_UV_SCALE.y);

   #if HAND_DYNAMIC_LIGHTING >= 0

      strength = max(strength, rescale(float(heldBlockLightValue) - SQRT_2 * length(feetPos), 0.0, 15.0));

   #endif

   strength = mix(strength*strength, smoothe(strength), screenBrightness);
   strength = mix(strength*strength, strength, max(1.0 - screenBrightness, eyeBrightnessSmooth.y/240.0));

   vec3 localColor = mix(
      mix(TORCH_OUTER_COLOR, TORCH_MIDDLE_COLOR, strength),
      TORCH_INNER_COLOR,
      slopeTo1(strength, 8.0)
   );
   return max(0.0,1.0-luma(ambient))*strength*localColor;
}
// Untextured geometry and particles have no reliable surface normal.
vec3 getTorchColor(float torchLight, vec3 ambient, vec3 feetPos) {
   return getTorchColor(torchLight,ambient,feetPos,vec3(0.0));
}
