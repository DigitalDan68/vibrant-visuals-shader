#include "/shader.h"
varying vec2 texUV;
varying vec4 celestialColor;
varying vec3 celestialViewPosition;
void main() {
   gl_Position = ftransform();
   texUV = (gl_TextureMatrix[0]*gl_MultiTexCoord0).st;
   celestialColor = gl_Color;
   celestialViewPosition = (gl_ModelViewMatrix*gl_Vertex).xyz;
}
