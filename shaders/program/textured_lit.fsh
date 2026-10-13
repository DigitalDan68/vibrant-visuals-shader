#include "/shader.h"

uniform float screenBrightness;
uniform int entityId;
#ifdef GBUFFERS_HAND
   uniform vec3 sunPosition;
#endif
uniform ivec2 eyeBrightnessSmooth;
uniform sampler2D gtexture;
uniform sampler2D lightmap;
#if defined GBUFFERS_HAND && HAND_DYNAMIC_LIGHTING >= 0 && !defined LAMB_DYNAMIC_LIGHTS
layout(r32ui) uniform uimage2D enchantedHeldImage;
#endif
#if (defined GBUFFERS_TERRAIN || defined GBUFFERS_ENTITIES_OPAQUE || defined GBUFFERS_ENTITIES_TRANSLUCENT || defined GBUFFERS_HAND) && !defined MOD_COLORWHEEL
   flat varying float integratedId;
   flat varying float cutCopperSurface;
   varying vec3 pbrNormal;
   varying vec4 pbrTangent;
   flat varying float pbrIsThin;
   #ifdef ENABLE_SHADOWS
      varying float pbrDiffuseScale;
   #endif
#endif

#if (defined GBUFFERS_TERRAIN || defined GBUFFERS_ENTITIES_OPAQUE || defined GBUFFERS_ENTITIES_TRANSLUCENT || defined GBUFFERS_HAND) && !defined MOD_COLORWHEEL
   #define TERRAIN_LABPBR
   uniform sampler2D normals;
   uniform sampler2D specular;
   uniform vec3 skyColor;
   #ifndef THE_NETHER
      uniform vec3 fogColor;
   #endif
   #include "/common/labpbr.glsl"
   #if defined ENABLE_SHADOWS || (defined GBUFFERS_HAND && defined OVERWORLD)
      uniform float rainStrength;
   #endif
#endif
uniform vec4 entityColor;

flat varying float lightSourceLevel;
varying float fogMix;
varying float sunHeight;
varying vec2 lightUV;
varying vec2 texUV;
varying vec3 feetPos;
varying vec3 gradientFogColor;

#ifdef GBUFFERS_TERRAIN
   varying vec4 color;
#else
   flat varying vec4 color;
#endif

#ifdef THE_END
   varying vec3 endTint;
#endif

#if BLOCK_REFLECTIONS > 0
   flat varying vec3 blockReflectivity;
   varying vec3 normal;
#endif

#ifdef GLOWING_ORES
   flat varying float isOre;
#endif

#if HAND_DYNAMIC_LIGHTING == 0 && !defined LAMB_DYNAMIC_LIGHTS
   uniform int heldBlockLightValue;
#elif HAND_DYNAMIC_LIGHTING == 1 && !defined LAMB_DYNAMIC_LIGHTS
   #define heldBlockLightValue 14
#endif

#include "/common/math.glsl"
#include "/common/getTorchColor.fsh"
#include "/common/getAmbientColor.glsl"

#if defined ENABLE_SHADOWS || defined TERRAIN_LABPBR
   #include "/common/transformations.glsl"
#endif

#ifdef ENABLE_SHADOWS
   uniform vec3 shadowLightPosition;
   uniform mat4 shadowModelView;
   uniform mat4 shadowProjection;
   uniform sampler2D shadowtex1;

   varying vec3 lightColor;
   varying float diffuse;

   #include "/common/getLightStrength.fsh"
#endif

