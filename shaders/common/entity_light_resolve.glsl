uniform sampler2D colortex9;
#include "/common/entity_light_depth.glsl"
#include "/common/entity_shadow_grid.glsl"
vec3 resolveEntityLight(vec2 uv) {
#if defined ENTITY_DYNAMIC_LIGHTING && !defined LAMB_DYNAMIC_LIGHTS
 float depth=entityReceiverDepth(uv);
 if(depth<=0.56 || depth>=1.0 || texture2D(colortex1,uv).a < -1.0) return vec3(0.0);
 vec3 receiver=screen2view(uv,depth);
 vec3 viewNormal=eye2view(texture2D(colortex6,uv).rgb*2.0-1.0);
 if(entityWaterPixel(uv)) viewNormal=normalize(cross(dFdx(receiver),dFdy(receiver)));
 vec3 snapped=entityShadowGridReceiver(receiver,viewNormal);
 vec2 gridUV=clamp(view2screen(snapped).xy,vec2(0.0),vec2(1.0));
 float receiverDepth=-receiver.z;
 vec2 size=vec2(textureSize(colortex9,0));
 vec2 pixel=gridUV*size-0.5;
 vec2 base=floor(pixel),fraction=fract(pixel);
 vec3 lighting=vec3(0.0);float weights=0.0;
 for(int y=0;y<2;++y) for(int x=0;x<2;++x) {
  vec4 light=texture2D(colortex9,(base+vec2(x,y)+0.5)/size);
  vec2 weight=mix(1.0-fraction,fraction,vec2(x,y));
  float w=weight.x*weight.y*(1.0-smoothstep(0.1,max(0.3,receiverDepth*0.02),abs(light.a-receiverDepth)));
  lighting+=light.rgb*w;weights+=w;
 }
 return lighting/max(weights,0.001);
#else
 return vec3(0.0);
#endif
}
