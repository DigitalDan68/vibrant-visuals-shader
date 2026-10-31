// Particle Rain 4.x splits rain.png into 16 mirrored square sprites and merges
// groups of four for heavy rain. Match their actual texels, not streak shape.
// See PigCart/particle-rain SpriteLoaderMixin and TextureUtil.
uniform sampler2D particleRainSource;
const ivec2 vvRainProbes[60] = ivec2[60](
   ivec2(28,30),
   ivec2(28,24),
   ivec2(0,0),
   ivec2(21,30),
   ivec2(21,24),
   ivec2(0,0),
   ivec2(19,9),
   ivec2(19,3),
   ivec2(0,0),
   ivec2(25,14),
   ivec2(26,20),
   ivec2(0,0),
   ivec2(13,11),
   ivec2(13,17),
   ivec2(0,0),
   ivec2(7,0),
   ivec2(14,20),
   ivec2(0,0),
   ivec2(7,31),
   ivec2(10,0),
   ivec2(0,0),
   ivec2(10,30),
   ivec2(17,18),
   ivec2(0,0),
   ivec2(19,31),
   ivec2(0,20),
   ivec2(0,0),
   ivec2(8,23),
   ivec2(22,16),
   ivec2(0,0),
   ivec2(4,24),
   ivec2(19,0),
   ivec2(0,0),
   ivec2(19,28),
   ivec2(7,11),
   ivec2(0,0),
   ivec2(21,1),
   ivec2(6,28),
   ivec2(0,0),
   ivec2(21,29),
   ivec2(20,3),
   ivec2(1,0),
   ivec2(13,19),
   ivec2(5,25),
   ivec2(0,0),
   ivec2(2,13),
   ivec2(2,19),
   ivec2(0,0),
   ivec2(28,29),
   ivec2(21,30),
   ivec2(0,0),
   ivec2(7,0),
   ivec2(7,31),
   ivec2(0,0),
   ivec2(4,24),
   ivec2(19,28),
   ivec2(0,0),
   ivec2(2,13),
   ivec2(13,21),
   ivec2(1,0));
vec4 vvRainReference(int sprite, ivec2 localPixel, int side) {
   int rows = textureSize(particleRainSource,0).y / side;
   int first = sprite < 16 ? sprite : (sprite-16)*4;
   vec4 result = vec4(0.0);
   for (int j=0;j<4;j++) {
      if (sprite < 16 && j>0) break;
      int index = first+j;
      ivec2 p = ivec2(index/rows,index%rows)*side + ivec2(side-1)-localPixel;
      vec4 sampleColor = texelFetch(particleRainSource,p,0);
      if (sampleColor.a>result.a) result=sampleColor;
   }
   float gray = max(result.r,max(result.g,result.b));
   return vec4(vec3(gray),result.a);
}
float vvParticleRainSprite(vec2 uv) {
   int side=textureSize(particleRainSource,0).x/2;
   if (side<1) return 0.0;
   ivec2 atlasSize=textureSize(gtexture,0);
   ivec2 origin=(ivec2(uv*vec2(atlasSize))/side)*side;
   for (int sprite=0;sprite<20;sprite++) {
      bool matches=true;
      for (int j=0;j<3;j++) {
         ivec2 probe=ivec2((vec2(vvRainProbes[sprite*3+j])+0.5)*float(side)/32.0);
         vec4 expected=vvRainReference(sprite,probe,side);
         // Empty reference probes must never identify arbitrary empty sprites.
         if (j==0 && expected.a<0.05) { matches=false; break; }
         vec4 actual=texelFetch(gtexture,clamp(origin+probe,ivec2(0),atlasSize-ivec2(1)),0);
         if (abs(actual.a-expected.a)>0.008 ||
             (expected.a>0.01 && any(greaterThan(abs(actual.rgb-expected.rgb),vec3(0.008))))) {
            matches=false; break;
         }
      }
      if (matches) return 1.0;
   }
   return 0.0;
}
