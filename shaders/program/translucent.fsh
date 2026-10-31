#include "/shader.h"

uniform int isEyeInWater;
uniform float screenBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform sampler2D gtexture;
#include "/common/animated_emission.glsl"
#if COLOR_GRADING == 1
uniform sampler2D depthtex1;
uniform float viewWidth, viewHeight, frameTimeCounter;
#include "/common/transformations.glsl"
#endif

flat varying float redstonePower;
flat varying float portalSurface;
flat varying float animatedPortal;
flat varying float glassSurface;
flat varying float waterSurface;
varying float fogMix;
varying float reflectivity;
varying float waterTexStrength;
varying vec2 lightUV;
varying vec2 texUV;
varying vec3 feetPos;
varying vec3 gradientFogColor;
varying vec3 normal;
varying vec3 blockLightNormal;
varying vec4 ambient;
varying vec4 color;

#if HAND_DYNAMIC_LIGHTING == 0 && !defined LAMB_DYNAMIC_LIGHTS
   uniform int heldBlockLightValue;
#elif HAND_DYNAMIC_LIGHTING == 1 && !defined LAMB_DYNAMIC_LIGHTS
   #define heldBlockLightValue 14
#endif

#ifdef VOXY
   varying float vanillaMix;
#endif

#include "/common/math.glsl"
#include "/common/water_optics.glsl"
#include "/common/getTorchColor.fsh"

void main() {
   // Solid translucent faces are one-sided; keep water and portals two-sided.
   if (!gl_FrontFacing && waterSurface < 0.5 && portalSurface < 0.5) discard;
   // Above the water, hidden back faces must not replace the visible surface's
   // depth/material data. Underwater, retain back faces to show its underside.
   if (waterSurface > 0.5 && isEyeInWater != 1 && !gl_FrontFacing) discard;
   if (fogMix > 0.999) {
      discard;
   }

   vec3 waterBiomeTint = color.rgb;
   vec4 albedo  = texture2D(gtexture, texUV);
   // Water uses zero alpha for deferred absorption, so its automatic alpha
   // test is disabled. Other surfaces still need texture cutout rejection
   // before they can write depth or replace the water metadata behind them.
   if (waterSurface < 0.5 && albedo.a*color.a < 0.001) discard;
   vec3 redstoneBase = pow(max(albedo.rgb*color.rgb,vec3(0.0)),vec3(2.2));
   float waterDetail = 0.0;
   vec4 ambient = ambient;
   vec4 color   = color;

   #ifdef VOXY
      vec4 vanilla = albedo * color * ambient;
   #endif

   if (waterSurface > 0.5) {
      float textureValue = max(albedo.r,max(albedo.g,albedo.b));
      waterDetail = smoothstep(min(WATER_GLINT_CUTOFF+0.1,0.99),min(WATER_GLINT_CUTOFF+0.3,1.0),textureValue)*waterTexStrength;
      #if MC_VERSION >= 11300
         albedo.rgb = rescale(albedo.rgb * waterTexStrength, vec3(WATER_GLINT_CUTOFF), vec3(1.0));
#if COLOR_GRADING == 1
         albedo.rgb = vec3(WATER_BRIGHTNESS); // Glint is a directional specular emitter in final.
#else
         albedo.rgb = vec3(WATER_BRIGHTNESS); // Directional textured sun highlight is handled in final.
#endif

         #define WATER_BUFFER color
      #else
         #define WATER_BUFFER albedo
      #endif

      WATER_BUFFER.ba = min(WATER_BUFFER.ba, vec2(max(WATER_BUFFER.r, WATER_BUFFER.g)*WATER_B, WATER_A));
   }

   ambient.rgb += getTorchColor(lightUV.s, ambient.rgb, feetPos, normalize(blockLightNormal));

   if (portalSurface > 0.5) {
      float animatedGlow=animatedPortal>0.5 ? vvAnimatedEmission(30020.0,texUV,albedo.rgb) : 1.0;
      waterDetail=animatedGlow; // Portal metadata carries its per-frame bloom mask.
      vec3 portalBase=max(albedo.rgb*color.rgb,vec3(0.0));
      vec3 portalGlow=pow(pow(portalBase,vec3(2.2))*(PORTAL_EMISSION*0.35),vec3(1.0/2.2));
      albedo.rgb=mix(portalBase*ambient.rgb,portalGlow,animatedGlow);
   } else albedo.rgb *= color.rgb*ambient.rgb;
   // Resource packs may route dust through the translucent terrain pass.
   // State IDs distinguish powered wire without guessing from texture colors.
   if (redstonePower > 0.0) {
      float peak = max(redstoneBase.r,max(redstoneBase.g,redstoneBase.b));
      float emission = 3.0*pow(redstonePower,5.0)*INTEGRATED_EMISSION;
      vec3 radiance = pow(max(albedo.rgb,vec3(0.0)),vec3(2.2));
      radiance += redstoneBase/max(peak,0.001)*emission*1.5;
      albedo.rgb = pow(radiance,vec3(1.0/2.2));
   }
   albedo.a *= color.a*ambient.a;
   #if COLOR_GRADING == 1
      if (waterSurface > 0.5) {
#ifndef WATER_VOLUMETRICS
         vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
         float opaqueDepth = texture2D(depthtex1, uv).x;
         float thickness = 48.0;
         if (opaqueDepth < 1.0)
            thickness = clamp(length(screen2view(uv, opaqueDepth)) - length(feet2view(feetPos)), 0.0, 48.0);
         vec3 absorption = exp(-waterTintExtinction(waterBiomeTint) * thickness);
         albedo.rgb *= absorption;
         albedo.a = max(albedo.a * 0.55, 1.0 - exp(-thickness * WATER_ABSORPTION));
#else
         // Retain a small physical surface layer in the transparency blend.
// A nearer glass face replaces the deferred water tag, so zero-alpha
// water would otherwise disappear completely through stained glass.
         vec3 surfaceTint = waterStyledTint(waterBiomeTint);
         // Preserve the biome hue; use neutral lighting for this surface layer.
         float surfaceLight = max(dot(ambient.rgb,vec3(0.2126,0.7152,0.0722)),0.08);
         albedo.rgb = surfaceTint * surfaceLight;
         albedo.a = 0.08;
#endif
      }
   #endif

   #ifdef VOXY
      float reflectivity = mix(reflectivity, 0.0, vanillaMix);

      albedo = mix(albedo, vanilla, vanillaMix);
   #endif

   albedo.rgb = mix(albedo.rgb, gradientFogColor, fogMix);

   /* DRAWBUFFERS:0672 */
   gl_FragData[0] = albedo;
   gl_FragData[1] = vec4(normal, 1.0);
   gl_FragData[3] = waterSurface > 0.5 ? vec4(waterBiomeTint,0.6+0.4*clamp(lightUV.t,0.0,1.0)) : vec4(0.0);
   gl_FragData[2] = vec4(reflectivity, waterDetail, waterSurface > 0.5 ? 0.25 : (portalSurface < 0.5 ? 0.6 : 0.51), waterSurface > 0.5 ? 0.6+0.4*clamp(lightUV.s,0.0,1.0) : 1.0);
}