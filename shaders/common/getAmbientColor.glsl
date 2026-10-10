vec4 getAmbientColor(float skyLight, float sunHeight) {
   vec4 ambient = texture2D(lightmap, vec2(AMBIENT_UV.s, skyLight));

   #ifdef OVERWORLD
      float x = ambient.g;
      float ambientBoost = (((0.8494 * x + 0.9687) * x - 5.238) * x + 3.711) * x - 0.2864;

      ambientBoost = max(0.0, ambientBoost);

      ambient.rgb = mix(
         min(vec3(1.0), ambient.rgb + vec3(ambientBoost) * clamp(0.2*sunHeight, 0.0, 1.0)),
         ambient.rgb,
         screenBrightness
      );
   #endif

   #if COLOR_GRADING == 1 && defined OVERWORLD
      // Keep sunset shadows readable without turning caves into daylight.
      float outdoor = smoothstep(0.35, 0.9, skyLight);
      ambient.rgb = max(ambient.rgb, vec3(0.16, 0.19, 0.25) * outdoor);
   #endif
   #ifdef THE_NETHER
      // Preserve biome hue in the dimension's diffuse ambient fill.
      float fogPeak = max(fogColor.r, max(fogColor.g, fogColor.b));
      vec3 biomeTint = fogColor / max(fogPeak, 0.05);
      vec3 ambientFill = mix(vec3(0.18), biomeTint * 0.26, 0.45) * NETHER_AMBIENCE;
      ambient.rgb = max(ambient.rgb, ambientFill);
   #endif
   #ifdef THE_END
      ambient.rgb = max(ambient.rgb, vec3(0.22, 0.18, 0.3) * END_AMBIENCE);
   #endif
   #ifdef THE_SIFT
      // Separate the cool ambient fill from warm local emitters.
      float outdoor = smoothstep(0.2,0.85,skyLight);
      ambient.rgb = mix(ambient.rgb,vec3(luma(ambient.rgb)),0.85);
      ambient.rgb *= vec3(1.04,1.0,0.98);
      ambient.rgb = max(ambient.rgb, mix(vec3(0.32,0.34,0.32),vec3(0.065,0.09,0.16),1.0-smoothstep(-5.0,5.0,sunHeight)) * SIFT_AMBIENCE * mix(0.25,1.0,outdoor));
   #endif
   #ifdef OVERWORLD
      float cave = 1.0-smoothstep(0.15,0.65,skyLight);
      ambient.rgb = max(ambient.rgb,vec3(CAVE_AMBIENT)*cave);
   #endif
   // Lightmap alpha is lighting data, never surface opacity.
   ambient.a = 1.0;
   return ambient;
}