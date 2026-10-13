#include "/shader.h"
uniform sampler2D colortex4;
#include "/common/bloom_sampling.glsl"
uniform float viewWidth;
varying vec2 texUV;
void main() {
   vec3 light = vec3(0.0);
#if COLOR_GRADING == 1
   if (BLOOM_STRENGTH > 0.0) {
      float radius = 2.0/viewWidth*BLOOM_RADIUS;
      for (int x=-2;x<=2;++x) {
         float weight = x == 0 ? 1.0 : (abs(x) == 1 ? 0.60653066 : 0.13533528);
         light += vvSmoothBloom(clamp(texUV+vec2(float(x)*radius,0.0),0.0,1.0))*weight;
      }
      light /= 2.48373188;
   }
#endif
   /* DRAWBUFFERS:4 */
   gl_FragData[0] = vec4(light,1.0);
}
