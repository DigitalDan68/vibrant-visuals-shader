#include "/common/dry_biome_fog.glsl"
#include "/common/water_optics.glsl"
uniform sampler2D waterCausticTex;
uniform sampler2D colortex2;
uniform sampler2D colortex4;
#include "/common/bloom_sampling.glsl"
uniform float viewWidth, viewHeight, frameTimeCounter;
uniform ivec2 eyeBrightnessSmooth;
uniform vec3 skyColor, sunPosition;
#ifndef THE_NETHER
uniform vec3 fogColor;
#endif
uniform float rainStrength;
uniform float thunderStrength;
#if defined OVERWORLD || defined THE_SIFT
uniform int worldTime;
#endif
uniform float blindness, darknessFactor;
#if defined ENABLE_SHADOWS && (defined OVERWORLD || defined THE_SIFT)
uniform mat4 shadowModelView, shadowProjection;
uniform sampler2D shadowtex1;
#include "/common/getShadowDistortion.glsl"
#endif
vec3 vvOpaquePosition(vec2 uv) {
   float depth = texture2D(depthtex1, uv).x;
   // Native chunks own their water-bed depth. The secondary buffer is a
   // fallback for absent chunks, not a competing approximation inside them.
   if (depth < 1.0) return screen2view(uv,depth);
   #ifdef DISTANT_HORIZONS
      float lodDepth = texture2D(dhDepthTex1, uv).x;
      if (lodDepth < 1.0) {
         vec4 pos = dhProjectionInverse * vec4(screen2ndc(vec3(uv, lodDepth)), 1.0);
         vec3 lodPosition = pos.xyz/pos.w;
         return lodPosition;
      }
   #endif
   if (depth >= 1.0) return normalize(screen2view(uv,0.999)) * 96.0;
   return screen2view(uv, depth);
}
float vvAmbientOcclusion(vec2 uv, vec3 pos) {
   float occlusion = 0.0;
   vec3 planeNormal = cross(dFdx(pos), dFdy(pos));
   planeNormal /= max(length(planeNormal), 0.00001);
   if (dot(planeNormal, -pos) < 0.0) planeNormal = -planeNormal;
   #if SSAO_SAMPLES > 0
      int aoSamples = SSAO_SAMPLES;
      vec2 radius = vec2(1.0 / viewWidth, 1.0 / viewHeight) * clamp(240.0 / max(-pos.z, 1.0), 1.5, 16.0);
      for (int i = 0; i < aoSamples; i++) {
         float angle = float(i) * 6.2831853 / float(aoSamples);
         vec2 sampleUV = clamp(uv + vec2(cos(angle), sin(angle)) * radius, 0.0, 1.0);
         vec3 other = vvOpaquePosition(sampleUV);
         vec3 delta = other - pos;
         float distanceToSample = length(delta);
         float hemisphere = smoothstep(0.05, 0.3, dot(planeNormal, delta / max(distanceToSample, 0.00001)));
         occlusion += hemisphere * smoothstep(0.06, 0.35, other.z - pos.z)
                    * (1.0 - smoothstep(0.4, 1.5, distanceToSample));
      }
      occlusion /= float(aoSamples);
   #endif
   return 1.0 - SSAO_STRENGTH * occlusion;
}
// Sunset-only grading fades smoothly across the evening horizon crossing.
float vvSunsetWeight() {
#ifdef OVERWORLD
   float sunUp = normalize(view2eye(sunPosition)).y;
   return exp(-pow(sunUp/0.22,2.0))*smoothstep(9500.0,11000.0,float(worldTime))
          *(1.0-smoothstep(13500.0,15000.0,float(worldTime)))*(1.0-rainStrength);
#else
   return 0.0;
#endif
}
vec3 vvBloom(vec2 uv) {
   vec3 light = vec3(0.0);
   if (BLOOM_STRENGTH > 0.0) {
      vec2 radius = vec2(2.0 / viewWidth, 2.0 / viewHeight) * BLOOM_RADIUS;
      // Horizontal filtering happens at half resolution in composite2.
      // Five vertical taps finish the same separable Gaussian footprint.
      for (int y=-2;y<=2;++y) {
         float weight = y == 0 ? 1.0 : (abs(y) == 1 ? 0.60653066 : 0.13533528);
         light += vvSmoothBloom(clamp(uv+vec2(0.0,float(y)*radius.y),0.0,1.0))*weight;
      }
      float bloomMultiplier = 1.0;
#ifdef OVERWORLD
      float sunUp = normalize(view2eye(sunPosition)).y;
      float dusk = exp(-pow(sunUp/0.18,2.0))*step(10000.0,float(worldTime))*(1.0-step(15000.0,float(worldTime)));
      bloomMultiplier = mix(1.0,SUNSET_BLOOM_BOOST,dusk*(1.0-rainStrength));
#endif
      light *= BLOOM_STRENGTH*bloomMultiplier/2.48373188;
   }
   return light;
}
float vvFogNoise(vec3 p);
float vvSunVisibility(vec3 world);
float vvForwardPhase(float cosine) {
   float g = 0.55;
   return (1.0-g*g)/pow(max(1.0+g*g-2.0*g*cosine,0.01),1.5);
}
vec3 vvVolumetricsBetween(vec3 scene,vec3 airStart,vec3 viewPos) {
#if COLOR_GRADING == 1 && VOLUMETRIC_SAMPLES > 0 && defined ENABLE_SHADOWS && defined OVERWORLD && defined ENABLE_FOG
   if (VOLUMETRIC_STRENGTH <= 0.0) return scene;
   // Atmospheric sun haze belongs to skylit air. Avoid marching outdoor fog
   // and shadow samples over every visible cave surface when no sky reaches us.
   float atmosphereAccess = clamp(float(eyeBrightnessSmooth.y)/240.0,0.0,1.0);
   if (isEyeInWater == 1 && length(airStart)>0.001) {
      vec4 surfaceTint = texture2D(colortex2,texUV);
      if(surfaceTint.a>0.5)
         atmosphereAccess=max(atmosphereAccess,clamp((surfaceTint.a-0.6)/0.4,0.0,1.0));
   }
   float atmosphereWeight = smoothstep(0.02,0.25,atmosphereAccess);
   if(atmosphereWeight<0.001) return scene;

   float airLength = length(viewPos-airStart);
   if(airLength<0.001) return scene;
   float range = min(airLength,160.0);
   vec3 direction = (viewPos-airStart)/airLength;
   float sunUp = normalize(view2eye(sunPosition)).y;
   float daylight = smoothstep(-0.02,0.12,sunUp)*(1.0-rainStrength);
   float phase = vvForwardPhase(dot(direction,normalize(sunPosition)));
   vec3 sunlight = mix(vec3(1.0,0.34,0.08),vec3(1.0,0.93,0.8),smoothstep(0.0,0.5,sunUp));
   float twilight = 0.0;
#ifdef TWILIGHT_RAYS
   twilight = smoothstep(-0.025,0.035,sunUp)*(1.0-smoothstep(0.12,0.35,sunUp))*TWILIGHT_RAY_STRENGTH;
#endif
   vec3 ambient = pow(max(isEyeInWater == 1 ? skyColor : vvDryBiomeFogColor(fogColor),vec3(0.0)),vec3(2.2))*0.35;
   int raySamples = VOLUMETRIC_SAMPLES;
   float stepLength = range/float(raySamples);
   float transmission = 1.0;
   vec3 radiance = vec3(0.0);
   vec3 twilightRadiance = vec3(0.0);
   for (int i=0;i<raySamples;++i) {
      vec3 world = view2feet(airStart+direction*((float(i)+0.5)*stepLength))+cameraPosition;
      float density = FOG_DENSITY*atmosphereWeight*mix(0.75,1.25,vvFogNoise(world*0.025));
      if (isEyeInWater == 0) density *= mix(1.0,8.0,max(clamp(vvDryBiomeDust,0.0,1.0),clamp(vvPaleGarden,0.0,1.0)));
#ifdef HEIGHT_FOG
      density *= clamp(exp(-(world.y-FOG_HEIGHT)/48.0),0.25,1.5);
#endif
      float segment = exp(-stepLength*density*VOLUMETRIC_STRENGTH/192.0);
      float sunVisibility = vvSunVisibility(world);
      vec3 light = ambient+sunlight*daylight*phase*sunVisibility*0.18;
      // Ray visibility is independent of extinction: brighter beams do not obscure the scene.
      float rayPhase = 0.5+min(phase,4.0);
      float rayFringe = 0.0;
      if (twilight > 0.0 && sunVisibility < 0.5) {
         // Very faint illumination at shadow boundaries; no artificial repeating stripes.
         rayFringe = 0.055*0.25*(vvSunVisibility(world+vec3(0.3,0.0,0.0))
                    +vvSunVisibility(world-vec3(0.3,0.0,0.0))
                    +vvSunVisibility(world+vec3(0.0,0.0,0.3))
                    +vvSunVisibility(world-vec3(0.0,0.0,0.3)));
      }
      twilightRadiance += transmission*sunlight*twilight*daylight*rayPhase*(sunVisibility+rayFringe)
                        *density*stepLength*0.015;
      radiance += transmission*(1.0-segment)*light;
      transmission *= segment;
   }
   twilightRadiance /= vec3(1.0)+twilightRadiance/0.45;
   return scene*transmission+radiance+twilightRadiance;
#else
   return scene;
#endif
}
vec3 vvToneMap(vec3 linearColor) {
   float exposure = EXPOSURE;
   float sunset = vvSunsetWeight();
   #ifdef AUTO_EXPOSURE
      // The preceding composite pass meters scene luminance and smooths it
      // through a persistent one-pixel HDR history buffer.
      float adapted = texture2D(colortex3, vec2(0.5)).r;
      float exposureCeiling = mix(EXPOSURE_MAX,min(EXPOSURE_MAX,1.1),sunset);
      exposure *= clamp(adapted, EXPOSURE_MIN, max(EXPOSURE_MIN, exposureCeiling));
   #endif
   vec3 sunsetGrade = mix(vec3(1.0),vec3(1.0,0.82,0.62),sunset);
   vec3 exposed = max(linearColor * sunsetGrade * exposure * mix(1.0,0.75,sunset), vec3(0.0));
   float peak = max(exposed.r, max(exposed.g, exposed.b));
   // Neutral shoulder preserves midtones and saturated material hues.
   exposed = labHighlightShoulder(exposed, 0.65);
   return pow(exposed, vec3(1.0 / 2.2));
}

