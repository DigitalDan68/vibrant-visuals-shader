#ifdef ENTITY_VERTEX_EYES
#include "/shader.h"
#include "/common/transformations.glsl"
#include "/common/entity_vertex_light.glsl"
#endif
varying vec2 lightUV;
varying vec2 texUV;
varying vec4 color;

void main() {
   gl_Position = ftransform();
#if defined ENTITY_VERTEX_EYES && defined ENTITY_DYNAMIC_LIGHTING && !defined LAMB_DYNAMIC_LIGHTS
   captureEntityVertexLight((gl_ModelViewMatrix*gl_Vertex).xyz,(gl_TextureMatrix[1]*gl_MultiTexCoord1).xy,gl_Color);
#endif

	texUV   = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lightUV = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
   color   = gl_Color;
}
