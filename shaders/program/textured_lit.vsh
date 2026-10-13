#include "/shader.h"

attribute vec4 mc_Entity;
uniform int blockEntityId;
uniform int entityId;
uniform int currentRenderedItemId;
#if (defined GBUFFERS_TERRAIN || defined GBUFFERS_ENTITIES_OPAQUE || defined GBUFFERS_ENTITIES_TRANSLUCENT || defined GBUFFERS_HAND) && !defined MOD_COLORWHEEL
   flat varying float integratedId;
   flat varying float cutCopperSurface;
   varying vec3 pbrNormal;
   varying vec4 pbrTangent;
   flat varying float pbrIsThin;
   #ifdef ENABLE_SHADOWS
      varying float pbrDiffuseScale;
   #endif
#endif

#if defined GBUFFERS_TERRAIN && !defined MOD_COLORWHEEL
   attribute vec4 at_tangent;
#endif

#ifdef IRIS_FEATURE_BLOCK_EMISSION_ATTRIBUTE
   attribute vec4 at_midBlock;
#endif

uniform float rainStrength;
uniform float screenBrightness;
uniform int isEyeInWater;
uniform int worldTime;
uniform vec3 sunPosition;

#ifdef HIGHLIGHT_WAXED
   uniform int heldItemId;
   uniform int heldItemId2;
#endif

flat varying float lightSourceLevel;
varying float fogMix;
varying float sunHeight;
varying vec2 lightUV;
varying vec2 texUV;
varying vec3 feetPos;
varying vec3 gradientFogColor;

#ifdef GBUFFERS_TERRAIN
   varying vec4 color;
#else
   flat varying vec4 color;
#endif

#ifdef THE_END
   varying vec3 endTint;
#endif

#if BLOCK_REFLECTIONS > 0
   flat varying vec3 blockReflectivity;
   varying vec3 normal;

   #include "/common/blockReflectivity.glsl"
#endif

#ifdef GLOWING_ORES
   flat varying float isOre;
#endif

#include "/common/math.glsl"
#include "/common/transformations.glsl"
#include "/common/getFogMix.vsh"
#include "/common/getFogColor.vsh"
#include "/common/getViewPosition.vsh"

#ifdef ENABLE_SHADOWS
   uniform vec3 shadowLightPosition;

   varying vec3 lightColor;
   varying float diffuse;

   #include "/common/getDiffuse.vsh"
   #include "/common/getLightColor.vsh"
#endif

