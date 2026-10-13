#ifndef VV_BLOOM_SAMPLING
#define VV_BLOOM_SAMPLING
// Explicit bilinear reconstruction: Iris buffers may use nearest sampling.
vec3 vvSmoothBloom(vec2 uv) {
   vec2 size=vec2(textureSize(colortex4,0));
   vec2 position=clamp(uv,vec2(0.0),vec2(1.0))*size-0.5;
   vec2 pixel=floor(position), blend=fract(position);
   vec2 a=(clamp(pixel,vec2(0.0),size-1.0)+0.5)/size;
   vec2 b=(clamp(pixel+1.0,vec2(0.0),size-1.0)+0.5)/size;
   return mix(mix(texture2D(colortex4,a).rgb,texture2D(colortex4,vec2(b.x,a.y)).rgb,blend.x),
              mix(texture2D(colortex4,vec2(a.x,b.y)).rgb,texture2D(colortex4,b).rgb,blend.x),blend.y);
}
#endif