float vvFogNoise(vec3 p);
vec3 vvSandSpecks(vec3 scene,vec3 viewPos) {
#if defined OVERWORLD && defined ENABLE_FOG
   float storm=clamp(vvDryBiomeDust,0.0,1.0);
   float outside=smoothstep(0.1,0.5,float(eyeBrightnessSmooth.y)/240.0);
   if (storm<0.001 || outside<0.001 || isEyeInWater!=0) return scene;
   float limit=min(length(viewPos),28.0);
   if (limit<0.2) return scene;
   vec3 ray=normalize(view2feet(viewPos));
   vec3 wind=normalize(vec3(1.0,0.08,0.45));
   vec3 axis=normalize(cross(wind,vec3(0.0,1.0,0.0)));
   vec3 vertical=cross(axis,wind);
   float facing=dot(ray,wind);
   if (abs(facing)<0.025) return scene;
   float thunder=clamp(thunderStrength,0.0,1.0);
   float windTime=frameTimeCounter*mix(1.0,2.0,thunder);
   float drift=windTime*4.0;
   float origin=dot(cameraPosition,wind)-drift;
   float first=floor(origin/1.8);
   vec3 sand=vvStormSandTint()*0.8*max(dot(fogColor,vec3(0.2126,0.7152,0.0722)),0.035);
   for(int layer=0;layer<16;++layer) {
      float plane=first+(facing>0.0 ? float(layer)+1.0 : -float(layer));
      float distance=(plane*1.8-origin)/facing;
      if(distance<=0.2 || distance>=limit) continue;
      vec3 hit=cameraPosition+ray*distance;
      vec2 position=vec2(dot(hit,axis),dot(hit,vertical))-vec2(windTime*0.15,windTime*0.08);
      vec2 cell=floor(position);
      float seed=fract(sin(dot(cell,vec2(12.9898,78.233))+plane*37.13)*43758.5453);
      if(seed<mix(0.89,0.68,thunder)) continue;
      vec2 center=vec2(fract(seed*17.31),fract(seed*43.71))*0.8+0.1;
      // Camera-facing square centered on a drifting world-space grain.
      vec3 grain=wind*(plane*1.8+drift)
                +axis*(cell.x+center.x+windTime*0.15)
                +vertical*(cell.y+center.y+windTime*0.08);
      vec3 grainView=feet2view(grain-cameraPosition);
      vec3 viewRay=normalize(viewPos);
      if (grainView.z>=-0.1 || abs(viewRay.z)<0.001) continue;
      float grainDistance=grainView.z/viewRay.z;
      if(grainDistance<=0.2 || grainDistance>=limit) continue;
      vec2 delta=(viewRay*grainDistance-grainView).xy/0.04;
      float edge=max(abs(delta.x),abs(delta.y));
      float speck=(1.0-smoothstep(0.85,1.0,edge))*exp(-grainDistance/22.0);
      scene=mix(scene,sand,speck*storm*outside*0.7);
   }
#endif
   return scene;
}

