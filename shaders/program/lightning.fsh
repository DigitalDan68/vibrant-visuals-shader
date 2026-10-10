#include "/shader.h"
varying vec4 boltColor;
void main() {
   if (boltColor.a < 0.001) discard;
   // Preserve Minecraft's nested bolt geometry and alpha, with HDR emission.
   // No lightmap or material atlas belongs to this position/color render type.
   /* DRAWBUFFERS:012567 */
   gl_FragData[0] = vec4(boltColor.rgb*3.5,boltColor.a);
   gl_FragData[1] = vec4(boltColor.rgb,-2.0);
   gl_FragData[2] = vec4(0.0);
   gl_FragData[3] = vec4(0.0);
   gl_FragData[4] = vec4(0.5,0.5,0.5,1.0);
   gl_FragData[5] = vec4(0.0,1.0,0.9,1.0);
}
