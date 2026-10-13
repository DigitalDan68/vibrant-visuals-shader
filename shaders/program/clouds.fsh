#define GBUFFERS_CLOUDS

#include "/shader.h"

uniform sampler2D gtexture;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform int isEyeInWater;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

varying float fogMix;
varying float sunClosenessToHorizon;
varying vec2 texUV;
varying vec3 normalizedViewPos;
varying vec4 color;

#include "/common/math.glsl"
#include "/common/biome_atmosphere.glsl"

void main() {
#if MC_VERSION >= 12111
   // Modern cloud meshes provide vertex color, without texture coordinates.
   vec4 albedo = color;
#else
   vec4 albedo = texture2D(gtexture, texUV) * color;
#endif

   albedo.a = mix(albedo.a, 0, fogMix);
   // Underwater fogColor belongs to the water volume, not the cloud layer.
   vec3 atmosphereColor = isEyeInWater == 1 ? skyColor : vvBiomeAtmosphereColor(fogColor,0.0);
   albedo.rgb = mix(albedo.rgb, atmosphereColor, 0.6);
   // Keep the cloud layer continuous; bloom handles glare without an angular hole.

   /* DRAWBUFFERS:06 */
   gl_FragData[0] = albedo;
   gl_FragData[1] = vec4(vec3(0.0), 1.0);
}