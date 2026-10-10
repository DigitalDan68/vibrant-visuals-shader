#include "/shader.h"
uniform int isEyeInWater;
uniform int worldTime;
uniform float rainStrength;
uniform vec3 sunPosition;
varying vec2 lightUV;
varying vec4 color;
varying vec3 feetPos;
varying float sunHeight;
varying float basicFog;
varying vec3 basicFogColor;

#include "/common/math.glsl"
#include "/common/transformations.glsl"
#include "/common/getFogMix.vsh"
#include "/common/getFogColor.vsh"

void main() {
   gl_Position = ftransform();

	lightUV = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
   color   = gl_Color;
   feetPos = view2feet((gl_ModelViewMatrix*gl_Vertex).xyz);
   sunHeight = view2feet(sunPosition).y;
   basicFog = getFogMix(feetPos);
   basicFogColor = getFogColor(basicFog,feetPos);
}