vec3 vvVolumetrics(vec3 scene,vec3 viewPos) {
   return vvSandSpecks(vvVolumetricsBetween(scene,vec3(0.0),viewPos),viewPos);
}
float vvSunVisibility(vec3 world) {
#if defined ENABLE_SHADOWS && (defined OVERWORLD || defined THE_SIFT)
   vec4 clip = shadowProjection*shadowModelView*vec4(world-cameraPosition,1.0);
   clip.xyz = getShadowDistortion(clip.xyz);
   vec3 uv = clip2screen(clip);
   if (any(lessThanEqual(uv,vec3(0.0))) || any(greaterThanEqual(uv,vec3(1.0)))) return 1.0;
   float visibility=step(uv.z-0.0006*SHADOW_DEPTH_BIAS_SCALE,texture2D(shadowtex1,uv.xy).x);
   vec3 edge=min(uv,vec3(1.0)-uv);
   float coverage=smoothstep(0.0,0.04,min(edge.x,min(edge.y,edge.z)));
   // Unknown sky outside the shadow map stays lit; fade only its occlusion.
   return mix(1.0,visibility,coverage);
#else
   return 0.0;
#endif
}
float vvCausticPattern(vec3 worldPosition) {
   ivec2 atlasSize = textureSize(waterCausticTex,0);
   float width = float(max(atlasSize.x,1));
   float frames = float(max(atlasSize.y/max(atlasSize.x,1),1));
   // Bedrock renderer caustics: 64 frames, 0.09 seconds per frame.
   float frame = mod(floor(frameTimeCounter*CAUSTICS_SPEED/0.09),frames);
   // Match Bedrock's inverse scale convention and retain the original texels.
   // Anchor light cells at block texture pixel centers before scaling the atlas.
   // All animation frames therefore share the same world-space 16x16 grid.
   vec2 gridPosition=(floor(worldPosition.xz*16.0)+0.5)/16.0;
   vec2 tile = (floor(fract(gridPosition/max(CAUSTICS_SCALE,0.01))*width)+0.5)/width;
   vec2 uv = vec2(tile.x,(tile.y+frame)/frames);
   float value = texture2DLod(waterCausticTex,uv,0.0).r;
   return pow(max(value,0.0),CAUSTICS_POWER);
}
vec3 vvCausticSunColor() {
#ifdef OVERWORLD
   float elevation = max(normalize(view2eye(sunPosition)).y,0.0);
   float evening = smoothstep(9500.0,11000.0,float(worldTime))*(1.0-smoothstep(15000.0,17000.0,float(worldTime)));
   vec3 lowSun = mix(vec3(1.0,0.78,0.52),vec3(1.0,0.38,0.12),evening);
   return mix(lowSun,vec3(1.0),smoothstep(0.08,0.65,elevation));
#else
   return vec3(1.0);
#endif
}

