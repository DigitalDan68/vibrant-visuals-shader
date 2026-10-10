#include "/shader.h"
#include "/common/entity_emission_target.glsl"
uniform int renderStage;
uniform sampler2D gtexture;
uniform int blockEntityId;
uniform int isEyeInWater;
uniform int worldTime;
uniform float rainStrength;
varying vec2 texUV;
varying vec4 beamColor;
varying vec3 beamFeetPos;
#include "/common/math.glsl"
#include "/common/transformations.glsl"
#include "/common/getFogMix.vsh"
#include "/common/getFogColor.vsh"
void main() {
   vec4 beam = texture2D(gtexture,texUV)*beamColor;
   if (beam.a < 0.001) discard;
   if (blockEntityId == 30022 || blockEntityId == 30021)
      beam.rgb = pow(pow(max(beam.rgb,vec3(0.0)),vec3(2.2))*PORTAL_EMISSION,vec3(1.0/2.2));
   // Beacon emission bypasses the lightmap, surface normals and material lighting.
   float fog = getFogMix(beamFeetPos);
   beam.rgb = mix(beam.rgb,getFogColor(fog,beamFeetPos),fog);
   /* DRAWBUFFERS:067528 */
   gl_FragData[0] = beam;
   gl_FragData[5] = vec4(0.0);
#ifdef ENTITY_DYNAMIC_LIGHTING
   if (renderStage==MC_RENDER_STAGE_ENTITIES && beam.a>0.05)
      gl_FragData[5]=vec4(pow(max(beam.rgb,vec3(0.0)),vec3(2.2)),1.0);
#endif
   gl_FragData[1] = vec4(0.0,0.0,0.0,1.0);
   gl_FragData[2] = vec4(0.0,0.0,0.9,1.0);
   gl_FragData[3] = vec4(0.0);
   gl_FragData[4] = vec4(0.0);
}
