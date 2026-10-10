#include "/shader.h"

uniform float far;
#define BLOCK_FAR_DECLARED
uniform vec3 moonPosition;
uniform int moonPhase;
uniform int isEyeInWater;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex3;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex5;
#include "/common/labpbr.glsl"
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

#if HAND_DYNAMIC_LIGHTING >= 0 && !defined LAMB_DYNAMIC_LIGHTS
uniform usampler2D enchantedHeldSampler;
uniform int heldItemId;
uniform int heldItemId2;
#endif
varying vec2 texUV;

#include "/common/math.glsl"
#include "/common/transformations.glsl"
#include "/common/getReflectionColor.fsh"
#include "/common/vibrant.glsl"
#include "/common/entity_light_resolve.glsl"

vec3 waterEntryPosition(vec2 uv,float depth) {
   if (depth < 1.0) return screen2view(uv,depth);
#ifdef DISTANT_HORIZONS
   float lodDepth = texture2D(dhDepthTex0,uv).x;
   if (lodDepth < 1.0) {
      vec4 lod = dhProjectionInverse*vec4(screen2ndc(vec3(uv,lodDepth)),1.0);
      vec3 lodPosition = lod.xyz/lod.w;
      if (depth >= 1.0 || lodPosition.z > screen2view(uv,depth).z) return lodPosition;
   }
#endif
   return screen2view(uv,min(depth,0.999));
}


vec3 waterCelestialHighlight(vec3 surface,float nativeDepth) {
#ifdef OVERWORLD
         vec3 waterNormal = screen2ndc(texture2D(colortex6,texUV).xyz);
         vec3 N = normalize(eye2view(waterNormal));

         vec3 V = normalize(-surface);
         vec3 L = normalize(sunPosition);
         float daylight = smoothstep(0.0,0.12,normalize(view2eye(sunPosition)).y);
         float visible = vvSunVisibility(view2feet(surface)+cameraPosition);
#ifndef ENABLE_SHADOWS
         visible = clamp(float(eyeBrightnessSmooth.y)/240.0,0.0,1.0);
#endif
         visible *= smoothstep(0.25,0.9,clamp((texture2D(colortex2,texUV).a-0.6)/0.4,0.0,1.0));
         float reflectedSun = max(dot(reflect(-V,N),L),0.0);
         vec3 sunTint = mix(vec3(1.0,0.62,0.35),vec3(1.0,0.95,0.85),daylight);
         vec3 highlight = (vec3(3.0*pow(reflectedSun,1024.0)+0.15*pow(reflectedSun,128.0))+labSpecular(N,V,L,vec3(0.02),0.04)+0.12*labSpecular(N,V,L,vec3(0.02),0.12))*sunTint*daylight*visible
                        * WATER_SUN_GLINT*WATER_GLINT_BRIGHTNESS*clamp(float(WATER_MIN_GLINT)*0.1,0.0,1.0)*(1.0-rainStrength);
         vec3 moonL = normalize(moonPosition);
         float moonElevation = normalize(view2eye(moonPosition)).y;
         float moonVisibility = smoothstep(0.0,0.12,moonElevation)*(1.0-daylight);
         float phaseDistance = min(float(moonPhase),8.0-float(moonPhase));
         float lunarPhase = clamp(1.0-phaseDistance/4.0,0.0,1.0);
         float reflectedMoon = max(dot(reflect(-V,N),moonL),0.0);
         vec3 moonTint = MOON_COLOR/max(max(MOON_COLOR.r,max(MOON_COLOR.g,MOON_COLOR.b)),0.001);
         vec3 moonLobe = vec3(3.0*pow(reflectedMoon,1024.0)+0.15*pow(reflectedMoon,128.0))
                       +labSpecular(N,V,moonL,vec3(0.02),0.04)+0.12*labSpecular(N,V,moonL,vec3(0.02),0.12);
         highlight += moonLobe*moonTint*moonVisibility*lunarPhase*visible*WATER_MOON_GLINT
                    *WATER_GLINT_BRIGHTNESS*clamp(float(WATER_MIN_GLINT)*0.1,0.0,1.0)*(1.0-rainStrength);
         float textureMask = nativeDepth >= 1.0 ? 1.0 : clamp(texture2D(colortex7,texUV).y,0.0,1.0);
         return highlight*mix(1.0,textureMask,clamp(WATER_TEXTURE_OVERLAY,0.0,1.0));
#else
   return vec3(0.0);
#endif
}