#ifdef THE_END
uniform float endFlashIntensity;
uniform vec3 endFlashPosition;
#endif
#ifdef THE_END
uniform sampler2D endSkyTex;
#endif
vec3 vvEndSky(vec3 direction) {
#ifdef THE_END
   // Map the native repeating End texture onto six sky faces. Dominant-axis
   // projection keeps the texture finite at the poles and across the horizon.
   vec3 axis = abs(direction);
   vec2 uv;
   if (axis.x >= axis.y && axis.x >= axis.z)
      uv = direction.zy / max(axis.x,0.0001);
   else if (axis.y >= axis.z)
      uv = direction.xz / max(axis.y,0.0001);
   else
      uv = direction.xy / max(axis.z,0.0001);
   // Original End sky tiles the texture sixteen times across each face.
   // Explicit wrapping also works when the custom sampler clamps its edges.
   vec2 tiledUV = fract((uv*0.5+0.5)*16.0);
   vec3 textureColor = texture2D(endSkyTex,tiledUV).rgb;
   // Vanilla renders this texture with a dim grey vertex tint.
   return pow(textureColor*0.16,vec3(2.2))*END_SKY_GLOW;
#else
   return vec3(0.0);
#endif
}

float vvFogNoise(vec3 p) {
   vec3 cell = floor(p);
   vec3 f = fract(p); f = f*f*(3.0-2.0*f);
   float n = dot(cell, vec3(1.0, 57.0, 113.0));
   vec4 low = fract(sin(n + vec4(0.0, 1.0, 57.0, 58.0)) * 43758.5453);
   vec4 high = fract(sin(n + vec4(113.0, 114.0, 170.0, 171.0)) * 43758.5453);
   float a = mix(mix(low.x,low.y,f.x),mix(low.z,low.w,f.x),f.y);
   float b = mix(mix(high.x,high.y,f.x),mix(high.z,high.w,f.x),f.y);
   return mix(a,b,f.z);
}
vec3 vvDimensionFog(vec3 scene, vec3 viewPosition) {
   #if COLOR_GRADING == 1 && defined DIMENSION_VOLUMETRICS && VOLUMETRIC_SAMPLES > 0 && defined ENABLE_FOG
      #if defined THE_END || defined THE_SIFT
         if (DIMENSION_FOG_STRENGTH <= 0.0 || isEyeInWater != 0 || blindness > 0.0 || darknessFactor > 0.0) return scene;
         #ifdef THE_NETHER
            float range = NETHER_FOG_DISTANCE;
            float start = 8.0;
            vec3 fogTint = fogColor;
            float falloff = 0.4;
         #elif defined THE_SIFT
            float range = SIFT_FOG_DISTANCE;
            float start = 16.0;
            vec3 fogTint = mix(vec3(0.64,0.76,0.7),vec3(0.035,0.065,0.15),siftNightWeight(float(worldTime)));
            float falloff = 0.65;
         #else
            float range = END_FOG_DISTANCE;
            float start = 16.0;
            vec3 fogTint = mix(fogColor, vec3(0.19,0.13,0.28),0.7);
            float falloff = 0.6;
         #endif
         float distanceToSurface = min(length(viewPosition), range*3.0);
         if (distanceToSurface <= start) return scene;
         vec3 direction = normalize(viewPosition);
         int dimensionSamples = VOLUMETRIC_SAMPLES;
         float stepLength = (distanceToSurface-start) / float(dimensionSamples);
         float transmission = 1.0;
         vec3 scattering = vec3(0.0);
         vec3 radiance = pow(max(fogTint,vec3(0.0)),vec3(2.2));
         for (int i=0; i<dimensionSamples; i++) {
            float distance = start + (float(i)+0.5)*stepLength;
            vec3 world = feet2world(view2feet(direction*distance));
            // Slowly moving, world-anchored density volumes: no screen-space overlay.
            float noise = vvFogNoise(world*0.035 + vec3(frameTimeCounter*0.007,0.0,0.0));
            float density = mix(0.55,1.45,noise);
            #ifdef THE_END
               density *= 0.8*(0.7 + 0.3*exp(-abs(world.y-64.0)/48.0));
            #endif
            #ifdef THE_SIFT
               // Dense low mist and lighter high-air wisps, anchored to world height.
               density *= clamp(exp(-(world.y-SIFT_MIST_HEIGHT)/56.0),0.25,1.5);
            #endif
            float segment = exp(-stepLength*density*FOG_DENSITY*DIMENSION_FOG_STRENGTH / max(range*falloff,1.0));
            vec3 localRadiance = radiance;
#if defined THE_END && defined END_FLASH_SKY
            // Native flashes illuminate mist only, without a sky sprite or rift.
            float flash = max(endFlashIntensity,0.0)*END_FLASH_STRENGTH;
            localRadiance += vec3(0.65,0.22,1.0)*flash*0.75;
#endif
            scattering += transmission*(1.0-segment)*localRadiance;
            transmission *= segment;
            if (transmission < 0.005) break; // Opaque haze: farther samples contribute negligibly.
         }
         return scene*transmission + scattering;
      #endif
   #endif
   return scene;
}

