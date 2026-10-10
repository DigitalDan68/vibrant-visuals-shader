#include "/shader.h"
attribute vec4 mc_Entity;
uniform int renderStage;

varying vec2 texUV;
varying float alpha;
flat varying float shadowGlass;
varying vec3 shadowTint;

#include "/common/getShadowDistortion.glsl"
#include "/common/voxel_write.glsl"

void main() {
#ifdef COLORED_BLOCK_LIGHTING
   writeBlockVoxel();
#endif
   bool entityShadow=renderStage==MC_RENDER_STAGE_ENTITIES || renderStage==MC_RENDER_STAGE_BLOCK_ENTITIES;
   shadowGlass = float(!entityShadow && mc_Entity.x == 30030.0);
   shadowTint = gl_Color.rgb;
   gl_Position = ftransform();
   gl_Position.xyz = getShadowDistortion(gl_Position.xyz);

   texUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
   alpha = entityShadow ? 1.0 : ((mc_Entity.x == 10072.0 || mc_Entity.x == 10076.0 || mc_Entity.x == 10008.0) ? 0.0 : gl_Color.a);
}