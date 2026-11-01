#include "/shader.h"
uniform sampler2D colortex10;
varying vec2 texUV;
void main(){
   /* RENDERTARGETS:11 */
   gl_FragData[0]=texelFetch(colortex10,ivec2(gl_FragCoord.xy),0);
}
