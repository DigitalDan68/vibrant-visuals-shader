#define SSR_BINARY_Z_CUTOFF 16.0

#ifdef DISTANT_HORIZONS
   uniform sampler2D dhDepthTex0;
   uniform sampler2D dhDepthTex1;
   uniform mat4 dhProjectionInverse;
#endif

float reflectionSceneZ(vec2 uv, bool opaqueOnly) {
   float sceneDepth = opaqueOnly ? texture2D(depthtex1, uv).x : texture2D(depthtex0, uv).x;
   #ifdef DISTANT_HORIZONS
      if (sceneDepth >= 1.0) {
         float dhDepth = opaqueOnly ? texture2D(dhDepthTex1, uv).x : texture2D(dhDepthTex0, uv).x;
         if (dhDepth < 1.0) {
            vec4 pos = dhProjectionInverse * vec4(screen2ndc(vec3(uv, dhDepth)), 1.0);
            return pos.z / pos.w;
         }
         return -1.0e20; // Sky is not a reflection hit.
      }
   #endif
   if (sceneDepth >= 1.0) return -1.0e20; // Never treat sky depth as opaque terrain.
   return screen2view(uv, sceneDepth).z;
}

float getReflectionVignette(vec2 uv) {
   uv.y = min(uv.y, 1.0 - uv.y);
   uv.x *= 1.0 - uv.x;
   uv.y *= uv.y;

   return 1.0 - pow(1.0 - uv.x, 50.0*uv.y);
}

vec4 getReflectionColor(float depth, vec3 normal, vec3 viewPos, bool opaqueOnly) {
   vec3 V = normalize(viewPos);
   vec3 R = normalize(reflect(V, normal));

   if (R.z >= -0.005) return vec4(0.0);

   float grazingEpsilon = rescale(1.0 - abs(dot(R, normal)), 0.95, 1.0);
   float invR = 1.0 / max(abs(R.z), 0.005);
   float directionConfidence = smoothstep(0.005, 0.15, -R.z);
   float invFar = 1.0 / (2.0*far);
   float lengthR = 0.15;
   vec3 oldPos = viewPos;
   int reflectionSamples = SSR_MAX_STEPS;
   int binarySamples = SSR_BINARY_STEPS;

   for (int i = 0; i < reflectionSamples; i++) {
      vec3 curPos = viewPos + R * lengthR;
      vec2 curUV  = view2screen(curPos).st;

      if (curUV.s < 0.0 || curUV.s > 1.0 || curUV.t < 0.0 || curUV.t > 1.0)
         break;

      float sceneZ = reflectionSceneZ(curUV, opaqueOnly);
      float distanceEpsilon = clamp(abs(sceneZ) * invFar, 0.0, 1.0);
      float epsilon = 1.0 + 0.1*max(distanceEpsilon, grazingEpsilon);
      float diffZ = curPos.z - sceneZ;

      if (diffZ < 0.0) {
         vec3 a = oldPos;
         vec3 b = curPos;

         {
            for (int j = 0; j < binarySamples; j++) {
               curPos = (a + b) * 0.5;
               curUV = view2screen(curPos).st;
               sceneZ = reflectionSceneZ(curUV, opaqueOnly);

               if (-curPos.z < -sceneZ) { a = curPos; }
               else                     { b = curPos; }
            }
         }

         // Reject depth discontinuities instead of sampling through a roof/wall.
         // A binary search across a silhouette is not necessarily a surface hit.
         float thickness = clamp(0.15 + 0.002 * abs(sceneZ), 0.15, 1.0);
         float error = abs(curPos.z - sceneZ);
         if (error > thickness*2.0 || length(curPos - viewPos) < 0.1)
            return vec4(0.0);
         bool hitIsBehind = length(curPos - viewPos) > 0.1;
         #ifndef DISTANT_HORIZONS
            if (!opaqueOnly) hitIsBehind = texture2D(depthtex0, curUV).x + 0.0001 > depth;
         #endif
         return !hitIsBehind
               ? vec4(0.0)
               : vec4(texture2D(colortex0, curUV).rgb,
                      getReflectionVignette(curUV) * directionConfidence
                      * (1.0 - smoothstep(thickness*0.15, thickness*2.0, error)));
      }

      oldPos = curPos;
      lengthR += max(SSR_STEP_SIZE * abs(diffZ) * invR, 1.0)*float(SSR_MAX_STEPS)/float(reflectionSamples);
   }

   return vec4(0.0);
}
