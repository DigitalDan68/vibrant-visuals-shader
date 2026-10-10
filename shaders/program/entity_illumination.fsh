#include "/shader.h"
#include "/common/entity_emission_target.glsl"
#include "/common/transformations.glsl"
uniform sampler2D entitySourcePositions,entitySourceColors;
uniform sampler2D depthtex0,depthtex1,colortex6,colortex1,colortex7;
#include "/common/entity_light_depth.glsl"
#include "/common/entity_shadow_grid.glsl"
uniform sampler2D colortex9;
uniform mat4 gbufferPreviousModelView,gbufferPreviousProjection;
uniform vec3 previousCameraPosition;
uniform float frameTime;
uniform int frameCounter;
varying vec2 texUV;
vec3 stabilizeEntityLighting(vec3 current,vec3 receiver) {
 if(frameCounter<2) return current;
 vec3 previousFeet=view2feet(receiver)+cameraPosition-previousCameraPosition;
 vec4 previousView=gbufferPreviousModelView*vec4(previousFeet,1.0);
 vec4 clip=gbufferPreviousProjection*previousView;
 if(clip.w<=0.0) return current;
 vec2 uv=clip.xy/clip.w*0.5+0.5;
 if(any(lessThan(uv,vec2(0.0))) || any(greaterThan(uv,vec2(1.0)))) return current;
 vec4 history=texture2D(colortex9,uv);
 float expectedDepth=-previousView.z;
 // Reject disoccluded geometry so old lighting cannot smear onto new surfaces.
 if(history.a<=0.0 || abs(history.a-expectedDepth)>max(0.15,expectedDepth*0.01)) return current;
 float currentWeight=1.0-exp(-max(frameTime,0.001)/0.065);
 return mix(max(history.rgb,vec3(0.0)),current,currentWeight);
}
float entityLightVisibility(vec3 receiver,vec3 source) {
 float visibility=1.0;
 for(int stepIndex=1;stepIndex<=4;++stepIndex) {
  vec3 p=mix(receiver,source,float(stepIndex)/5.0);
  vec3 projected=view2screen(p);
  if(any(lessThan(projected.xy,vec2(0.0))) || any(greaterThan(projected.xy,vec2(1.0)))) continue;
  // A glowing mob's own body is not a solid-world blocker.
  if(texture2D(colortex1,projected.xy).a < -1.5) continue;
  float depth=entityReceiverDepth(projected.xy);
  if(depth<1.0) {
   float blocker=-screen2view(projected.xy,depth).z;
   float clearance=(-p.z)-blocker;
   visibility*=1.0-smoothstep(0.25,0.55,clearance);
  }
 }
 return visibility;
}
void main() {
 vec4 result=vec4(0.0);
#if defined ENTITY_DYNAMIC_LIGHTING && !defined LAMB_DYNAMIC_LIGHTS
 float depth=entityReceiverDepth(texUV);
 if(depth>0.56 && depth<1.0 && texture2D(colortex1,texUV).a>=-1.0) {
  vec3 receiver=screen2view(texUV,depth);
  if(!entityWithinLightRange(receiver)) {gl_FragData[0]=vec4(0.0);return;}
  vec3 encodedNormal=texture2D(colortex6,texUV).rgb*2.0-1.0;
  vec3 normal=normalize(eye2view(encodedNormal));
  if(entityWaterPixel(texUV)) normal=normalize(cross(dFdx(receiver),dFdy(receiver)));
  if(dot(encodedNormal,encodedNormal)<0.01) normal=normalize(cross(dFdx(receiver),dFdy(receiver)));
  vec3 shadowReceiver=entityShadowGridReceiver(receiver,normal);
  vec3 irradiance=vec3(0.0);
  for(int y=0;y<9;++y) for(int x=0;x<16;++x) {
   vec4 source=texelFetch(entitySourcePositions,ivec2(x,y),0);
   if(source.w<0.5 || !entityWithinLightRange(source.xyz)) continue;
   vec3 delta=source.xyz-receiver;
   float distanceSquared=dot(delta,delta);
   if(distanceSquared>=36.0 || distanceSquared<0.0001) continue;
   float distanceToLight=sqrt(distanceSquared);
   float facing=max(0.0,dot(normal,delta/distanceToLight));
   if(facing<0.001) continue;
   vec4 emission=texelFetch(entitySourceColors,ivec2(x,y),0);
   float strength=min(emission.a,2.0)*0.5;
#ifdef COLORED_BLOCK_LIGHTING
   vec3 tint=emission.rgb/max(emission.a,0.001);
#else
   vec3 tint=vec3(1.0,0.78,0.52);
#endif
   float falloff=pow(max(0.0,1.0-distanceToLight/6.0),2.0);
   vec3 contribution=tint*strength*falloff*facing*entityLightVisibility(shadowReceiver+normal*0.08,source.xyz);
   // Max blending prevents several visible tiles of one entity multiplying brightness.
   irradiance=max(irradiance,contribution);
  }
  result=vec4(stabilizeEntityLighting(irradiance,receiver),-receiver.z);
 }
#endif
 /* DRAWBUFFERS:9 */
 gl_FragData[0]=result;
}
