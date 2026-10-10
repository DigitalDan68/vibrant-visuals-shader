#include "/shader.h"
#include "/common/transformations.glsl"
layout(local_size_x=8,local_size_y=8,local_size_z=1) in;
const ivec3 workGroups=ivec3(16,9,1);
uniform sampler2D colortex8,depthtex0,depthtex1,colortex7;
#include "/common/entity_light_depth.glsl"
layout(rgba32f) uniform image2D entitySourcePosition;
layout(rgba32f) uniform image2D entitySourceColor;
shared vec4 sourceColor[64];
shared vec4 sourcePosition[64];
void main() {
 uint lane=gl_LocalInvocationIndex;
 vec4 bestColor=vec4(0.0),bestPosition=vec4(0.0);
#if defined ENTITY_DYNAMIC_LIGHTING && !defined LAMB_DYNAMIC_LIGHTS
 ivec2 size=textureSize(colortex8,0);
 ivec2 tile=ivec2(gl_WorkGroupID.xy);
 ivec2 begin=tile*size/ivec2(16,9),end=(tile+1)*size/ivec2(16,9);
 for(int y=begin.y+int(gl_LocalInvocationID.y);y<end.y;y+=8)
 for(int x=begin.x+int(gl_LocalInvocationID.x);x<end.x;x+=8) {
  vec4 sampleValue=texelFetch(colortex8,ivec2(x,y),0);
  float peak=max(sampleValue.r,max(sampleValue.g,sampleValue.b));
  vec2 uv=(vec2(x,y)+0.5)/vec2(size);
  float depth=entityReceiverDepth(uv);
  if(sampleValue.a>0.5 && depth>0.56 && depth<1.0 && peak>0.001) {
   vec3 position=screen2view(uv,depth);
   if(entityWithinLightRange(position)) {
    // Weight the whole visible glow patch, avoiding jumps between brightest pixels.
    bestColor+=vec4(sampleValue.rgb*peak,peak);
    bestPosition+=vec4(position*peak,peak);
   }
  }
 }
#endif
 sourceColor[lane]=bestColor;sourcePosition[lane]=bestPosition;
 barrier();
 for(uint stride=32u;stride>0u;stride/=2u) {
  if(lane<stride) {
   sourceColor[lane]+=sourceColor[lane+stride];sourcePosition[lane]+=sourcePosition[lane+stride];
  }
  barrier();
 }
 if(lane==0u) {
  float weight=sourceColor[0].a;
  vec3 emission=sourceColor[0].rgb/max(weight,0.001);
  // Keep the pre-rasterization source when its glowing face is hidden.
#if defined ENTITY_DYNAMIC_LIGHTING && !defined LAMB_DYNAMIC_LIGHTS
  if(weight<=0.001 && imageLoad(entitySourcePosition,ivec2(gl_WorkGroupID.xy)).w>0.5) return;
#endif
  imageStore(entitySourcePosition,ivec2(gl_WorkGroupID.xy),vec4(sourcePosition[0].xyz/max(weight,0.001),weight>0.001 ? 1.0 : 0.0));
  imageStore(entitySourceColor,ivec2(gl_WorkGroupID.xy),vec4(emission,max(emission.r,max(emission.g,emission.b))));
 }
}
