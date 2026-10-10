#include "/shader.h"
varying vec2 texUV;
varying vec4 beamColor;
varying vec3 beamFeetPos;
#include "/common/transformations.glsl"
void main() {
   gl_Position = ftransform();
   texUV = (gl_TextureMatrix[0]*gl_MultiTexCoord0).st;
   beamColor = gl_Color;
   beamFeetPos = view2feet((gl_ModelViewMatrix*gl_Vertex).xyz);
}