vec3 vvSiftSky(vec3 direction) {
   float ribbon = 0.5+0.5*sin(direction.x*3.0+direction.z*4.0+frameTimeCounter*0.015);
   vec3 pastel = mix(vec3(0.3,0.64,0.55),vec3(0.72,0.44,0.53),ribbon);
   float horizon = 1.0-smoothstep(0.0,0.65,abs(direction.y));
   vec3 daySky = mix(pastel,vec3(0.72,0.8,0.68),horizon*0.65);
#ifdef THE_SIFT
   vec3 nightSky = mix(vec3(0.012,0.025,0.075),vec3(0.04,0.075,0.17),horizon);
   daySky = mix(daySky,nightSky,siftNightWeight(float(worldTime)));
#endif
   return daySky*SIFT_SKY_GLOW;
}
// Camera-facing planes give motes the flat square silhouette of game particles.
float vvPlaneMote(vec3 origin, vec3 direction, vec3 center, float radius, float range) {
   vec3 normal = normalize(view2eye(vec3(0.0,0.0,-1.0)));
   float denominator = dot(direction,normal);
   if (abs(denominator) < 0.00001) return 0.0;
   float distance = dot(center-origin,normal)/denominator;
   if (distance <= 0.5 || distance >= range) return 0.0;
   vec3 offset = origin+direction*distance-center;
   vec3 right = normalize(view2eye(vec3(1.0,0.0,0.0)));
   vec3 up = normalize(view2eye(vec3(0.0,1.0,0.0)));
   vec2 local = abs(vec2(dot(offset,right),dot(offset,up)));
   return 1.0-smoothstep(radius*0.85,radius,max(local.x,local.y));
}
vec3 vvSiftAtmosphere(vec3 viewPosition) {
   vec3 result = vec3(0.0);
#if COLOR_GRADING == 1 && defined THE_SIFT && VOLUMETRIC_SAMPLES > 0
   if (isEyeInWater != 0) return result;
   float night = siftNightWeight(float(worldTime));
   float range = min(length(viewPosition),128.0);
   vec3 direction = normalize(viewPosition);
   vec3 worldOrigin = feet2world(view2feet(vec3(0.0)));
   vec3 worldDirection = normalize(view2eye(direction));
   int siftSamples = VOLUMETRIC_SAMPLES*2;
   float stepLength = range/float(siftSamples);
   vec3 previousCell = vec3(1e20);
   vec3 siftRayRadiance = vec3(0.0);
   for (int i=0;i<siftSamples;++i) {
      float distance = (float(i)+0.5)*stepLength;
      vec3 world = worldOrigin+worldDirection*distance;
      // Drifting projected cloud openings keep thin shafts parallel along their length.
      vec3 axis = normalize(vec3(-0.45,1.0,0.25));
      vec2 column = vec2(world.x+0.45*world.y,world.z-0.25*world.y);
      vec2 drift = vec2(frameTimeCounter*0.28,frameTimeCounter*0.13);
      vec2 movingColumn = column+drift;
      float stripe = 0.5+0.5*sin(movingColumn.x*0.65+sin(movingColumn.y*0.12)*0.65);
      float core = smoothstep(0.965,0.998,stripe);
      float fringe = smoothstep(0.90,0.985,stripe)*0.055;
      float cloud = vvFogNoise(vec3((column+drift*1.7)*0.045,0.0));
      float cloudOpening = smoothstep(0.25,0.72,cloud);
      float beams = (core+fringe)*mix(0.08,1.0,cloudOpening);
      float visibility = 1.0;
#ifdef ENABLE_SHADOWS
      vec4 clip = shadowProjection*shadowModelView*vec4(world-cameraPosition,1.0);
      clip.xyz = getShadowDistortion(clip.xyz);
      vec3 uv = clip2screen(clip);
      if (all(greaterThan(uv,vec3(0.0))) && all(lessThan(uv,vec3(1.0))))
         visibility = step(uv.z-0.001*SHADOW_DEPTH_BIAS_SCALE,texture2D(shadowtex1,uv.xy).x);
#endif
      float phase = 0.7+0.3*pow(max(dot(worldDirection,axis),0.0),3.0);
      siftRayRadiance += mix(vec3(0.95,0.62,0.48),vec3(0.28,0.4,0.65),night)*beams*visibility*phase*SIFT_LIGHT_SHAFTS*stepLength*0.025*exp(-distance/80.0);
      // Analytic luminous motes; terminate at scene depth rather than drawing over terrain.
      vec3 cell = floor(world/8.0);
      float hash = fract(sin(dot(cell,vec3(13.1,71.7,29.3)))*43758.5453);
      vec3 mote = (cell+vec3(0.2+hash*0.6,0.5+0.2*sin(frameTimeCounter*0.25+hash*20.0),0.8-hash*0.6))*8.0;
      float along = dot(mote-worldOrigin,worldDirection);
      float spark = vvPlaneMote(worldOrigin,worldDirection,mote,0.055,range);
      if (any(notEqual(cell,previousCell)) && along > 1.0 && along < range && hash > mix(0.45,0.05,night))
         result += mix(mix(vec3(0.4,1.0,0.85),vec3(1.0,0.6,0.85),hash),vec3(1.0),night)*mix(1.0,3.0,night)*spark*SIFT_MOTES*exp(-along/48.0);
      previousCell = cell;
   }
   result += siftRayRadiance/(vec3(1.0)+siftRayRadiance/0.9);
#endif
   return result;
}

