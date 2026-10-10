uniform float fogEnd, fogStart;
#if defined THE_NETHER || defined THE_END || defined THE_SIFT
uniform float blindness, darknessFactor;
#endif
uniform float near;
#ifndef BLOCK_FAR_DECLARED
uniform float far;
#define BLOCK_FAR_DECLARED
#endif
#ifdef DISTANT_HORIZONS
   uniform int dhRenderDistance;
#endif

float calcFogMix(vec3 feetPos, float fogStartMult, float rangeFar) {
   float len = length(feetPos);
   float cylinderLen = max(length(feetPos.xz), abs(feetPos.y));
   float density = FOG_DENSITY;
   #if COLOR_GRADING == 1 && defined HEIGHT_FOG && defined OVERWORLD && !defined GBUFFERS_SKYBASIC
      // Midpoint integration of altitude density, shared by vanilla and DH.
      float altitude = cameraPosition.y + 0.5 * feetPos.y;
      density *= clamp(exp(-(altitude - FOG_HEIGHT) / 48.0), 0.25, 1.5);
   #endif
   float start = fogStartMult * (far - clamp(0.1 * far, 4.0, 64.0));
   // Artistic fog uses the normal view distance, independent of Iris's
   // environmental fog uniforms and DH's much larger visibility range.
   if (rangeFar > far) {
      float atmosphere = min(0.97, 1.0 - exp(-0.8 * density * max(0.0, len - start) / max(far, 1.0)));
      float horizon = rescale(cylinderLen, 0.9 * rangeFar, rangeFar);
      return max(atmosphere, horizon);
   }
   float distanceFog = rescale(cylinderLen, start, max(start + 1.0, rangeFar));
   float atmosphere = 1.0 - pow(max(1.0 - distanceFog, 0.0), density);
   return atmosphere;
}

float getFogMix(vec3 feetPos) {
#ifdef GBUFFERS_CLOUDS
   // Clouds remain in air even when the camera is submerged. Preserve their
   // atmospheric distance fade instead of suppressing it for water fog.
   if (isEyeInWater == 1) {
#ifdef ENABLE_FOG
      float cloudFar = far;
#ifdef DISTANT_HORIZONS
      cloudFar = max(far,float(dhRenderDistance));
#endif
      return calcFogMix(feetPos,0.65,cloudFar);
#else
      return 0.0;
#endif
   }
#endif
   #ifdef WATER_VOLUMETRICS
      // Water scattering is evaluated once in final, using scene depth.
      if (isEyeInWater == 1 && WATER_FOG_DENSITY > 0.0) return 0.0;
   #endif
   float fogFar = far;
   #ifdef DISTANT_HORIZONS
      if (fogEnd >= far && isEyeInWater == 0) fogFar = max(far, float(dhRenderDistance));
   #endif
   #if defined VOXY && !defined GBUFFERS_SKYBASIC && !defined GBUFFERS_CLOUDS
      float far = 48000.0;
      float near = 16.0;
      fogFar = far;
   #endif

   #ifndef ENABLE_FOG
      if (fogEnd >= far) {
         return 0.0;
      }
   #endif

   #if MC_VERSION >= 11700
      if (fogEnd < far) {
         // a fog effect (like blindness) is active
         #if defined THE_NETHER || defined THE_END || defined THE_SIFT
            // Normal dimension biome fog may also have an end below view distance.
            // Only bypass artistic controls for a real environmental effect.
            if (isEyeInWater > 0 || blindness > 0.0 || darknessFactor > 0.0)
               return rescale(length(feetPos), fogStart, max(fogStart + 0.001, fogEnd));
         #else
            return rescale(length(feetPos), fogStart, max(fogStart + 0.001, fogEnd));
         #endif
      }

      #if defined GBUFFERS_SKYBASIC
         return 0.0;
      #elif defined GBUFFERS_CLOUDS
         return clamp((length(feetPos) - far) * (near * 0.01), 0.0, 1.0);
      #else
         #if COLOR_GRADING == 1 && defined DIMENSION_VOLUMETRICS && VOLUMETRIC_SAMPLES > 0
            #if defined THE_END || defined THE_SIFT
               // Final ray marching supplies fog once, with scene-depth termination.
               // Environmental fog above still takes precedence.
               if (isEyeInWater == 0 && blindness <= 0.0 && darknessFactor <= 0.0 && DIMENSION_FOG_STRENGTH > 0.0)
                  return 0.0;
            #endif
         #endif
         #ifdef THE_SIFT
            #ifdef ENABLE_FOG
               float siftFog = 1.0 - exp(-max(length(feetPos)-16.0,0.0) * FOG_DENSITY / max(SIFT_FOG_DISTANCE*0.65,1.0));
               return min(siftFog,0.995);
            #else
               return 0.0;
            #endif
         #endif
         #ifdef THE_END
            #ifdef ENABLE_FOG
               float endFog = 1.0 - exp(-max(length(feetPos) - 24.0, 0.0)
                                 * FOG_DENSITY / max(END_FOG_DISTANCE * 0.6, 1.0));
               return min(endFog, 0.995);
            #else
               return 0.0;
            #endif
         #endif
         #ifdef THE_NETHER
            // Nether atmosphere starts nearby, independent of view/DH distance.
            // Retain biome fog color and avoid discarding fully obscured geometry.
            #ifdef ENABLE_FOG
               float distanceFog = 1.0 - exp(-max(length(feetPos) - 8.0, 0.0)
                                    * FOG_DENSITY / max(NETHER_FOG_DISTANCE * 0.28, 1.0));
               return min(distanceFog, 0.995);
            #else
               return 0.0;
            #endif
         #endif
         #ifdef OVERWORLD
            float x = worldTime * NORMALIZE_TIME;

            x = clamp(25.0*(x < MIDNIGHT ? SUNSET - x : x - SUNRISE) + 0.3,
                     OVERWORLD_FOG_MIN,
                     OVERWORLD_FOG_MAX);

            x = min(x, 1.0 - rainStrength);
         #else
            float x = 1.0;
         #endif

         return calcFogMix(feetPos, x, fogFar);
      #endif
   #else
      gl_FogFragCoord = length(feetPos);

      return (isEyeInWater > 0) ? 1.0 - exp(-gl_FogFragCoord * gl_Fog.density)
                                : clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0);
   #endif
}
