#include "/shader.h"
uniform sampler2D gtexture;
uniform vec3 sunPosition;
uniform float rainStrength;
varying vec2 texUV;
varying vec4 celestialColor;
varying vec3 celestialViewPosition;
void main() {
   vec4 sprite = texture2D(gtexture,texUV)*celestialColor;
   if (sprite.a < 0.001) discard;
#if COLOR_GRADING == 1
   // The native sun sprite is display-white, so the scene bloom threshold barely
   // captures it. Supply a sun-only HDR emitter before bloom extraction.
   float alignment = dot(normalize(celestialViewPosition),normalize(sunPosition));
   float sun = smoothstep(0.8,0.95,alignment);
   float emission = 1.0+sun*SUN_BLOOM_STRENGTH*5.0*(1.0-rainStrength);
   sprite.rgb = pow(pow(max(sprite.rgb,vec3(0.0)),vec3(2.2))*emission,vec3(1.0/2.2));
#endif
   /* DRAWBUFFERS:0 */
   gl_FragData[0] = sprite;
}