// Integrate only the water segment of the camera ray. Low uses homogeneous fog.
// Keep the biome hue visible in shallow water without an opaque surface layer.
// This tints transmission; reflected sky and celestial highlights retain their colors.
vec3 vvWaterSurfaceTint(vec3 scene) {
   vec4 data = texture2D(colortex2,texUV);
   if (data.a <= 0.5) return scene;
   vec3 tint = pow(waterStyledTint(data.rgb),vec3(2.2));
   float peak = max(tint.r,max(tint.g,tint.b));
   if (peak < 0.0001) return scene;
   return scene*mix(vec3(1.0),tint/peak,0.15);
}
vec3 vvWaterFog(vec3 scene, vec3 startPosition, vec3 endPosition) {
#ifdef WATER_VOLUMETRICS
   float distanceInWater = min(length(endPosition-startPosition), 96.0);
   if (WATER_FOG_DENSITY <= 0.0 || distanceInWater < 0.001) return scene;
   endPosition = startPosition + normalize(endPosition-startPosition)*distanceInWater;
   vec4 waterTintData = texture2D(colortex2,texUV);
   // Visible water carries its actual biome vertex tint; underwater fog supplies
   // the local game's water fog color when no surface crosses this pixel.
   // Underwater tint must be local and independent of visible surface coverage.
   // Surface metadata varies with plants, waves and view direction.
   vec3 biomeTint = isEyeInWater == 1 ? fogColor : (waterTintData.a > 0.5 ? waterTintData.rgb : fogColor);
   if (isEyeInWater == 0 && waterTintData.a < 0.5) biomeTint = vec3(0.25,0.46,0.75);
   // One concentration-driven medium on both sides of the surface.
   float submergedDensity=isEyeInWater == 1 ? 1.7 : 1.0;
   vec3 extinction=waterTintExtinction(biomeTint)*WATER_FOG_DENSITY*2.5*submergedDensity;
   vec3 scatterCoefficient=waterScatteringCoefficients()*WATER_FOG_DENSITY*1.40*submergedDensity;
   // Water metadata preserves local skylight and block light even above ground.
   float waterSky = isEyeInWater == 0 && waterTintData.a > 0.5 ? clamp((waterTintData.a-0.6)/0.4,0.0,1.0) : clamp(float(eyeBrightnessSmooth.y)/240.0,0.0,1.0);
   float waterBlock = isEyeInWater == 0 && waterTintData.a > 0.5 ? clamp((texture2D(colortex7,texUV).a-0.6)/0.4,0.0,1.0) : clamp(float(eyeBrightnessSmooth.x)/240.0,0.0,1.0);
   float light = max(CAVE_AMBIENT,max(waterSky,0.6*waterBlock));
   vec3 scattering = scatterCoefficient * WATER_SCATTERING * light;
   vec3 transmission = vec3(1.0);
   vec3 radiance = vec3(0.0);

#if WATER_VOLUMETRIC_SAMPLES > 0
   int waterSamples = WATER_VOLUMETRIC_SAMPLES;
   float stepLength = distanceInWater / float(waterSamples);
   for (int i=0; i<waterSamples; ++i) {
      float t = (float(i)+0.5)/float(waterSamples);
      vec3 world = view2feet(mix(startPosition,endPosition,t)) + cameraPosition;
      float density = mix(0.85,1.15,vvFogNoise(world*0.16+vec3(0.0,frameTimeCounter*0.025,0.0)));
      vec3 stepTransmission = exp(-extinction*stepLength*density);
      vec3 localScattering = scattering;
#ifdef OVERWORLD
      vec3 waterDirection = normalize(endPosition-startPosition);
      float phase = vvForwardPhase(dot(waterDirection,normalize(sunPosition)));
      float sunUp = smoothstep(0.0,0.12,normalize(view2eye(sunPosition)).y);
      float sunVisibility=vvSunVisibility(world);
      float daylight=sunUp*(1.0-rainStrength)*waterSky;
      localScattering *= 0.65+0.35*sunVisibility*daylight*min(phase,3.0);
#ifdef WATER_LIGHT_SHAFTS
      // Project the animated caustic pattern along the sun direction. Points on
      // the same light ray share a pattern value, forming coherent light columns.
      vec3 sunWorld=normalize(view2eye(sunPosition));
      vec2 shaftPosition=world.xz-world.y*sunWorld.xz/max(sunWorld.y,0.12);
      // Broad shafts and larger coverage cells avoid clipping them into thin strips.
      float shaftPattern=vvCausticPattern(vec3(shaftPosition.x*0.2,0.0,shaftPosition.y*0.2));
      // Reduce shaft coverage only; the lake-bed caustic texture stays intact.
      vec2 shaftCell=floor(shaftPosition/4.0);
      float shaftCoverage=fract(sin(dot(shaftCell,vec2(127.1,311.7)))*43758.5453);
      shaftPattern*=step(0.75,shaftCoverage);
      float shaftPhase=0.35+min(phase,4.0);
      vec3 shaftLight=scatterCoefficient*WATER_SCATTERING*vvCausticSunColor()
         *shaftPattern*8.0*shaftPhase*sunVisibility*daylight;
      // Rays use the same RGB absorption and integration as the water fog.
      localScattering+=shaftLight;
#endif
#endif
      // Integrate RGB single scattering with the same extinction as transmission.
      radiance += transmission*(localScattering/max(extinction,vec3(0.00001)))*(vec3(1.0)-stepTransmission);
      transmission *= stepTransmission;
      if (max(transmission.r,max(transmission.g,transmission.b)) < 0.005) break;
   }
#else
   transmission = exp(-extinction*distanceInWater);
   radiance = (scattering/max(extinction,vec3(0.00001)))*(vec3(1.0)-transmission);
#endif
   return scene*transmission+radiance;
#else
   return scene;
#endif
}