void main() {
   if (fogMix > 0.999) {
      discard;
   }

   vec4 albedo = texture2D(gtexture, texUV);
   vec4 outlineTexture = albedo;
   vec4 outlineVertexColor = color;
   bool outlineUnlit = false;
   bool outlineUntinted = false;
#if defined PACK_OUTLINE_MARKERS && (defined GBUFFERS_HAND || defined GBUFFERS_ENTITIES_OPAQUE || defined GBUFFERS_ENTITIES_TRANSLUCENT)
   // Read the original texel, not a filtered alpha that could accidentally
   // interpolate to a reserved marker at the edge of an ordinary sprite.
   ivec2 outlineSize = textureSize(gtexture,0);
   ivec2 outlinePixel = clamp(ivec2(floor(texUV*vec2(outlineSize))),ivec2(0),outlineSize-ivec2(1));
   float outlineAlpha = floor(texelFetch(gtexture,outlinePixel,0).a*255.0+0.5);
#ifdef GBUFFERS_HAND
   bool outlineItem = true;
#else
   bool outlineItem = integratedId >= 41001.0;
#endif
   outlineUnlit = outlineItem && (outlineAlpha == 200.0 || outlineAlpha == 252.0 || outlineAlpha == 253.0);
   outlineUntinted = outlineAlpha == 200.0;
#endif
#if defined GBUFFERS_HAND && HAND_DYNAMIC_LIGHTING >= 0 && !defined LAMB_DYNAMIC_LIGHTS
   // Outline packs replace vanilla glint with marked item texture pixels.
   // Only held-item programs register these markers, never mobs or drops.
   if (outlineUnlit && outlineTexture.a*outlineVertexColor.a > 0.01)
      imageAtomicOr(enchantedHeldImage,ivec2(0),1u);
#endif
   vec4 color  = color;
   bool resourceEntityFullbright=false;
   vec3 resourceEntityEmission=vec3(0.0);
#if defined GBUFFERS_ENTITIES_OPAQUE || defined GBUFFERS_ENTITIES_TRANSLUCENT
   // ETF's mob emissive draw uses Minecraft's packed FULL_BRIGHT lightmap.
   // Preserve that draw's texture-defined brightness instead of shading it again.
#ifdef PACK_FULLBRIGHT_ENTITIES
   resourceEntityFullbright=min(lightUV.x,lightUV.y)>0.96;
#endif
   if(resourceEntityFullbright)
      resourceEntityEmission=pow(max(albedo.rgb*color.rgb,vec3(0.0)),vec3(2.2))*LABPBR_EMISSION_STRENGTH*2.0;
#endif

   #ifdef GBUFFERS_TERRAIN
      float ambientOcclusion = color.a;
      color.a = 1.0;
   #else
      float ambientOcclusion = 1.0;
   #endif

   #ifdef MOD_COLORWHEEL
      vec2 lightUV;
      vec4 entityColor;

      clrwl_computeFragment(albedo, albedo, lightUV, ambientOcclusion, entityColor);
   #endif

   #ifdef TERRAIN_LABPBR
      vec4 packNormal = texture2D(normals,texUV);
      vec4 packSpecular = texture2D(specular,texUV);
      bool hasPackSpecular = any(greaterThan(abs(packSpecular),vec4(0.5/255.0)));
      bool hasPackNormal = any(greaterThan(abs(packNormal-vec4(127.0/255.0,127.0/255.0,1.0,1.0)),vec4(1.5/255.0)));
#if MATERIAL_MODE == 1
      vec4 normalSample = packNormal;
      vec4 specSample = packSpecular;
#else
      vec4 normalSample = vec4(0.5,0.5,1.0,1.0);
      float rough = 1.0;
      float metal = 0.0;
      float emit = 0.0;
      if (integratedId == 30001.0 || integratedId == 30002.0 || integratedId == 30005.0 || integratedId == 20013.0) {rough = 0.28;metal = 0.55*INTEGRATED_METALS;}
      if (integratedId == 20007.0 || integratedId == 20008.0 || integratedId == 42014.0 || integratedId == 10984.0) {rough = 0.28;metal = 0.55*INTEGRATED_METALS;}
      if ((integratedId >= 43101.0 && integratedId <= 43103.0) ||
          (integratedId >= 43111.0 && integratedId <= 43113.0)) {
         float oxidation = integratedId >= 43111.0 ? integratedId-43110.0 : integratedId-43100.0;
         rough = oxidation < 1.5 ? 0.45 : (oxidation < 2.5 ? 0.65 : 0.85);
         metal = (oxidation < 1.5 ? 0.35 : (oxidation < 2.5 ? 0.15 : 0.03))*INTEGRATED_METALS;
      }
      if (integratedId == 43003.0) {
         float copperFleck = max(smoothstep(0.06,0.18,albedo.r-albedo.b),
                                 smoothstep(0.04,0.14,albedo.g-albedo.r));
         rough = mix(1.0,0.28,copperFleck);
         metal = 0.55*copperFleck*INTEGRATED_METALS;
      }
      if (integratedId == 30004.0) rough = 0.2;
      if (integratedId == 30010.0) rough = 0.35;
      if (integratedId >= 30020.0 && integratedId <= 30022.0) emit = PORTAL_EMISSION;
      if (integratedId == 20014.0 || integratedId == 20015.0) rough = 0.12;
      if (integratedId == 20003.0 || integratedId == 20005.0 || integratedId == 20006.0 ||
          (integratedId >= 20010.0 && integratedId <= 20012.0) || integratedId == 20017.0) rough = 0.7;
      float bright = max(albedo.r,max(albedo.g,albedo.b));
      if (integratedId >= 43120.0 && integratedId <= 43123.0) {
         float oxidation = integratedId-43120.0;
         rough = oxidation < 0.5 ? 0.28 : (oxidation < 1.5 ? 0.45 : (oxidation < 2.5 ? 0.65 : 0.85));
         metal = (oxidation < 0.5 ? 0.55 : (oxidation < 1.5 ? 0.35 : (oxidation < 2.5 ? 0.15 : 0.03)))*INTEGRATED_METALS;
         // Vanilla frame peaks at 227/255 red; panels start at 246/255.
         // Require bright warm/cream texels, not merely copper-colored ones.
         float bulbPanel = smoothstep(0.90,0.96,albedo.r)
                         * smoothstep(0.60,0.65,albedo.g)
                         * (1.0-smoothstep(0.01,0.06,albedo.g-albedo.r));
         emit = bulbPanel*1.5;
      }

      #ifndef GBUFFERS_TERRAIN
      if (integratedId == 40001.0) {
         // Include warm, weathered iron pixels; exclude green vines and red eyes.
         float vines = smoothstep(0.02,0.10,albedo.g-max(albedo.r,albedo.b));
         float eyes = smoothstep(0.20,0.40,albedo.r-max(albedo.g,albedo.b));
         float ironBody = (1.0-vines)*(1.0-eyes);
         metal = 0.20*ironBody*INTEGRATED_METALS;
         rough = mix(1.0,0.72,ironBody);
      }
      if (integratedId >= 41001.0 && integratedId <= 41005.0) {
         float metalPart = 1.0-smoothstep(0.06,0.18,bright-min(albedo.r,min(albedo.g,albedo.b)));
         if (integratedId == 41002.0 || integratedId == 41005.0)
            metalPart = smoothstep(0.12,0.28,albedo.g-albedo.b)*smoothstep(0.45,0.70,albedo.r);
         if (integratedId == 41003.0)
            metalPart = smoothstep(0.08,0.25,min(albedo.g,albedo.b)-albedo.r);
         metal = 0.50*metalPart*INTEGRATED_METALS;
         rough = mix(1.0,0.28,metalPart);
      }
      #endif
      if ((integratedId >= 42001.0 && integratedId <= 42014.0) || (integratedId >= 43111.0 && integratedId <= 43113.0)) emit = 1.0;
      float warmPixel = smoothstep(0.55,0.85,bright)*smoothstep(0.05,0.25,max(albedo.r,albedo.b)-albedo.g*0.7);
      if (integratedId == 30003.0) emit = smoothstep(0.55,0.9,bright);
      // Match the previous texture-shaped glow, with a gentler froglight bloom.
      if (integratedId >= 42009.0 && integratedId <= 42011.0) emit = 0.8*smoothstep(0.55,0.9,bright);
      if (integratedId == 10068.0 || integratedId == 10072.0 || integratedId == 10076.0) emit = 1.0;
      if (integratedId >= 10496.0 && integratedId <= 10984.0) emit = warmPixel;
      // Copper torch flames are green, unlike the warm-source fallback.
      if (integratedId == 10984.0)
         emit = max(warmPixel,smoothstep(0.30,0.65,albedo.g)*smoothstep(0.035,0.15,albedo.g-max(albedo.r,albedo.b)));
      // Soul flames include dark cyan embers below the warm-source cutoff.
      // Cyan separation keeps the brown logs and neutral ash non-emissive.
      if (integratedId == 10656.0)
         emit = max(warmPixel,smoothstep(0.03,0.12,min(albedo.g,albedo.b)-albedo.r)*smoothstep(0.12,0.35,bright));
      if (integratedId == 42016.0)
         emit=1.2*smoothstep(0.03,0.12,min(albedo.g,albedo.b)-albedo.r)*smoothstep(0.10,0.30,bright);
      if (integratedId == 42015.0) {
         float yellowLichen = smoothstep(0.025,0.09,min(albedo.r,albedo.g)-albedo.b);
         emit = mix(1.4,2.0,yellowLichen);
      }
      // Select saturated vein texels from the unlit texture, leaving dark bark intact.
      if (integratedId >= 43201.0 && integratedId <= 43215.0)
         emit = 1.5*(integratedId-43200.0)/15.0;
      if (integratedId == 43001.0)
         emit = smoothstep(0.32,0.55,albedo.r)*smoothstep(0.12,0.25,albedo.r-albedo.g);
      if (integratedId == 43002.0)
         emit = smoothstep(0.18,0.35,max(albedo.g,albedo.b))*smoothstep(0.07,0.16,min(albedo.g,albedo.b)-albedo.r);
      // Texture-anchored oxidation patches remain stable as the camera moves.
      float patchOxidation = 0.0;
      if (integratedId >= 43101.0 && integratedId <= 43102.0) patchOxidation = integratedId-43100.0;
      if (integratedId >= 43111.0 && integratedId <= 43112.0) patchOxidation = integratedId-43110.0;
      if (integratedId >= 43121.0 && integratedId <= 43122.0) patchOxidation = integratedId-43120.0;
      if (patchOxidation > 0.0) {
         vec2 copperTexel = floor(texUV*vec2(textureSize(gtexture,0)));
         float patchNoise = fract(sin(dot(copperTexel,vec2(12.9898,78.233)))*43758.5453);
         float copperWarmth = clamp((albedo.r-albedo.g)*2.0+0.5,0.0,1.0);
         // Exposed copper loses shine only on green patina; weathered stays noisy.
         float greenPatina = smoothstep(0.015,0.08,albedo.g-albedo.r);
         float metallicPatch = patchOxidation < 1.5 ? 1.0-greenPatina
                              : step(0.72,patchNoise*0.7+copperWarmth*0.3);
         rough = mix(1.0,patchOxidation < 1.5 ? 0.28 : 0.45,metallicPatch);
         metal = metallicPatch*(patchOxidation < 1.5 ? 0.55 : 0.22)*INTEGRATED_METALS;
      }
      // Lamp panels are rough luminous material, not reflective copper.
      // Apply after oxidation coverage so exposed panels cannot regain metal.
      if (integratedId >= 43120.0 && integratedId <= 43123.0) {
         float neutralCore = smoothstep(0.94,0.99,bright)
                           * (1.0-smoothstep(0.10,0.22,bright-min(albedo.r,min(albedo.g,albedo.b))));
         float panelCoverage = max(smoothstep(0.02,0.20,emit),neutralCore);
         emit = max(emit,neutralCore*1.5);
         metal *= 1.0-panelCoverage;
         rough = mix(rough,1.0,panelCoverage);
      }
      // Cut-copper seams use the darker texels of the internal texture.
      // Keep patina roughness; widen only the dividing-strip highlights.
      if (cutCopperSurface>0.5) {
         float strip = 1.0-smoothstep(0.61,0.68,bright);
         rough = max(rough,mix(rough,0.82,strip));
      }
      if (integratedId == 43601.0)
         emit = 1.5*smoothstep(0.35,0.65,albedo.r)*smoothstep(0.12,0.30,albedo.r-albedo.b);
      if (integratedId == 43602.0) {
         float neutralRail=1.0-smoothstep(0.06,0.18,bright-min(albedo.r,min(albedo.g,albedo.b)));
         float goldRail=smoothstep(0.68,0.82,albedo.g/max(albedo.r,0.001))*smoothstep(0.10,0.25,albedo.g-albedo.b);
         float railMetal=max(neutralRail,goldRail);
         rough=mix(1.0,0.36,railMetal);
         metal=railMetal*0.40*INTEGRATED_METALS;
      }
      if (integratedId == 40009.0) {
         float cartMetal=1.0-smoothstep(0.06,0.18,bright-min(albedo.r,min(albedo.g,albedo.b)));
         rough=mix(1.0,0.42,cartMetal);
         metal=cartMetal*0.25*INTEGRATED_METALS;
      }
      // Only colored lamp-interior texels emit; metal hardware stays shaded.
      if (integratedId == 42003.0)
         emit = smoothstep(0.60,0.80,albedo.r)*smoothstep(0.12,0.30,albedo.r-albedo.b);
      if (integratedId == 42001.0)
         emit = smoothstep(0.30,0.65,max(albedo.g,albedo.b))*smoothstep(0.05,0.18,min(albedo.g,albedo.b)-albedo.r);
      if (integratedId == 42014.0 || (integratedId >= 43111.0 && integratedId <= 43113.0))
      {
         float greenInterior=smoothstep(0.50,0.80,albedo.g)*smoothstep(0.025,0.12,albedo.g-max(albedo.r,albedo.b));
         float paleInterior=smoothstep(0.78,0.91,min(albedo.r,min(albedo.g,albedo.b)));
         emit=max(greenInterior,paleInterior);
         // Light panels are luminous glass, not reflective copper.
         float interior=smoothstep(0.05,0.30,emit);
         metal*=1.0-interior;
         rough=mix(rough,1.0,interior);
      }
      emit *= INTEGRATED_EMISSION;
      vec4 specSample = vec4(1.0-sqrt(rough),mix(0.04,230.0/255.0,metal),0.0,min(emit,0.99)*254.0/255.0);
#endif
#if MATERIAL_MODE == 0
      if (hasPackNormal) normalSample=packNormal;
      if (hasPackSpecular) specSample=packSpecular;
#endif
      vec3 N = normalize(pbrNormal);
      vec3 T = pbrTangent.xyz - N * dot(N, pbrTangent.xyz);
      float tangentSign = pbrTangent.w;
      #ifndef GBUFFERS_TERRAIN
      vec3 dx = dFdx(feetPos), dy = dFdy(feetPos);
      vec2 ux = dFdx(texUV), uy = dFdy(texUV);
      float determinant = ux.x*uy.y-ux.y*uy.x;
      if (abs(determinant)>0.000001) {
         T = (dx*uy.y-dy*ux.y)/determinant;
         T -= N*dot(N,T);
         vec3 derivativeB = (-dx*uy.x+dy*ux.x)/determinant;
         tangentSign = dot(cross(N,T),derivativeB)<0.0 ? -1.0 : 1.0;
      }
      #endif
      // A missing tangent must not produce NaNs.
      if ((MATERIAL_MODE == 1 || hasPackNormal) && pbrIsThin < 0.5 && dot(T, T) > 0.00001) {
         T = normalize(T);
         vec3 B = cross(N, T) * sign(tangentSign);
         vec2 xy = normalSample.rg * 2.0 - 1.0;
         xy.y = -xy.y; // labPBR uses DirectX (Y-) normals.
         xy *= LABPBR_NORMAL_STRENGTH;
         xy /= max(1.0, length(xy));
         N = normalize(mat3(T, B, N) * vec3(xy, sqrt(max(0.0, 1.0 - dot(xy, xy)))));
      }
      float pbrEmission = specSample.a < 254.5/255.0 ? specSample.a * 255.0/254.0 : 0.0;
#if MATERIAL_MODE == 0
      if (!hasPackSpecular) pbrEmission = emit;
#endif
      if (!hasPackSpecular) {
      if (integratedId >= 30020.0 && integratedId <= 30022.0) pbrEmission = max(pbrEmission,PORTAL_EMISSION);
      #if MATERIAL_MODE == 0
      if (integratedId == 42015.0 && !hasPackSpecular) pbrEmission = emit;
#endif
      }
      // Powered dust retains its requested glow even if a pack supplies
      // only roughness/metal maps. Stronger pack emission still wins.
      bool poweredDust = integratedId >= 43201.0 && integratedId <= 43215.0;
      if (poweredDust)
         pbrEmission=3.0*pow((integratedId-43200.0)/15.0,5.0)*INTEGRATED_EMISSION;
      float circuitGlow=0.0;
      if (integratedId >= 43301.0 && integratedId <= 43303.0) {
         // Lit red torch tips and traces, excluding gray stone and brown stems.
         circuitGlow=smoothstep(0.4,0.7,albedo.r)
                    *smoothstep(0.12,0.3,albedo.r-max(albedo.g,albedo.b));
         pbrEmission=max(pbrEmission,1.5*circuitGlow*INTEGRATED_EMISSION);
      }
      // Resource packs control entity emission, with the requested blaze fallback.
#if defined GBUFFERS_ENTITIES_OPAQUE || defined GBUFFERS_ENTITIES_TRANSLUCENT
      if (!hasPackSpecular && integratedId >= 40000.0 && integratedId < 41000.0) pbrEmission=0.0;
#endif
#if MATERIAL_MODE == 0
      // Warm blaze body and rods glow; dark facial pixels retain their contrast.
      if (!hasPackSpecular && integratedId == 40002.0)
         pbrEmission = smoothstep(0.20,0.55,albedo.r)*smoothstep(0.06,0.20,albedo.r-albedo.b)*INTEGRATED_EMISSION;
#endif
#if MATERIAL_MODE == 0
      if (!hasPackSpecular && integratedId == 40008.0)
         pbrEmission = 1.5*smoothstep(0.60,0.85,albedo.r)*smoothstep(0.20,0.40,albedo.r-albedo.b)*INTEGRATED_EMISSION;
#endif
      float pbrMetal = step(229.5/255.0, specSample.g) * (1.0 - pbrIsThin) * LABPBR_METAL_FACTOR;
      float pbrRoughness = clamp(pow(1.0 - specSample.r, 2.0) * LABPBR_ROUGHNESS_SCALE, 0.04, 1.0);
#if MATERIAL_MODE == 0
      if (!hasPackSpecular) {
         pbrMetal = metal*(1.0-pbrIsThin)*LABPBR_METAL_FACTOR;
         pbrRoughness = rough;
      }
#endif
      // Widen undersampled highlights instead of allowing specular fireflies.
      if (MATERIAL_MODE == 1 || hasPackNormal) {
      vec3 normalDx = dFdx(N);
      vec3 normalDy = dFdy(N);
      float variance = 0.25 * (dot(normalDx, normalDx) + dot(normalDy, normalDy));
      pbrRoughness = sqrt(min(1.0, pbrRoughness*pbrRoughness + variance));
      }
      bool pbrHasSpecular = pbrIsThin < 0.5 && ((MATERIAL_MODE == 1 || hasPackSpecular) ? dot(specSample.rgb, specSample.rgb) > 0.0 : specSample.r > 0.001);
      float pbrSpecularStrength = LABPBR_SPECULAR_STRENGTH;
      float integratedReflectionCap = 1.0;
#if MATERIAL_MODE == 0 && defined GBUFFERS_TERRAIN
      if (!hasPackSpecular) {
         pbrSpecularStrength = min(max(pbrSpecularStrength,0.0),0.25);
         integratedReflectionCap = 0.25;
      }
#endif
      vec3 pbrBase = pow(max(albedo.rgb * color.rgb, vec3(0.0)), vec3(2.2));
      float dielectricF0 = specSample.g >= 229.5/255.0 ? 0.04 : specSample.g;
#if MATERIAL_MODE == 0
      if (!hasPackSpecular) dielectricF0 = 0.04;
#endif
      vec3 pbrF0 = mix(vec3(dielectricF0), pbrBase, pbrMetal);
#if MATERIAL_MODE == 0
      if (!hasPackSpecular && (integratedId == 30001.0 || integratedId == 20013.0 ||
                              integratedId == 40001.0 || integratedId == 41001.0)) {
         // Internal iron reflectance uses unshaded texture color.
         pbrF0 = mix(vec3(dielectricF0),clamp(pow(max(albedo.rgb,vec3(0.0)),vec3(2.2))*1.5,vec3(0.08),vec3(0.58)),pbrMetal);
      }
#endif

#if MATERIAL_MODE == 0
      if (!hasPackSpecular && (integratedId == 20007.0 || integratedId == 20008.0 ||
                              integratedId == 42014.0 || integratedId == 10984.0 || integratedId == 43003.0 || (integratedId >= 43101.0 && integratedId <= 43103.0) || (integratedId >= 43111.0 && integratedId <= 43113.0) || (integratedId >= 43120.0 && integratedId <= 43123.0))) {
         // Internal copper uses texture-based reflectance; patina controls coverage.
         // Partial integrated metal coverage keeps the underlying texture readable.
         vec3 copperReflectance = clamp(pow(max(albedo.rgb,vec3(0.0)),vec3(2.2))*2.0,vec3(0.015),vec3(0.85));
         pbrF0 = mix(vec3(dielectricF0),copperReflectance,pbrMetal);
      }
#endif

#if MATERIAL_MODE == 0
      if (!hasPackSpecular && (integratedId == 30002.0 || integratedId == 41002.0 || integratedId == 41005.0))
         pbrF0 = mix(vec3(dielectricF0),pbrBase,pbrMetal);
#endif

      ambientOcclusion *= mix(1.0, normalSample.b, LABPBR_AO_STRENGTH);
   #endif

   vec4 ambient = getAmbientColor(lightUV.t, sunHeight);

   #ifdef THE_END
      ambient.rgb *= endTint;
   #endif

   #ifdef GLOWING_ORES
      ambient.rgb = mix(
         ambient.rgb,
         vec3(1.0, 0.9, 0.9),
         isOre * 0.3333*squaredLength(rescale(albedo.rgb, vec3(0.59), vec3(1.0)))
      );
   #endif

   albedo *= color;

   // render thunder
   albedo.a = entityId == 11000.0 ? 0.15 : albedo.a;
   // render entity color changes (e.g taking damage)
   albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);

   float albedoLuma = luma(albedo.rgb);

   #ifdef ENABLE_SHADOWS
      float materialDiffuse = diffuse;
      #ifdef TERRAIN_LABPBR
         if (pbrIsThin < 0.5) materialDiffuse = pbrDiffuseScale * clamp(2.5 * dot(N, normalize(view2eye(shadowLightPosition))), -0.3333, 1.0);
      #endif
      float lightStrength = getLightStrength(materialDiffuse, lightUV.t, feetPos);
      float lightBrightness = max(0.0, LIGHT_BRIGHTNESS - 0.5*pow3(albedoLuma));

      lightStrength = max(lightStrength, 0.75*lightSourceLevel);

      ambient.rgb *= mix(SHADOW_COLOR, vec3(1.0), lightStrength);
      ambient.rgb *= 0.75 + (lightBrightness * lightStrength) * lightColor * getGlassShadowTint(feetPos);
   #endif

   // Bias only the field lookup into air; evaluate falloff at the actual surface.
   // Use the geometric normal so texture normal maps cannot move the lookup into solids.
   vec3 blockLightNormal = vec3(0.0);
   #ifdef TERRAIN_LABPBR
      blockLightNormal = normalize(pbrNormal);
   #endif

