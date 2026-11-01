// History is written only by composite3, never by a gbuffers draw.
// Moving entities have no object motion vectors, so only terrain uses it.
#ifdef TEMPORAL_SHADOW_CLAMP
#if defined OVERWORLD && defined GBUFFERS_TERRAIN && !defined MOD_COLORWHEEL
uniform sampler2D colortex11;
uniform mat4 gbufferPreviousModelView, gbufferPreviousProjection;
uniform vec3 previousCameraPosition;
uniform float frameTime;
uniform int frameCounter;
vec4 temporalShadowRecord=vec4(0.0);
float temporalShadowClamp(float current,vec3 feetPos,vec3 normal){
   vec3 world=feetPos+cameraPosition;
   vec3 movement=cameraPosition-previousCameraPosition;
   vec4 previousView=gbufferPreviousModelView*vec4(feetPos+movement,1.0);
   vec4 previousClip=gbufferPreviousProjection*previousView;
   float filtered=current;
   if(frameCounter>2 && dot(movement,movement)<4.0 && previousClip.w>0.0){
      vec2 uv=previousClip.xy/previousClip.w*0.5+0.5;
      ivec2 size=textureSize(colortex11,0);
      if(all(greaterThan(uv,vec2(0.0))) && all(lessThan(uv,vec2(1.0)))){
         ivec2 base=ivec2(floor(uv*vec2(size)-0.5));
         float bestError=1e20;
         float history=current;
         float previousRaw=step(0.5,current);
         float footprint=2.0*abs(previousView.z)/(abs(gbufferPreviousProjection[1].y)*float(size.y));
         float radius=max(0.015,footprint*1.5);
         // Select one matching surface, not a blend across silhouettes.
         for(int i=0;i<4;i++){
            ivec2 p=clamp(base+ivec2(i%2,i/2),ivec2(0),size-ivec2(1));
            vec4 h=texelFetch(colortex11,p,0);
            // X stores filtered visibility, the previous raw state and a
            // validity marker. YZW is the exact
            // stored world position. No inverse-projection or normal decoding.
            if(h.x<2.0 || h.x>5.0 || (h.x>3.0 && h.x<4.0)) continue;
            vec3 delta=h.yzw-world;
            float error=dot(delta,delta);
            if(error>radius*radius || abs(dot(delta,normal))>max(0.01,footprint*0.05)) continue;
            if(error<bestError){
               bestError=error;
               previousRaw=step(4.0,h.x);
               history=h.x-2.0-2.0*previousRaw;
            }
         }
         if(bestError<1e19){
            // Ignore a one-frame raw-state reversal. Once confirmed on the
            // next frame, respond quickly rather than dragging a 120 ms trail.
            float change=clamp(frameTime,0.001,0.1)/0.035;
            filtered=abs(step(0.5,current)-previousRaw)>0.5
               ? history : clamp(current,history-change,history+change);
         }
      }
   }
   temporalShadowRecord=vec4(filtered+2.0+2.0*step(0.5,current),world);
   return filtered;
}
#endif
#endif
