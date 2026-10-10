#include "/shader.h"
uniform int isEyeInWater;
uniform int worldTime;
uniform float rainStrength;
varying vec2 texUV;
varying vec2 lightUV;
varying vec4 particleColor;
varying float particleFog;
varying vec3 particleFogColor;
#include "/common/math.glsl"
#include "/common/transformations.glsl"
#include "/common/getFogMix.vsh"
#include "/common/getFogColor.vsh"
void main() {
   gl_Position = ftransform();
   texUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
   lightUV = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
   particleColor = gl_Color;
   vec3 feetPos = view2feet((gl_ModelViewMatrix * gl_Vertex).xyz);
   particleFog = getFogMix(feetPos);
   particleFogColor = getFogColor(particleFog, feetPos);
}
