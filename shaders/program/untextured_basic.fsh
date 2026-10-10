#include "/shader.h"
uniform sampler2D lightmap;
uniform float screenBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform int heldBlockLightValue;
#ifndef THE_NETHER
uniform vec3 fogColor;
#endif

varying vec2 lightUV;
varying vec4 color;
varying vec3 feetPos;
varying float sunHeight;
varying float basicFog;
varying vec3 basicFogColor;

#include "/common/math.glsl"
#include "/common/getAmbientColor.glsl"
#include "/common/getTorchColor.fsh"

void main() {
   if (color.a < 0.001) discard;
   // Leads have position/color/lightmap attributes, without a color texture.
   vec3 ambient = getAmbientColor(lightUV.t,sunHeight).rgb;
   ambient += getTorchColor(lightUV.s,ambient,feetPos);
   vec3 lit = mix(color.rgb*ambient,basicFogColor,basicFog);
   /* DRAWBUFFERS:012567 */
   gl_FragData[0] = vec4(lit,color.a);
   // Clear background material state and protect this thin native geometry
   // from DH overlays, water reflections, caustics and sky replacement.
   gl_FragData[1] = vec4(color.rgb,-2.0);
   gl_FragData[2] = vec4(0.0);
   gl_FragData[3] = vec4(0.0);
   gl_FragData[4] = vec4(0.5,0.5,0.5,1.0);
   gl_FragData[5] = vec4(0.0,1.0,0.9,1.0);
}
