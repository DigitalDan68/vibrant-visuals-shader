#include "/shader.h"

// Keep Iris's fog declarations in order; opt out of Chunks Fade In's DH patch.
void _cfi_ignoreMarker() {}

uniform sampler2D lightmap;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex1;
uniform float viewWidth,viewHeight;
#ifdef DH_WATER_PASS
   uniform sampler2D dhDepthTex1;
   uniform mat4 dhProjectionInverse;
#endif
uniform float screenBrightness;
uniform float rainStrength;
uniform int worldTime;
uniform int isEyeInWater;
uniform ivec2 eyeBrightnessSmooth;
in vec4 color;
in vec2 lightUV;
in vec3 feetPos;
in vec3 dhNormal;
in float sunHeight;
flat in float dhEmission;
flat in float dhWater;

#if HAND_DYNAMIC_LIGHTING == 0 && !defined LAMB_DYNAMIC_LIGHTS
   uniform int heldBlockLightValue;
#elif HAND_DYNAMIC_LIGHTING == 1 && !defined LAMB_DYNAMIC_LIGHTS
   #define heldBlockLightValue 14
#endif

#include "/common/math.glsl"
#include "/common/water_optics.glsl"
#include "/common/transformations.glsl"
#include "/common/getAmbientColor.glsl"
#include "/common/getTorchColor.fsh"
#include "/common/getFogMix.vsh"
#include "/common/getFogColor.vsh"
#include "/common/labpbr.glsl"

#ifdef ENABLE_SHADOWS
   uniform vec3 shadowLightPosition;
   uniform mat4 shadowModelView;
   uniform mat4 shadowProjection;
   uniform sampler2D shadowtex1;
   #include "/common/getLightStrength.fsh"
   #include "/common/getLightColor.vsh"
#endif

void main() {
   // Native chunks own the near field, including holes in cutout meshes.
   // A LOD's solid approximation must not fill iron-bar/leaf/glass gaps.
   // Keep two chunks of overlap at the native boundary for terrain coverage.
   float nativeInterior = max(far - 32.0, 0.0);
   if (length(feetPos.xz) < nativeInterior) discard;
   #ifdef DH_WATER_PASS
   {
      // DH uses a separate projection/depth buffer. Explicitly protect nearby
      // opaque Minecraft surfaces from distant translucent LOD water.
      vec2 sceneUV = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
      if (texture2D(colortex1,sceneUV).a < -1.5) discard;
      float opaqueDepth = min(texture2D(depthtex0,sceneUV).x,texture2D(depthtex1,sceneUV).x);
      // Loaded native geometry owns this pixel, including transparent water.
      // Approximate secondary geometry must not replace its material/tint
      // data merely because its independently projected depth is closer.
      if (opaqueDepth < 1.0) discard;
   }
   #endif
   vec4 albedo = color;
   vec4 ambient = getAmbientColor(lightUV.t, sunHeight);
   #ifdef THE_END
      ambient.rgb *= END_AMBIENT + 0.02 * dhNormal;
   #endif
   #ifdef ENABLE_SHADOWS
      float diffuse = clamp(2.5 * dot(normalize(dhNormal), normalize(view2eye(shadowLightPosition))), -0.3333, 1.0);
      diffuse *= (isEyeInWater == 0 ? 1.0 : 0.5) * (1.0 - rainStrength)
               * clamp(0.1*abs(sunHeight) - 0.4453, 0.0, 1.0);
      float strength = max(getLightStrength(diffuse, lightUV.t, feetPos), 0.75 * dhEmission);
      ambient.rgb *= mix(SHADOW_COLOR, vec3(1.0), strength);
      ambient.rgb *= 0.75 + max(0.0, LIGHT_BRIGHTNESS - 0.5*pow3(luma(albedo.rgb)))
                   * strength * getLightColor(sunHeight, lightUV.t);
   #endif
   ambient.rgb += getTorchColor(lightUV.s, ambient.rgb, feetPos, normalize(dhNormal));
   ambient.rgb = mix(ambient.rgb, max(ambient.rgb, vec3(1.0)), dhEmission);
   #ifdef DH_WATER_PASS
      if (dhWater > 0.5) {
         albedo.rgb = vec3(WATER_BRIGHTNESS) * color.rgb;
         albedo.b = min(albedo.b, max(albedo.r, albedo.g) * WATER_B);
         albedo.a = WATER_A;
      }
   #else
      albedo.a = 1.0;
   #endif
   albedo.rgb *= ambient.rgb;
   #if COLOR_GRADING == 1 && defined DH_WATER_PASS
      if (dhWater > 0.5) {
#ifndef WATER_VOLUMETRICS
         vec2 waterUV = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
         float lodOpaqueDepth = texture2D(dhDepthTex1, waterUV).x;
         float thickness = 48.0;
         if (lodOpaqueDepth < 1.0) {
            vec4 behind = dhProjectionInverse * vec4(screen2ndc(vec3(waterUV, lodOpaqueDepth)), 1.0);
            thickness = clamp(length(behind.xyz / behind.w) - length(feet2view(feetPos)), 0.0, 48.0);
         }
         albedo.rgb *= exp(-waterTintExtinction(color.rgb) * thickness * (WATER_ABSORPTION/0.08));
         albedo.a = max(albedo.a * 0.55, 1.0 - exp(-thickness * WATER_ABSORPTION));
#else
         albedo.a = 0.0; // Final supplies the water volume, shared with native water.
#endif

      }
   #endif
   #if defined THE_NETHER && defined NETHER_COLOR_GRADING
      albedo.rgb = mix(vec3(luma(albedo.rgb)), albedo.rgb,
                       max(rescale(luma(ambient.rgb), 0.2, 0.6), rescale(luma(color.rgb), 0.15, 0.4)));
   #endif
   float fog = getFogMix(feetPos);
   albedo.rgb = mix(albedo.rgb, getFogColor(fog, feetPos), fog);
   // DH has no labPBR atlas or tangent data. Clear material metadata explicitly.
   /* DRAWBUFFERS:06752 */
   gl_FragData[0] = albedo;
   gl_FragData[1] = vec4(vec3(0.5), 1.0);
   gl_FragData[2] = vec4(0.0, 0.0, 0.0, 1.0);
   gl_FragData[3] = vec4(0.0);
   gl_FragData[4] = vec4(0.0);
#ifdef DH_WATER_PASS
   if (dhWater > 0.5) {
      gl_FragData[1] = vec4(normalize(dhNormal)*0.5+0.5,1.0);
      gl_FragData[2] = vec4(WATER_REFLECTIVITY,0.0,0.26,0.6+0.4*clamp(lightUV.s,0.0,1.0));
      gl_FragData[4] = vec4(color.rgb,0.6+0.4*clamp(lightUV.t,0.0,1.0));
   }
#endif
}
