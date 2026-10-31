#define PACK_OUTLINE_MARKERS
#define PACK_FULLBRIGHT_ENTITIES
//#define LAMB_DYNAMIC_LIGHTS
#define CAVE_AMBIENT 0.08 //[0.0 0.04 0.06 0.08 0.1 0.15]
#define WATER_MOON_GLINT 0.15 //[0.0 0.05 0.1 0.15 0.25 0.5]
#define WATER_TEXTURE_OVERLAY 1.0 //[0.0 0.25 0.5 0.75 1.0]
//#define COLORED_GLASS_SHADOWS
#define WATER_SCENE_REFLECTIONS
#define WATER_SUN_GLINT 2.0 //[0.0 0.5 1.0 2.0 3.0 4.0]
#define GLASS_REFLECTION_STRENGTH 0.35 //[0.0 0.15 0.25 0.35 0.5 0.75]
#define SUNSET_BLOOM_BOOST 1.75 //[1.0 1.25 1.5 1.75 2.0 2.5 3.0]
#define PORTAL_EMISSION 3.0 //[1.0 2.0 3.0 4.0 6.0]
#define MATERIAL_MODE 0 //[0 1]
#if MATERIAL_MODE == 1
#define LABPBR
#endif
#define INTEGRATED_EMISSION 1.0 //[0.0 0.5 1.0 1.5 2.0 3.0]
#define INTEGRATED_METALS 1.0 //[0.0 0.25 0.5 0.75 1.0]
#define CAUSTICS_SCALE 2.0 //[0.25 0.5 0.75 1.0 1.5 2.0]
#define CAUSTICS_SPEED 1.0 //[0.25 0.5 1.0 1.5 2.0]
#define CAUSTICS_POWER 1.0 //[1.0 2.0 3.0 4.0]
#define LABPBR_NORMAL_STRENGTH 1.0 //[0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0]
#define LABPBR_METAL_FACTOR 1.0 //[0.0 0.25 0.5 0.75 1.0]
#define LABPBR_ROUGHNESS_SCALE 1.0 //[0.5 0.75 1.0 1.25 1.5 2.0]
#define LABPBR_SPECULAR_STRENGTH 1.0 //[0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0]
#define LABPBR_AO_STRENGTH 1.0 //[0.0 0.25 0.5 0.75 1.0]
#define LABPBR_EMISSION_STRENGTH 1.0 //[0.0 0.25 0.5 0.75 1.0 1.5 2.0 3.0 4.0]
#define COLOR_GRADING 1 //[0 1]

#define EXPOSURE 1.0 //[0.5 0.75 1.0 1.25 1.5 2.0]
#define AUTO_EXPOSURE
#define EXPOSURE_MIN 0.5 //[0.25 0.5 0.75 1.0]
#define EXPOSURE_MAX 2.0 //[1.0 1.5 2.0 3.0 4.0 6.0 8.0]
#define EXPOSURE_SPEED 1.0 //[0.25 0.5 1.0 1.5 2.0 4.0]
#define BLOOM_STRENGTH 0.12 //[0.0 0.05 0.1 0.12 0.2 0.3 0.5]
#define SUN_BLOOM_STRENGTH 1.0 //[0.0 0.25 0.5 0.75 1.0 1.5 2.0]
#define BLOOM_RADIUS 3.0 //[0.5 1.0 1.5 2.0 3.0]
#define HEIGHT_FOG
#define FOG_HEIGHT 64.0 //[-64.0 0.0 32.0 64.0 96.0 128.0 192.0]
#define NETHER_FOG_DISTANCE 96.0 //[32.0 48.0 64.0 96.0 128.0 192.0 256.0]
#define SIFT_FOG_DISTANCE 192.0 //[48.0 64.0 96.0 128.0 192.0 256.0 384.0]
#define SIFT_AMBIENCE 1.25 //[0.0 0.25 0.5 0.75 1.0 1.25 1.5]
#define SIFT_SKY_GLOW 1.0 //[0.0 0.25 0.5 0.6 0.75 1.0 1.5]
#define SIFT_MIST_HEIGHT 64.0 //[0.0 32.0 64.0 96.0 128.0 192.0]
#define SIFT_LIGHT_SHAFTS 0.65 //[0.0 0.25 0.4 0.65 0.8 1.0 1.5]
#define SIFT_MOTES 0.7 //[0.0 0.25 0.5 0.7 1.0 1.5]
#define SIFT_GLOW 1.15 //[0.0 0.5 0.75 1.0 1.15 1.5 2.0]
#define END_FOG_DISTANCE 192.0 //[48.0 64.0 96.0 128.0 192.0 256.0 384.0]
#define END_AMBIENCE 1.0 //[0.0 0.25 0.5 0.75 1.0 1.25 1.5]
#define END_FLASH_SKY
#define END_FLASH_STRENGTH 1.0 //[0.0 0.25 0.5 0.75 1.0 1.5 2.0]
#define END_SKY_GLOW 1.0 //[0.0 0.25 0.5 0.75 1.0 1.5 2.0]
#define NETHER_AMBIENCE 0.8 //[0.0 0.25 0.5 0.8 1.0 1.25 1.5]
#ifdef THE_NETHER
   uniform vec3 fogColor;
