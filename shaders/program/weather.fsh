#include "/shader.h"

uniform sampler2D gtexture;
uniform sampler2D lightmap;

varying vec2 texUV;
varying vec2 lightUV;
varying vec4 color;

void main() {
   vec4 albedo = texture2D(gtexture, texUV) * color;
   // Precipitation is lit scenery, rather than a full-bright white overlay.
   vec3 weatherLight = texture2D(lightmap, clamp(lightUV, vec2(0.5 / 16.0), vec2(15.5 / 16.0))).rgb;
   albedo.rgb *= weatherLight * vec3(0.28, 0.38, 0.48);

   albedo.a *= WEATHER_OPACITY;

   /* DRAWBUFFERS:0 */
   gl_FragData[0] = albedo;
}
