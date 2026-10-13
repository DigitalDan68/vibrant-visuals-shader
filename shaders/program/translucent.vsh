#include "/shader.h"

attribute vec4 mc_Entity;

uniform float frameTimeCounter;
uniform float rainStrength;
uniform float screenBrightness;
uniform int isEyeInWater;
uniform int worldTime;
uniform sampler2D lightmap;
uniform vec3 sunPosition;

flat varying float redstonePower;
flat varying float portalSurface;
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

#ifdef VOXY
   varying float vanillaMix;
#endif

#include "/common/math.glsl"
#include "/common/transformations.glsl"
#include "/common/getFogMix.vsh"
#include "/common/getFogColor.vsh"
#include "/common/getAmbientColor.glsl"
#include "/common/getViewPosition.vsh"
#include "/common/getWaterTextureStrength.vsh"
#include "/common/getWaterWave.vsh"

void main() {
   gl_Position = ftransform();
   redstonePower = mc_Entity.x >= 43201.0 && mc_Entity.x <= 43215.0 ? (mc_Entity.x-43200.0)/15.0 : 0.0;
   waterSurface = float(mc_Entity.x == 10008.0);
   glassSurface = float(mc_Entity.x == 30030.0);
   portalSurface = float(mc_Entity.x >= 30020.0 && mc_Entity.x <= 30022.0);

   float sunHeight = view2feet(sunPosition).y;

   color        = gl_Color;
   texUV        = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
   lightUV      = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
   normal       = gl_Normal;
   blockLightNormal = normalize(view2eye(gl_NormalMatrix * gl_Normal));
   ambient      = getAmbientColor(lightUV.t, sunHeight);
   reflectivity = GLASS_REFLECTION_STRENGTH;

   feetPos = view2feet(getViewPosition());
   fogMix = getFogMix(feetPos);
   gradientFogColor = getFogColor(fogMix, feetPos);

   ambient.rgb *= color.a;
   color.a = 1.0;

   #ifdef VOXY
      vanillaMix = calcFogMix(feetPos, 0.3, far);
   #endif

   if (mc_Entity.x == 10008.0) {
      float posRandom = random(floor(feetPos.xz + cameraPosition.xz + vec2(0.01)));

      #if WATER_WAVE_SIZE > 0

         if (abs(normal.y) > 0.8) {
            normal = normalize(normal + getWaterWave(posRandom, feetPos));
         }

      #endif

      reflectivity = WATER_REFLECTIVITY;
      waterTexStrength = getWaterTextureStrength(posRandom);
   }

   if (glassSurface > 0.5) reflectivity = GLASS_REFLECTION_STRENGTH;
   if (portalSurface > 0.5 || redstonePower > 0.0) reflectivity = 0.0;
   normal = ndc2screen(normal);
}