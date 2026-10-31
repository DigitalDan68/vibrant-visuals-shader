// Native animation envelopes: per-texel minimum/maximum over all frames.
// The current game atlas supplies the actual animated/interpolated frame.
uniform sampler2D animatedEmissionBounds;
float vvAnimationTexel(int row,vec2 spriteSize,vec2 uv,vec3 albedo) {
   vec2 atlasPixel=uv*vec2(textureSize(gtexture,0));
   vec2 local=fract(atlasPixel/spriteSize);
   ivec2 pixel=ivec2(clamp(floor(local*32.0),vec2(0.0),vec2(31.0)));
   vec4 low=texelFetch(animatedEmissionBounds,ivec2(pixel.x,pixel.y+row*32),0);
   vec4 high=texelFetch(animatedEmissionBounds,ivec2(pixel.x+32,pixel.y+row*32),0);
   float range=high.a-low.a;
   if(range<0.003 || any(lessThan(albedo,low.rgb-vec3(0.025))) || any(greaterThan(albedo,high.rgb+vec3(0.025)))) return 0.0;
   float brightness=max(albedo.r,max(albedo.g,albedo.b));
   return smoothstep(0.08,0.80,clamp((brightness-low.a)/max(range,0.003),0.0,1.0));
}
float vvAnimatedEmission(float id,vec2 uv,vec3 albedo) {
   if(id==42016.0) return vvAnimationTexel(0,vec2(16.0,16.0),uv,albedo);
   if(id==42017.0) return vvAnimationTexel(1,vec2(16.0,16.0),uv,albedo);
   if(id==42002.0) return vvAnimationTexel(2,vec2(16.0,16.0),uv,albedo);
   if(id==42003.0) return vvAnimationTexel(3,vec2(16.0,16.0),uv,albedo);
   if(id==42001.0) return vvAnimationTexel(4,vec2(16.0,16.0),uv,albedo);
   if(id==42014.0) return vvAnimationTexel(5,vec2(16.0,16.0),uv,albedo);
   if(id==43111.0) return vvAnimationTexel(6,vec2(16.0,16.0),uv,albedo);
   if(id==43112.0) return vvAnimationTexel(7,vec2(16.0,16.0),uv,albedo);
   if(id==43113.0) return vvAnimationTexel(8,vec2(16.0,16.0),uv,albedo);
   if(id==10068.0) return max(vvAnimationTexel(9,vec2(16.0,16.0),uv,albedo),vvAnimationTexel(10,vec2(32.0,32.0),uv,albedo));
   if(id==10072.0) return max(vvAnimationTexel(11,vec2(16.0,16.0),uv,albedo),vvAnimationTexel(12,vec2(16.0,16.0),uv,albedo));
   if(id==10076.0) return max(vvAnimationTexel(13,vec2(16.0,16.0),uv,albedo),vvAnimationTexel(14,vec2(16.0,16.0),uv,albedo));
   if(id==10652.0) return max(vvAnimationTexel(15,vec2(16.0,16.0),uv,albedo),vvAnimationTexel(16,vec2(16.0,16.0),uv,albedo));
   if(id==10656.0) return max(vvAnimationTexel(17,vec2(16.0,16.0),uv,albedo),vvAnimationTexel(18,vec2(16.0,16.0),uv,albedo));
   if(id==43001.0) return vvAnimationTexel(19,vec2(16.0,16.0),uv,albedo);
   if(id==43002.0) return vvAnimationTexel(20,vec2(16.0,16.0),uv,albedo);
   if(id==30020.0) return vvAnimationTexel(21,vec2(16.0,16.0),uv,albedo);
   if(id==42018.0) return max(vvAnimationTexel(22,vec2(16.0,16.0),uv,albedo),vvAnimationTexel(23,vec2(16.0,16.0),uv,albedo));
   return 1.0;
}