#endif
#define FOG_DENSITY 1.0 //[0.25 0.5 0.75 1.0 1.5 2.0]
#define CLOUD_SHADOWS
#define CLOUD_SHADOW_STRENGTH 0.0 //[0.0 0.15 0.25 0.35 0.5 0.65 0.8]
#define CLOUD_SHADOW_HEIGHT 192.0 //[128.0 160.0 192.0 224.0 256.0 320.0]
#define DIMENSION_VOLUMETRICS
#define DIMENSION_FOG_STRENGTH 1.0 //[0.0 0.25 0.5 0.75 1.0 1.5 2.0]
#define VOLUMETRIC_SAMPLES 8 //[0 4 8 12 16 32 64 96 128]
#define WATER_VOLUMETRIC_SAMPLES 64 //[0 4 8 12 16 32 64 96 128]
//#define WATER_LIGHT_SHAFTS
#define TWILIGHT_RAYS
#define TWILIGHT_RAY_STRENGTH 1.0 //[0.0 0.25 0.5 0.75 1.0 1.5 2.0]
#define VOLUMETRIC_STRENGTH 0.18 //[0.0 0.05 0.1 0.18 0.25 0.4]
#define CAVE_RAY_STRENGTH 1.0 //[0.0 0.25 0.5 0.75 1.0 1.5 2.0]
#define CAVE_RAY_FADE_HEIGHT 128.0 //[32.0 64.0 96.0 128.0 160.0 192.0 224.0]
#define SSAO_SAMPLES 4 //[0 4 8]
#define SSAO_STRENGTH 0.35 //[0.0 0.15 0.25 0.35 0.5 0.75]
#define SKY_REFLECTIONS
#define WATER_VOLUMETRICS
#define WATER_FOG_DENSITY 0.5 //[0.0 0.25 0.5 0.75 1.0 1.5 2.0]
#define WATER_SCATTERING 0.8 //[0.0 0.25 0.4 0.6 0.8 1.0]
#define WATER_ABSORPTION 0.08 //[0.0 0.02 0.04 0.08 0.12 0.2]
#define WATER_CAUSTICS 6.0 //[0.0 0.15 0.3 0.6 1.0 1.5 2.0 3.0 4.0 5.0 6.0]
#define CAUSTICS_PIXELS 16 //[8 16 32 64]
// Keep symbolic format directives for Iris while defining valid GLSL values.
const int RGBA16F = 34842;
const int colortex0Format = RGBA16F;
const int colortex4Format = RGBA16F;
const int RGBA32F = 34836;
const int colortex3Format = RGBA32F; // Preserve precision for gradual exposure changes.
const bool colortex3Clear = false;
const bool colortex4Clear = true;


#define SHADOW_DARKNESS 0.3 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define LIGHT_BRIGHTNESS 0.9 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]

