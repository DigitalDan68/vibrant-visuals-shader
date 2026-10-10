#include "/shader.h"
uniform sampler2D gtexture;

varying vec2 texUV;
varying float alpha;
flat varying float shadowGlass;
varying vec3 shadowTint;

void main() {
   vec4 albedo = texture2D(gtexture, texUV);

   if (shadowGlass > 0.5) {
      vec3 tint = mix(vec3(1.0),albedo.rgb*shadowTint,step(0.01,albedo.a));
      tint /= max(max(tint.r,max(tint.g,tint.b)),0.001);
      gl_FragData[0] = vec4(mix(vec3(0.08),tint,0.62),1.0);
      return;
   }
   albedo.a *= alpha;

   if (albedo.a < 0.1) {
      discard;
   }

   gl_FragData[0] = vec4(vec3(0.0),0.0);
}