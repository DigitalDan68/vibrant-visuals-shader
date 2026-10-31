uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;
#include "/common/getShadowDistortion.glsl"
#include "/common/cloudShadows.glsl"

float getLightStrength(float diffuse, float skyLight, vec3 feetPos) {
   vec3 pos = feetPos;
   float posDistance = squaredLength(pos);
   vec4 shadowView   = shadowModelView * vec4(pos, 1.0);
   vec4 shadowClip   = shadowProjection * shadowView;

   shadowClip.xyz = getShadowDistortion(shadowClip.xyz);

   vec3 shadowUV = clip2screen(shadowClip);

   // Evaluate derivatives before lighting-dependent returns. Each depth texel
   // represents a different point on a sloped receiver, including flat terrain.
   vec3 dx = dFdx(shadowUV), dy = dFdy(shadowUV);
   float determinant = dx.x*dy.y-dx.y*dy.x;
   vec2 depthGradient = vec2(0.0);
   if (abs(determinant)>1e-12)
      depthGradient = vec2(dy.y*dx.z-dx.y*dy.z,dx.x*dy.z-dy.x*dx.z)/determinant;

   vec2 lookupUV = shadowUV.xy;
      // Pixelize the lookup, not the receiver depth. Snapping world XYZ can
      // move the point into its own block and destroy the surface derivatives.
      vec3 worldPos = feet2world(feetPos);
      vec3 pixelWorld = bandify(worldPos,16.0);
      // Keep the snapped lookup on the receiver plane, avoiding self-shadow
      // artifacts from moving the sample into a solid block.
      vec3 planeNormal = cross(dFdx(feetPos),dFdy(feetPos));
      float planeLength = length(planeNormal);
      if (planeLength>0.000001) {
         planeNormal/=planeLength;
         pixelWorld-=planeNormal*dot(pixelWorld-worldPos,planeNormal);
      }
      vec3 pixelPos = world2feet(pixelWorld);
      vec4 pixelClip = shadowProjection*shadowModelView*vec4(pixelPos,1.0);
      pixelClip.xyz = getShadowDistortion(pixelClip.xyz);
      vec3 snappedShadowUV = clip2screen(pixelClip);
      lookupUV = snappedShadowUV.xy;

   // Zero skylight/diffuse cannot receive sun or cloud shadows.
   diffuse *= rescale(skyLight, 0.3137, 0.6235);
   if (diffuse == 0.0) return 0.0;
   #if defined CLOUD_SHADOWS && defined OVERWORLD
      diffuse *= cloudTransmission(feetPos);
   #endif
   #ifdef GBUFFERS_HAND
      return 0.5*diffuse;
   #endif
   if (diffuse <= 0.0) return diffuse;

   if (posDistance < SHADOW_MAX_DIST_SQUARED &&
      diffuse    > 0.0 && shadowUV.z > 0.0 && shadowUV.z < 1.0 &&
      lookupUV.s > 0.0 && lookupUV.s < 1.0 &&
      lookupUV.t > 0.0 && lookupUV.t < 1.0)
   {
      float shadowFade  = 1.0-smoothstep(0.64*SHADOW_MAX_DIST_SQUARED,SHADOW_MAX_DIST_SQUARED,posDistance);
      float visibility=0.0;
      float glassShade=0.0;
      float resolution = float(shadowMapResolution);
      vec2 pixel = lookupUV*resolution-0.5;
      vec2 base = floor(pixel);
      vec2 fraction = fract(pixel);
      // A small texel-scaled slope allowance handles rasterized receiver depth
      // without widening the shadow edge or depending on time of day.
      float slopeBias=min(0.00015,0.5*max(abs(depthGradient.x),abs(depthGradient.y))/resolution);
      float bias = (0.00002+slopeBias)*SHADOW_DEPTH_BIAS_SCALE;
      for (int tap=0;tap<4;++tap) {
         vec2 corner = vec2(float(tap%2),float(tap/2));
         vec2 uv = (base+corner+0.5)/resolution;
         vec2 weights = mix(vec2(1.0)-fraction,fraction,corner);
         float weight = weights.x*weights.y;
         float receiverDepth = snappedShadowUV.z+dot(depthGradient,uv-lookupUV)-bias;
         float front=texture2D(shadowtex0,uv).x;
         float opaque=texture2D(shadowtex1,uv).x;
         bool glass=texture2D(shadowcolor0,uv).a>0.5;
         float depth=glass ? opaque : min(front,opaque);
         visibility+=step(receiverDepth,depth)*weight;
         glassShade+=(glass && receiverDepth>front ? 0.7 : 1.0)*weight;
      }
      // Retain sub-texel coverage. Re-thresholding the filtered result makes
      // the entire edge pixel pop between lit/shadowed as the map moves.
      // The four taps still cover only the native one-texel footprint.
      visibility=clamp(visibility,0.0,1.0);
      return diffuse*mix(1.0,visibility*glassShade,shadowFade);
   }

   return diffuse;
}
vec3 getGlassShadowTint(vec3 feetPos) {
#ifdef COLORED_GLASS_SHADOWS
   vec4 clip = shadowProjection*shadowModelView*vec4(feetPos,1.0);
   clip.xyz = getShadowDistortion(clip.xyz);
   vec3 uv = clip2screen(clip);
   if (squaredLength(feetPos) < SHADOW_MAX_DIST_SQUARED && uv.z < 1.0 && all(greaterThan(uv.xy,vec2(0.0))) && all(lessThan(uv.xy,vec2(1.0)))) {
      float front = texture2D(shadowtex0,uv.xy).x;
      float opaque = texture2D(shadowtex1,uv.xy).x;
      vec4 transmission = texture2D(shadowcolor0,uv.xy);
      if (uv.z > front+0.0006*SHADOW_DEPTH_BIAS_SCALE && uv.z <= opaque+0.0006*SHADOW_DEPTH_BIAS_SCALE && transmission.a > 0.5) {
         vec3 tint = transmission.rgb/max(max(transmission.r,max(transmission.g,transmission.b)),0.001);
         return mix(vec3(1.0),tint,1.0-squaredLength(feetPos)*INV_SHADOW_MAX_DIST_SQUARED);
      }
   }
#endif
   return vec3(1.0);
}