void main() {
   vec4 color = texture2D(colortex0, texUV);
   vec4 reflectivityAndRoughness = texture2D(colortex7, texUV);
   float reflectivity = reflectivityAndRoughness.x;
   float roughness = reflectivityAndRoughness.y;
   vec3 waterReflection = vec3(0.0);
   float waterReflectionWeight = 0.0;

   bool hasRenderedSurface = reflectivityAndRoughness.a > 0.5;
   bool depthlessOverlay = hasRenderedSurface && texture2D(depthtex0,texUV).x >= 1.0;
   #ifdef DISTANT_HORIZONS
      depthlessOverlay = depthlessOverlay && texture2D(dhDepthTex0,texUV).x >= 1.0;
   #endif
   bool isDhWater = abs(reflectivityAndRoughness.z - 0.26) < 0.004;
   bool isWater = abs(reflectivityAndRoughness.z - 0.25) < 0.004 || isDhWater;
#ifdef DISTANT_HORIZONS
   if (isDhWater) {
      float nativeFront = texture2D(depthtex0,texUV).x;
      float lodFront = texture2D(dhDepthTex0,texUV).x;
      if (nativeFront < 1.0 && lodFront < 1.0) {
         vec4 lodPosition = dhProjectionInverse*vec4(screen2ndc(vec3(texUV,lodFront)),1.0);
         if (screen2view(texUV,nativeFront).z > lodPosition.z/lodPosition.w+0.05) {
            isWater = false;
            reflectivity = 0.0;
         }
      }
   }
#endif
   if (isWater) roughness = 0.0; // Water metadata Y holds animated texture detail.
   bool isGlass = abs(reflectivityAndRoughness.z - 0.6) < 0.01;
   if (isGlass) reflectivity = GLASS_REFLECTION_STRENGTH;
   bool isPbr = abs(reflectivityAndRoughness.z - 0.75) < 0.01;
   if (REFLECTIONS > 0 && reflectivity > MIN_REFLECTIVITY && (isPbr || isWater || isGlass || abs(reflectivityAndRoughness.z - 0.5) < 0.01)) {
      // the normal doesn't come premultiplied by the normal matrix to
      // avoid the modelview transformations when view bobbing is on
      // which causes severe artifacts when moving
      vec3 prenormal = screen2ndc(texture2D(colortex6, texUV).xyz);



      float depth  = texture2D(depthtex0, texUV).x;
      vec3 normal  = eye2view(prenormal);
      vec3 viewPos = isWater ? waterEntryPosition(texUV,depth) : screen2view(texUV, depth);
      vec3 feetPos = view2feet(viewPos);
      vec3 worldPos = feet2world(feetPos);
      float pixelDistance = min(1.0, length(feetPos)/16.0);
      float stepSize = stepify(mix(1.0/512.0, 1.0/64.0, pixelDistance), 1.0/512.0);

      // Keep the original stochastic reflections only on the legacy material path.
      if (!isPbr) normal += roughness * random3(stepify(worldPos, stepSize));
      normal = normalize(normal);

      vec4 reflectionColor = (isDhWater || (isWater && depth >= 1.0)) ? vec4(0.0) : getReflectionColor(depth, normal, viewPos, isWater || isGlass);
      #ifndef WATER_SCENE_REFLECTIONS
         if (isWater) reflectionColor = vec4(0.0);
      #endif
      #if defined SKY_REFLECTIONS && (defined OVERWORLD || defined THE_SIFT)
         if (isWater || isGlass) {
            vec3 reflectedDirection = view2eye(reflect(normalize(viewPos), normal));
            vec3 skyReflection = pow(labSkyEnvironment(reflectedDirection, 0.05, skyColor, fogColor), vec3(1.0/2.2));

            if (!(isWater && isEyeInWater == 1))
               reflectionColor.rgb = mix(skyReflection, reflectionColor.rgb, reflectionColor.a);
            // Retain scene hits, but avoid reflecting the outdoor sky inside caves.
            float skyAccess = isWater ? smoothstep(0.25,0.9,clamp((texture2D(colortex2,texUV).a-0.6)/0.4,0.0,1.0)) : 1.0;
            if (!(isWater && isEyeInWater == 1)) reflectionColor.a = mix(skyAccess,1.0,reflectionColor.a);
         }
      #endif

      if (isPbr) {
         vec3 F = labFresnel(texture2D(colortex5, texUV).rgb, max(dot(normal, normalize(-viewPos)), 0.0));
         F = clamp(F * LABPBR_SPECULAR_STRENGTH, 0.0, 1.0);
         vec3 reflected = pow(max(reflectionColor.rgb, vec3(0.0)), vec3(2.2));
         vec3 base = pow(max(color.rgb, vec3(0.0)), vec3(2.2));
         // Replace the approximate environment term where SSR finds a hit.
         base = mix(base, base * (vec3(1.0) - F) + reflected * F,
                    clamp(reflectionColor.a * reflectivity * 0.1*REFLECTIONS, 0.0, 1.0));
         color.rgb = pow(max(base, vec3(0.0)), vec3(1.0/2.2));
      } else {
      float viewCosine = dot(normal, normalize(-viewPos));
      // Water is two-sided; a back face must not become a fully opaque mirror.
      float grazing = 1.0-clamp(isWater ? abs(viewCosine) : max(viewCosine,0.0),0.0,1.0);
      // Use water Fresnel in both grading modes, preserving transmission away from grazing angles.
      if (isWater) {
         float fresnel=0.02+0.98*pow(grazing,5.0);
         // A gentle broad surface lobe helps small pools read as water.
         // Limit it to the top surface and preserve the underwater critical angle.
         if (isEyeInWater == 0) {
            float topSurface = smoothstep(0.65,0.95,prenormal.y);
            fresnel = mix(fresnel,0.04+0.96*pow(grazing,3.0),topSurface);
         }
         if (isEyeInWater == 1) {
            // Water-to-air critical angle: transmit overhead, reflect at grazing angles.
            float internalReflection=1.0-smoothstep(0.62,0.70,abs(viewCosine));
            fresnel=mix(fresnel,1.0,internalReflection);
            // Keep actual hit confidence: a missing reflection must not become opaque fog.
         }
         reflectionColor.a *= fresnel;
      }
      else {
      #if COLOR_GRADING == 1
         reflectionColor.a *= isGlass ? 0.04+0.96*pow(grazing,5.0) : grazing;
      #else
         reflectionColor.a *= grazing;
      #endif
      }
#if COLOR_GRADING == 1
      if (isWater) {
         waterReflection = pow(max(reflectionColor.rgb,vec3(0.0)),vec3(2.2));
         waterReflectionWeight = clamp(reflectionColor.a*reflectivity*0.1*REFLECTIONS,0.0,isEyeInWater == 1 ? 1.0 : 0.75); // Reserve transmission; celestial glints remain independent.
      } else
#endif
      color.rgb = mix(color.rgb,reflectionColor.rgb,reflectionColor.a*reflectivity*0.1*REFLECTIONS);
      }
   }

   #ifdef THE_END
      bool endSkyPixel = !hasRenderedSurface && texture2D(depthtex0, texUV).x >= 1.0;
      #ifdef DISTANT_HORIZONS
         endSkyPixel = endSkyPixel && texture2D(dhDepthTex0, texUV).x >= 1.0;
      #endif
      #ifdef ENABLE_SKY
         if (endSkyPixel) {
            vec3 skyDirection = normalize(view2eye(screen2view(texUV, 0.999)));
            // Depth-masked fallback also works when modern Minecraft omits
            // the old textured End-sky draw, and cannot cover distant islands.
            vec3 sky = vvEndSky(skyDirection);
            color.rgb = pow(sky, vec3(1.0/2.2));
         }
      #endif
   #endif
   #if defined THE_SIFT
      bool siftSkyPixel = !hasRenderedSurface && texture2D(depthtex0,texUV).x >= 1.0;
      #ifdef DISTANT_HORIZONS
         siftSkyPixel = siftSkyPixel && texture2D(dhDepthTex0,texUV).x >= 1.0;
      #endif
      #ifdef ENABLE_SKY
      if (siftSkyPixel) {
         vec3 direction = normalize(view2eye(screen2view(texUV,0.999)));
         vec3 sky = vvSiftSky(direction);
         color.rgb = pow(sky,vec3(1.0/2.2));
      }
      #endif
   #endif
   vec3 entityIrradiance=resolveEntityLight(texUV);
#if HAND_DYNAMIC_LIGHTING >= 0 && !defined LAMB_DYNAMIC_LIGHTS
   bool enchantedHeld = texelFetch(enchantedHeldSampler,ivec2(0),0).r != 0u;
   bool redstoneHeld = heldItemId == 42013 || heldItemId2 == 42013;
   if (enchantedHeld || redstoneHeld) {
      float heldReceiverDepth=entityReceiverDepth(texUV);
      if (heldReceiverDepth > 0.56 && heldReceiverDepth < 1.0) {
         vec3 heldReceiver=screen2view(texUV,heldReceiverDepth);
         float enchantedFalloff=max(0.0,1.0-length(heldReceiver)/6.0);
         if (enchantedHeld)
            entityIrradiance+=vec3(0.10,0.035,0.18)*enchantedFalloff*enchantedFalloff;
         // Redstone blocks have shader emission but no native light level.
         // Item IDs cover either hand without depending on visible glow pixels.
         if (redstoneHeld) {
            float redstoneFalloff=max(0.0,1.0-length(heldReceiver)/8.0);
            entityIrradiance+=vec3(0.4,0.006,0.002)*redstoneFalloff*redstoneFalloff;
         }
      }
   }
#endif
   vec3 receiverBase=max(texture2D(colortex1,texUV).rgb,vec3(0.0));
   color.rgb=pow(pow(max(color.rgb,vec3(0.0)),vec3(2.2))+receiverBase*entityIrradiance,vec3(1.0/2.2));
   #if COLOR_GRADING == 1
      vec3 sceneLinear = pow(max(color.rgb, vec3(0.0)), vec3(2.2));
      float opaqueDepth = texture2D(depthtex1, texUV).x;
      vec3 opaquePosition = vvOpaquePosition(texUV);
      float nearestDepth = texture2D(depthtex0, texUV).x;
      // Translucent entity render types are omitted from depthtex1. Stop air
      // scattering at their actual front depth rather than the sky behind them.
      if (texture2D(colortex1,texUV).a < -1.5 && nearestDepth < 1.0)
         opaquePosition = screen2view(texUV,nearestDepth);
      bool handPixel = nearestDepth < 0.56;
      vec3 waterSurfaceGlint = vec3(0.0);
#ifdef OVERWORLD
      vec3 bedWorld = view2feet(opaquePosition)+cameraPosition;
      vec3 bedNormal = cross(dFdx(bedWorld),dFdy(bedWorld));
      bedNormal /= max(length(bedNormal),1e-12);
      if (dot(bedNormal,cameraPosition-bedWorld) < 0.0) bedNormal = -bedNormal;
      float upwardBed = smoothstep(0.95,0.995,bedNormal.y);
      if (isWater && !handPixel) {
         waterSurfaceGlint = waterCelestialHighlight(waterEntryPosition(texUV,nearestDepth),nearestDepth);
      }
#endif
      // AO only affects opaque visible surfaces, not water, sky or the held item.
      if (!handPixel && opaqueDepth < 1.0 && abs(nearestDepth - opaqueDepth) < 0.00001)
         sceneLinear *= vvAmbientOcclusion(texUV, opaquePosition);
      #ifdef OVERWORLD
         // Project onto the actual opaque lake bed, visible through water too.
         if (!handPixel && (isEyeInWater == 1 || isWater) && opaqueDepth < 1.0 && upwardBed > 0.0 && texture2D(colortex1,texUV).a >= 0.0) {

            float waterThickness = min(length(opaquePosition), 48.0);
            if (isEyeInWater == 0)
               waterThickness = clamp(length(opaquePosition) - length(screen2view(texUV, nearestDepth)), 0.0, 48.0);
            float daylight = smoothstep(-0.02, 0.15, normalize(view2eye(sunPosition)).y);
            float illumination = upwardBed*vvSunVisibility(bedWorld);
            sceneLinear += min(sceneLinear * 0.8 + vec3(0.012), vec3(0.12, 0.16, 0.14)) * vvCausticPattern(bedWorld) * WATER_CAUSTICS
                         * vvCausticSunColor() * daylight * illumination * exp(-waterThickness * 0.14)
                         * (1.0 - rainStrength);
         }
      #endif
#ifdef OVERWORLD
      if (!handPixel && isEyeInWater == 1 && isWater && nearestDepth < 1.0) {
         vec3 airStart = waterEntryPosition(texUV,nearestDepth);
         sceneLinear = vvVolumetricsBetween(sceneLinear,airStart,opaquePosition);
      }
#endif
      if (!handPixel && (isEyeInWater == 1 || isWater)) {
         vec3 entry = vec3(0.0);
         vec3 exitPosition = opaquePosition;
         if (isEyeInWater == 0) entry = waterEntryPosition(texUV,nearestDepth);
         else if (nearestDepth < 1.0) exitPosition = screen2view(texUV,nearestDepth);
         sceneLinear = vvWaterFog(sceneLinear,entry,exitPosition);
      }
      if (isWater) {
         sceneLinear = vvWaterSurfaceTint(sceneLinear);
         sceneLinear = mix(sceneLinear,waterReflection,waterReflectionWeight);
      }
      if (isEyeInWater == 0) {
         sceneLinear += waterSurfaceGlint;
      }
      // Composite air last so water absorption/tint/reflections cannot erase foreground mist.
      if (!handPixel && !depthlessOverlay && isEyeInWater == 0) {
         sceneLinear = vvVolumetrics(sceneLinear,isWater ? waterEntryPosition(texUV,nearestDepth) : opaquePosition);
         #if defined THE_NETHER || defined THE_END || defined THE_SIFT
            vec3 fogPosition = opaquePosition;
            // Stop at the nearest visible translucent surface as well as solid terrain.
            if (nearestDepth < 1.0) fogPosition = screen2view(texUV, nearestDepth);
            #ifdef DISTANT_HORIZONS
               if (nearestDepth >= 1.0 && texture2D(dhDepthTex0, texUV).x < 1.0) {
                  vec4 lod = dhProjectionInverse * vec4(screen2ndc(vec3(texUV, texture2D(dhDepthTex0,texUV).x)),1.0);
                  fogPosition = lod.xyz / lod.w;
               }
            #endif
            #ifdef THE_END
               sceneLinear = vvDimensionFog(sceneLinear, fogPosition);
            #else
               #ifdef THE_SIFT
                  if (!siftSkyPixel) sceneLinear = vvDimensionFog(sceneLinear, fogPosition);
               #else
                  sceneLinear = vvDimensionFog(sceneLinear, fogPosition);
               #endif
               #ifdef THE_SIFT
                  if (!siftSkyPixel) sceneLinear += vvSiftAtmosphere(fogPosition);
               #endif
            #endif
         #endif
      }
      #ifdef THE_SIFT
         sceneLinear += vvBloom(texUV) * SIFT_GLOW;
      #else
         sceneLinear += vvBloom(texUV);
      #endif
      color.rgb = vvToneMap(sceneLinear);
      #ifdef THE_SIFT
         // Gently separate cyan highlights from violet shadow detail.
         float shade = 1.0-smoothstep(0.12,0.65,luma(color.rgb));
         color.rgb *= mix(vec3(1.035,1.015,0.97),vec3(0.96,1.035,1.02),shade);
      #endif
      float luminance = luma(color.rgb);
      // Moderate saturation keeps foliage natural and sunset shadows readable.
      color.rgb = mix(vec3(luminance), color.rgb, 1.08);
      color.rgb = labHighlightShoulder(max(color.rgb, vec3(0.0)), 0.95);
   #endif
   #if COLOR_GRADING == 0
      float nearest = texture2D(depthtex0,texUV).x;
      if (nearest >= 0.56 && (isEyeInWater == 1 || isWater)) {
         vec3 entry = isEyeInWater == 1 ? vec3(0.0) : waterEntryPosition(texUV,nearest);
         vec3 exitPosition = isEyeInWater == 1 && nearest < 1.0 ? screen2view(texUV,nearest) : vvOpaquePosition(texUV);
         color.rgb = pow(vvWaterFog(pow(max(color.rgb,vec3(0.0)),vec3(2.2)),entry,exitPosition),vec3(1.0/2.2));
      }
      if (isWater && nearest >= 0.56) {
         color.rgb = pow(vvWaterSurfaceTint(pow(max(color.rgb,vec3(0.0)),vec3(2.2))),vec3(1.0/2.2));
         vec3 highlight = isEyeInWater == 0 ? waterCelestialHighlight(waterEntryPosition(texUV,nearest),nearest) : vec3(0.0);
         color.rgb = pow(labHighlightShoulder(pow(max(color.rgb,vec3(0.0)),vec3(2.2))+highlight,0.65),vec3(1.0/2.2));
      }
   #endif
   gl_FragData[0] = color;
}
