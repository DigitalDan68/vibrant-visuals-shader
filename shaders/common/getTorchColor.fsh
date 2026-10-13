vec3 getTorchColor(float torchLight, vec3 ambient, vec3 feetPos, vec3 surfaceNormal) {
   // Use native block-light intensity, including LambDynamicLights updates.
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
   return max(0.0,1.0-luma(ambient))*strength*localColor;
}
// Untextured geometry and particles have no reliable surface normal.
vec3 getTorchColor(float torchLight, vec3 ambient, vec3 feetPos) {
   return getTorchColor(torchLight,ambient,feetPos,vec3(0.0));
}