ambient.rgb += getTorchColor(lightUV.s, ambient.rgb, feetPos, blockLightNormal);


   #ifndef TERRAIN_LABPBR
      albedo.rgb *= ambientOcclusion;
   #endif

   albedo *= ambient;

   #ifdef TERRAIN_LABPBR
      vec3 V = normalize(-feetPos + gbufferModelViewInverse[3].xyz);
      vec3 fresnel = vec3(0.0);
      if (pbrHasSpecular) {
      fresnel = labFresnel(pbrF0, max(dot(N, V), 0.0));
      float smoothReflection = pow(1.0 - pbrRoughness, 4.0);
      fresnel = mix(pbrF0, fresnel, smoothReflection);
      fresnel = clamp(fresnel * LABPBR_SPECULAR_STRENGTH, 0.0, 1.0);
      }
      // Retain the miniature ambient palette, with a simple environment fallback.
      vec3 diffuseColor = pow(max(albedo.rgb, vec3(0.0)), vec3(2.2)) * ambientOcclusion;
      vec3 lit = diffuseColor * (1.0 - pbrMetal) * (vec3(1.0) - fresnel);
      if (pbrHasSpecular) {
      vec3 environment = pow(max(ambient.rgb, vec3(0.0)), vec3(2.2));
      #if COLOR_GRADING == 1 && defined SKY_REFLECTIONS && (defined OVERWORLD || defined THE_SIFT)
         environment = labSkyEnvironment(reflect(-V, N), pbrRoughness, skyColor, fogColor)
                     * smoothstep(0.3, 0.95, lightUV.t);
      #endif
      lit += environment * fresnel * (1.0 - 0.5*pbrRoughness) * ambientOcclusion * integratedReflectionCap;
      #if defined ENABLE_SHADOWS || (defined GBUFFERS_HAND && defined OVERWORLD)
         #ifdef ENABLE_SHADOWS
         vec3 L = normalize(view2eye(shadowLightPosition));
         float visibility = getLightStrength(1.0, lightUV.t, feetPos);
         #else
         // Keep held-tool directional highlights even when shadow maps are disabled.
         vec3 sunDirection = view2eye(sunPosition);
         vec3 L = normalize(sunDirection.y >= 0.0 ? sunDirection : -sunDirection);
         float visibility = 0.5*smoothstep(0.3,0.95,lightUV.t);
         vec3 lightColor = sunDirection.y >= 0.0 ? vec3(1.0,0.95,0.85) : MOON_COLOR;
         #endif
         float daylight = clamp(0.1*abs(sunHeight) - 0.4453, 0.0, 1.0);
         lit += labSpecular(N, V, L, pbrF0, pbrRoughness) * lightColor * LIGHT_BRIGHTNESS
              #ifdef ENABLE_SHADOWS
              * getGlassShadowTint(feetPos)
              #endif
              * max(visibility, 0.0) * daylight * (1.0 - rainStrength) * pbrSpecularStrength
              * float(pbrHasSpecular);
      #endif
      }

