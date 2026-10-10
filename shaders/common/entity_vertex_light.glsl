// Capture emission before rasterization/culling. Only Ultra enables this path.
#if defined ENTITY_DYNAMIC_LIGHTING && !defined LAMB_DYNAMIC_LIGHTS
uniform sampler2D gtexture;
#ifndef ENTITY_VERTEX_EYES
uniform sampler2D specular;
#endif
layout(rgba32f) uniform image2D entitySourcePosition;
layout(rgba32f) uniform image2D entitySourceColor;
void captureEntityVertexLight(vec3 position,vec2 lightCoords,vec4 vertexTint) {
#ifndef ENTITY_VERTEX_EYES
   bool fullbright = min(lightCoords.x,lightCoords.y)>0.96;
#else
   bool fullbright = true;
#endif
   // A coarse mip scan covers tiny eye pixels even on back-facing triangles.
   // It reads each entity's texture, never adds shader-defined mob emission.
   if ((gl_VertexID & 3) != 0) return; // One capture per typical model quad.
   vec2 dimensions=vec2(textureSize(gtexture,0));
   float level=max(0.0,log2(max(dimensions.x,dimensions.y)/8.0));
   int scanSize = textureQueryLevels(gtexture)>1 ? 8 : 32;
   vec3 emission=vec3(0.0);
   for(int y=0;y<scanSize;y++) for(int x=0;x<scanSize;x++) {
      vec2 uv=(vec2(x,y)+0.5)/float(scanSize);
      vec4 texel=textureLod(gtexture,uv,level);
      if(texel.a<0.0001) continue;
      float amount=fullbright ? 1.0 : 0.0;
#ifndef ENTITY_VERTEX_EYES
      vec4 material=textureLod(specular,uv,level);
      if(material.a<254.5/255.0) amount=max(amount,material.a*255.0/254.0);
#endif
      vec3 glow=clamp(texel.rgb/max(texel.a,0.02),0.0,1.0)*vertexTint.rgb;
      emission=max(emission,pow(max(glow,vec3(0.0)),vec3(2.2))*amount);
   }
   float peak=max(emission.r,max(emission.g,emission.b));
   if(peak<0.01) return;
   vec4 clip=gbufferProjection*vec4(position,1.0);
   vec2 uv=clip.xy/max(abs(clip.w),0.001)*0.5+0.5;
   ivec2 tile=clamp(ivec2(uv*vec2(16,9)),ivec2(0),ivec2(15,8));
   imageStore(entitySourcePosition,tile,vec4(position,1.0));
   imageStore(entitySourceColor,tile,vec4(emission*LABPBR_EMISSION_STRENGTH*2.0,peak*LABPBR_EMISSION_STRENGTH*2.0));
}
#endif