#if defined GBUFFERS_ENTITIES_OPAQUE || defined GBUFFERS_ENTITIES_TRANSLUCENT
#endif
void main() {
   gl_Position = ftransform();
   #if (defined GBUFFERS_TERRAIN || defined GBUFFERS_ENTITIES_OPAQUE || defined GBUFFERS_ENTITIES_TRANSLUCENT || defined GBUFFERS_HAND) && !defined MOD_COLORWHEEL
      #ifdef GBUFFERS_TERRAIN
      float terrainMaterialId=mc_Entity.x;
      integratedId = (blockEntityId == 20007 || blockEntityId == 20008 || (blockEntityId >= 43101 && blockEntityId <= 43113) || (blockEntityId >= 30020 && blockEntityId <= 30022)) ? float(blockEntityId) : terrainMaterialId;
      #else
      integratedId = currentRenderedItemId > 0 ? float(currentRenderedItemId) : (blockEntityId == 20007 || blockEntityId == 20008 || (blockEntityId >= 43101 && blockEntityId <= 43113) ? float(blockEntityId) : float(entityId));
      #endif
      cutCopperSurface = float(integratedId>=43501.0 && integratedId<=43504.0);
      if (cutCopperSurface>0.5)
         integratedId = integratedId<43501.5 ? 20008.0 : 43100.0+(integratedId-43501.0);
      pbrNormal = view2eye(gl_NormalMatrix * gl_Normal);
      pbrNormal = dot(pbrNormal,pbrNormal)>0.00001 ? normalize(pbrNormal) : vec3(0.0,1.0,0.0);
      #ifdef GBUFFERS_TERRAIN
      pbrTangent = vec4(view2eye(gl_NormalMatrix * at_tangent.xyz), at_tangent.w);
      #else
      pbrTangent = vec4(0.0);
      #endif
   #endif

   sunHeight = view2feet(sunPosition).y;
   color     = gl_Color;
   texUV     = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
   lightUV   = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
   lightSourceLevel = float(mc_Entity.x == 10068.0 || mc_Entity.x == 10072.0 ||
                            mc_Entity.x == 10076.0 || mc_Entity.x == 10496.0 ||
                            mc_Entity.x == 10528.0 || mc_Entity.x == 10604.0 ||
                            mc_Entity.x == 10652.0 || mc_Entity.x == 10656.0 ||
                            mc_Entity.x == 10984.0);

   #ifdef IRIS_FEATURE_BLOCK_EMISSION_ATTRIBUTE
      lightSourceLevel = max(lightSourceLevel, at_midBlock.w < 16.0 ? at_midBlock.w / 15.0 : 0.0);
   #endif

   #ifdef THE_END
      endTint = END_AMBIENT + 0.02*(gl_NormalMatrix * gl_Normal).xyz;
   #endif

   #if BLOCK_REFLECTIONS > 0
      normal = ndc2screen(gl_Normal);
      blockReflectivity = BLOCK_REFLECTIVITY[int(mc_Entity.x >= 20001.0 && mc_Entity.x <= 20017.0 ? mc_Entity.x - 20000.0 : 0.0)];
   #endif

   if (mc_Entity.x == 10068.0) { // lava
      color.rgb = mix(vec3(0.8, 0.5, 0.3), vec3(1.0), rescale(color.rgb, vec3(0.54), vec3(0.9)));
      color.a = 1.0;
   }

   #ifdef GLOWING_ORES
      isOre = float(mc_Entity.x == 10014.0);
   #endif

   #ifdef HIGHLIGHT_WAXED
      color.rgb *= (heldItemId == 20007 || heldItemId2 == 20007) && mc_Entity.x == 20007.0 ? 0.4 : 1.0;
   #endif

   bool isThin = mc_Entity.x == 10031.0 || (mc_Entity.x == 10059.0 || mc_Entity.x == 42015.0)
              || mc_Entity.x == 10175.0 || mc_Entity.x == 10176.0;

   #if (defined GBUFFERS_TERRAIN || defined GBUFFERS_ENTITIES_OPAQUE || defined GBUFFERS_ENTITIES_TRANSLUCENT || defined GBUFFERS_HAND) && !defined MOD_COLORWHEEL
      pbrIsThin = float(isThin);
   #endif

   #ifndef FLAT_LIGHTING
      vec3 lightNormal = gl_NormalMatrix * gl_Normal;

      lightNormal = isThin ? vec3(0.0, 1.0, 0.0) : view2eye(lightNormal);

      color.rgb *= clamp(lightNormal.x * lightNormal.x * 0.6
                       + lightNormal.y * lightNormal.y * 0.25 * (3.0 + lightNormal.y)
                       + lightNormal.z * lightNormal.z * 0.8, step(0.933, lightSourceLevel), 1.0);
   #endif

   feetPos = view2feet(getViewPosition());
   fogMix = getFogMix(feetPos);
   fogMix = mix(fogMix, fogMix*fogMix, lightSourceLevel);
   gradientFogColor = getFogColor(fogMix, feetPos);

   #ifdef ENABLE_SHADOWS
      float skyLight = clamp(lightUV.t, 0.0, 1.0);

      diffuse = getDiffuse(sunHeight, skyLight, isThin);
      #if (defined GBUFFERS_TERRAIN || defined GBUFFERS_ENTITIES_OPAQUE || defined GBUFFERS_ENTITIES_TRANSLUCENT || defined GBUFFERS_HAND) && !defined MOD_COLORWHEEL
         pbrDiffuseScale = getDiffuse(sunHeight, skyLight, true) / 0.75;
      #endif
      lightColor = getLightColor(sunHeight, skyLight);
   #endif
}