#if MATERIAL_MODE == 0
      // Integrated emission keeps its strength independent of labPBR controls.
      if (!hasPackSpecular && (integratedId == 43001.0 || integratedId == 43002.0 || (integratedId >= 43201.0 && integratedId <= 43215.0) || (integratedId >= 43120.0 && integratedId <= 43123.0))) {
         // Dark saturated vein textures need a small HDR lift to reach bloom extraction.
         float veinPeak = max(pbrBase.r,max(pbrBase.g,pbrBase.b));
         vec3 veinHue = pbrBase/max(veinPeak,0.025);
         lit += veinHue*pbrEmission*0.9;
      } else {
      lit += pbrBase * pbrEmission * (hasPackSpecular ? LABPBR_EMISSION_STRENGTH : 2.0);
      }
#else
      lit += pbrBase * pbrEmission * LABPBR_EMISSION_STRENGTH;
#endif
      if (poweredDust || circuitGlow>0.001) {
         // Thin, vertex-tinted dust needs HDR radiance to show red bloom.
         float dustPeak=max(pbrBase.r,max(pbrBase.g,pbrBase.b));
         lit+=pbrBase/max(dustPeak,0.001)*pbrEmission*(poweredDust ? 1.5 : 0.9);
      }
      #if COLOR_GRADING == 1
         // Preserve HDR lighting until the final exposure/tone mapping pass.
         albedo.rgb = pow(max(lit, vec3(0.0)), vec3(1.0/2.2));
      #else
         albedo.rgb = pow(labHighlightShoulder(lit, 0.65), vec3(1.0/2.2));
      #endif
   #endif

   #if defined THE_NETHER && defined NETHER_COLOR_GRADING
      albedo.rgb = mix(
         vec3(luma(albedo.rgb)),
         albedo.rgb,
         max(rescale(luma(ambient.rgb), 0.2, 0.6), rescale(albedoLuma, 0.15, 0.4))
      );
   #endif

   if(resourceEntityFullbright)
      albedo.rgb=pow(resourceEntityEmission,vec3(1.0/2.2));
   if(outlineUnlit) {
      albedo.rgb = outlineTexture.rgb*(outlineUntinted ? vec3(1.0) : outlineVertexColor.rgb);
      albedo.a = outlineTexture.a*outlineVertexColor.a;
   }
   albedo.rgb = mix(albedo.rgb, gradientFogColor, fogMix);