#define ENABLE_FOG
#define OVERWORLD_FOG_MAX_SLIDER 7 //[0 1 2 3 4 5 6 7 8 9 10]
#define OVERWORLD_FOG_MIN_SLIDER 0 //[0 1 2 3 4 5 6 7 8 9 10]
#define WEATHER_OPACITY 0.35 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

#define TORCH_INNER_R 1.0  //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_INNER_G 0.85 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_INNER_B 0.7  //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_MIDDLE_R 1.0 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_MIDDLE_G 0.8 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_MIDDLE_B 0.6 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_OUTER_R 1.0  //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_OUTER_G 0.55 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_OUTER_B 0.2  //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define MOON_R 0.1  //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define MOON_G 0.15 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define MOON_B 0.3  //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

#define BLOCK_REFLECTIONS 5  //[0 1 2 3 4 5 6 7 8 9 10]
#define REFLECTIONS 10       //[0 1 2 3 4 5 6 7 8 9 10]
#define SSR_MAX_STEPS 10     //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 24 32 64 96 128 256 512]
#define SSR_STEP_SIZE 1.6    //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define SSR_BINARY_STEPS 4   //[1 2 3 4 5 6 7 8 9 10]

#define SHADOW_BLUENESS 0.2 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]

const int   shadowMapResolution = 1024;  //[256 512 1024 2048 3072 4096]
const float shadowDistance      = 384.0; //[8.0 16.0 32.0 64.0 96.0 128.0 192.0 256.0 384.0 512.0 768.0 1024.0]
// Cover off-screen roofs/ceilings along the light axis as well as across the map.
const float shadowNearPlane = -2048.0;
const float shadowFarPlane = 2048.0;
const float SHADOW_DEPTH_BIAS_SCALE = 256.05 / (shadowFarPlane-shadowNearPlane);
const float shadowIntervalSize  = 7.0;  //[1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0]
const float shadowDistanceRenderMul = 1.0;
const float entityShadowDistanceMul = 1.0; //[0.125 0.2 0.25 0.333 0.5 0.75 1.0]
const float sunPathRotation = 0.0; //[-90.0 -85.0 -80.0 -75.0 -70.0 -65.0 -60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0 65.0 70.0 75.0 80.0 85.0 90.0]

#define WATER_WAVE_SIZE 1          //[0 1 2 3 4 5 6 7 8 9 10]
#define WATER_WAVE_SPEED 2         //[1 2 3 4 5 6 7 8 9 10]
#define WATER_BRIGHTNESS 0.4       //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define WATER_B 1.3                //[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]
#define WATER_A 0.7                //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define WATER_MIN_GLINT 9          //[-1 0 1 2 3 4 5 6 7 8 9 10]
#define WATER_GLINT_CUTOFF 0.6     //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define WATER_GLINT_BRIGHTNESS 0.8 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]

#define END_STARS_SPEED  0.05  //[0.002 0.005 0.01 0.02 0.05 0.1 0.5]
#define END_STARS_AMOUNT 256.0 //[128.0 256.0 512.0 1024.0 2048.0]
#define END_STARS_FLOOR  256.0
#define END_STARS_OPACITY 1.0 //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define FLAT_LIGHTING
//#define GLOWING_ORES
#define HIGHLIGHT_WAXED
#define SHADOW_ENTITY 1 //[-1 0 1]
#define ENABLE_SKY
#define NETHER_COLOR_GRADING

#if defined OVERWORLD || defined THE_SIFT
   #define ENABLE_SHADOWS
#endif

#if MC_VERSION >= 11300
   #define HAND_DYNAMIC_LIGHTING 0 //[-1 0 1]
#endif

// optifine needs these to show on menu
#ifdef LABPBR
#endif
#ifdef ENABLE_FOG
#endif
#ifdef ENABLE_SKY
#endif
#ifdef FLAT_LIGHTING
#endif
#ifdef SHADOW_ENTITY
#endif
#ifdef NETHER_COLOR_GRADING
#endif

//----------------------------------------------------------------------------//

#define MIN_REFLECTIVITY 0.01
#define WATER_REFLECTIVITY 0.99
#define GLASS_REFLECTIVITY 0.3

