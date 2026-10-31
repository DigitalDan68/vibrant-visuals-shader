#include "/shader.h"
uniform sampler2D colortex0;
uniform sampler2D colortex7;
uniform float viewWidth, viewHeight;
varying vec2 texUV;
void main() {
   vec3 bloom = vec3(0.0);
   #if COLOR_GRADING == 1
      if (BLOOM_STRENGTH > 0.0) {
      vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
      for (int x = -1; x <= 1; x++) for (int y = -1; y <= 1; y++) {
         vec3 sampleColor = pow(max(texture2D(colortex0, clamp(texUV + vec2(x,y)*texel, 0.0, 1.0)).rgb, vec3(0.0)), vec3(2.2));
         float brightness = max(sampleColor.r, max(sampleColor.g, sampleColor.b));
         float weight = smoothstep(0.65, 1.25, brightness);
         // Portals bloom independently of their restrained visible surface.
         vec4 material=texture2D(colortex7,clamp(texUV+vec2(x,y)*texel,0.0,1.0));
         if (abs(material.z-0.51)<0.003) weight=max(weight,5.0*material.y);
         bloom += sampleColor * weight / 9.0;
      }
      }
   #endif
   /* DRAWBUFFERS:4 */
   gl_FragData[0] = vec4(bloom, 1.0);
}
