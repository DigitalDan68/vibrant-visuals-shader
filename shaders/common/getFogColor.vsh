#ifndef THE_NETHER
uniform vec3 fogColor;
#endif
uniform vec3 skyColor;

vec3 getFogColor(float fogMix, vec3 feetPos) {
   #ifdef OVERWORLD
      vec3 atmosphere = fogColor;
      #if COLOR_GRADING == 1
         // Reduce the uniform orange veil at sunset while retaining its warmth.
         atmosphere = mix(fogColor, skyColor, 0.35);
      #endif
      return mix(atmosphere, skyColor, fogMix * clamp(0.006*feetPos.y, 0.0, 1.0));
   #elif defined THE_SIFT
      return mix(vec3(0.64,0.76,0.7),vec3(0.035,0.065,0.15),siftNightWeight(float(worldTime)));
   #elif defined THE_END
      // The End's near-black vanilla fog cannot express atmospheric depth.
      return mix(fogColor, vec3(0.19, 0.13, 0.28), 0.7);
   #else
      return fogColor;
   #endif
}