#if defined GBUFFERS_ENTITIES_OPAQUE || defined GBUFFERS_ENTITIES_TRANSLUCENT
   // Keep the texture and vertex alpha; the native render type selects blending.
   if(albedo.a<0.01) discard;
#endif
   /* DRAWBUFFERS:067521 */
   gl_FragData[0] = albedo;


   gl_FragData[3] = vec4(0.0);
   gl_FragData[4] = vec4(0.0);
   gl_FragData[5] = vec4(0.0);
#ifdef TERRAIN_LABPBR
   float receiverTag=pbrEmission;
#ifdef GBUFFERS_TERRAIN
   if (pbrIsThin>0.5) receiverTag=-1.0;
#else
   receiverTag=-2.0;
#endif
   gl_FragData[5] = vec4(pbrBase,receiverTag);
#endif
   #ifdef TERRAIN_LABPBR
      gl_FragData[1] = vec4(N * 0.5 + 0.5, 1.0);
      #if BLOCK_REFLECTIONS > 0
         float reflectionWeight = (1.0 - fogMix) * pow(1.0 - pbrRoughness, 4.0)
                                * min(1.0, pbrSpecularStrength) * float(pbrHasSpecular);
      #else
         float reflectionWeight = 0.0;
      #endif
      gl_FragData[2] = vec4(reflectionWeight, pbrRoughness, 0.75, 1.0);
      gl_FragData[3] = vec4(pbrF0, pbrMetal);
   #elif BLOCK_REFLECTIONS > 0
      float reflectivity = max(0.0, (albedoLuma - blockReflectivity.y) * blockReflectivity.x * 0.2*BLOCK_REFLECTIONS);

      gl_FragData[1] = vec4(normal, 1.0);
      gl_FragData[2] = vec4(reflectivity, blockReflectivity.z, 0.5, 1.0);
   #else
      gl_FragData[1] = vec4(vec3(0.0), 1.0);
      gl_FragData[2] = vec4(vec3(0.0), 1.0);
   #endif
}
