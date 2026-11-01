#include "/shader.h"
attribute vec4 mc_Entity;
uniform int renderStage;
uniform vec3 cameraPosition;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

varying vec2 texUV;
varying float alpha;
flat varying float shadowGlass;
varying vec3 shadowTint;

#include "/common/getShadowDistortion.glsl"

void main() {
   bool entityShadow=renderStage==MC_RENDER_STAGE_ENTITIES || renderStage==MC_RENDER_STAGE_BLOCK_ENTITIES;
   shadowGlass = float(!entityShadow && (mc_Entity.x == 30030.0 || mc_Entity.x == 30031.0));
   shadowTint = gl_Color.rgb;
   // Use the same pack projection as the receiver lookup, including its
   // explicit near/far planes; keep the native object/chunk model transform.
   gl_Position = shadowProjection * gl_ModelViewMatrix * gl_Vertex;
   gl_Position.xyz = getShadowDistortion(gl_Position.xyz);

   texUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
   alpha = entityShadow ? 1.0 : ((mc_Entity.x == 10072.0 || mc_Entity.x == 10076.0 || mc_Entity.x == 10008.0) ? 0.0 : gl_Color.a);
}