#define HALF_PI 1.570796326
#define PI 3.141592653
#define TAU 6.283185307
#define SQRT_2 1.414213562
#define NOON 0.25 // 6000
#define SUNSET 0.5325 // 12780
#define MIDNIGHT 0.75 // 18000
#define SUNRISE 0.9675 // 23220

const float INV_PI = 1.0 / PI;
const float INV_TAU = 1.0 / TAU;

const float NORMALIZE_TIME = 1.0/24000.0;

const float OVERWORLD_FOG_MIN = 1.0 - 0.1*OVERWORLD_FOG_MAX_SLIDER;
const float OVERWORLD_FOG_MAX = 1.0 - 0.1*OVERWORLD_FOG_MIN_SLIDER;

const vec2 AMBIENT_UV = vec2(8.0/255.0, 247.0/255.0);
const vec2 TORCH_UV_SCALE = vec2(8.0/255.0, 231.0/255.0);
const vec3 TORCH_INNER_COLOR = vec3(TORCH_INNER_R, TORCH_INNER_G, TORCH_INNER_B);
const vec3 TORCH_MIDDLE_COLOR = vec3(TORCH_MIDDLE_R, TORCH_MIDDLE_G, TORCH_MIDDLE_B);
const vec3 TORCH_OUTER_COLOR = vec3(TORCH_OUTER_R, TORCH_OUTER_G, TORCH_OUTER_B);
const vec3 MOON_COLOR = vec3(MOON_R, MOON_G, MOON_B);

const vec4 END_STARS_DRAG = vec4(200, 500, 100, 100);
const vec3 END_AMBIENT    = vec3(0.83, 0.7, 1.0);

const vec3 SHADOW_COLOR = vec3(1.0 - SHADOW_DARKNESS) + vec3(0.0, 0.3333, 1.0) * SHADOW_BLUENESS;

const float SHADOW_MAX_DIST_SQUARED = shadowDistance * shadowDistance;
const float INV_SHADOW_MAX_DIST_SQUARED = 1.0/SHADOW_MAX_DIST_SQUARED;

// Compare individual depths before filtering visibility. Interpolating depth
// across unrelated surfaces produces false shadows at geometry boundaries.
const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;

const bool colortex2Clear = true;
const vec4 colortex2ClearColor = vec4(0.0, 0.0, 0.0, 0.0);

// Untouched sky has no surface marker; custom depthless effects still do.
const bool colortex7Clear = true;
const vec4 colortex7ClearColor = vec4(0.0, 0.0, 0.0, 0.0);

// Signed surface tags protect entities from DH and exclude vegetation from caustics.
// Every profile reads these tags, so normalized RGBA8 is never suitable.
const int colortex1Format = RGBA16F;
const bool colortex1Clear = true;
const vec4 colortex1ClearColor = vec4(0.0,0.0,0.0,0.0);

const int RGBA8 = 32856;
const int shadowcolor0Format = RGBA8;
const vec4 shadowcolor0ClearColor = vec4(1.0,1.0,1.0,0.0);

#ifdef THE_SIFT
// The Sift maps its clock to 3000 by day and 18000 by night, with smooth transitions.
float siftNightWeight(float time) {
 return smoothstep(11000.0,15000.0,time)*(1.0-smoothstep(22000.0,24000.0,time));
}
#endif

#define BIOME_ATMOSPHERE
#define BIOME_ATMOSPHERE_STRENGTH 0.65 //[0.0 0.25 0.5 0.65 0.75 1.0]

#define WATER_CDOM 0.1 //[0.0 0.1 0.25 0.5 1.0 2.0 4.0 8.0 15.0]
#define WATER_CHLOROPHYLL 0.1 //[0.0 0.1 0.25 0.5 1.0 2.0 5.0 10.0]
#define WATER_SEDIMENT 0.25 //[0.0 0.25 0.5 1.0 5.0 10.0 30.0 100.0 300.0]
#define WATER_BIOME_COLOR 0.2 //[0.0 0.1 0.2 0.35 0.5 0.75 1.0]
