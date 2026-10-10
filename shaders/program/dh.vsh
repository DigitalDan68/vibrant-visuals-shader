#include "/shader.h"

// Chunks Fade In 3.0.29 reorders Iris fog globals before their struct type.
// Its supported opt-out marker bypasses that patch for DH programs only.
void _cfi_ignoreMarker() {}

uniform vec3 sunPosition;
uniform float frameTimeCounter;
out vec4 color;
out vec2 lightUV;
out vec3 feetPos;
out vec3 dhNormal;
out float sunHeight;
flat out float dhEmission;
flat out float dhWater;

#include "/common/transformations.glsl"
#include "/common/math.glsl"
#include "/common/getWaterWave.vsh"

void main() {
   vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
   gl_Position = gl_ProjectionMatrix * viewPos;
   feetPos = view2feet(viewPos.xyz);
   dhNormal = normalize(view2eye(gl_NormalMatrix * gl_Normal));
   sunHeight = view2eye(sunPosition).y;
   color = gl_Color;
   // Iris supplies normalized DH lightmap coordinates.
   lightUV = gl_MultiTexCoord2.st;
   dhEmission = float(dhMaterialId == DH_BLOCK_LAVA || dhMaterialId == DH_BLOCK_ILLUMINATED);
   dhWater = float(dhMaterialId == DH_BLOCK_WATER);
   if (dhWater > 0.5 && abs(dhNormal.y) > 0.8 && WATER_WAVE_SIZE > 0) {
      float seed = random(floor(feetPos.xz+cameraPosition.xz+vec2(0.01)));
      dhNormal = normalize(dhNormal+getWaterWave(seed,feetPos));
   }
   #ifndef FLAT_LIGHTING
      if (dhWater < 0.5) color.rgb *= clamp(dhNormal.x * dhNormal.x * 0.6
                       + dhNormal.y * dhNormal.y * 0.25 * (3.0 + dhNormal.y)
                       + dhNormal.z * dhNormal.z * 0.8, dhEmission, 1.0);
   #endif
}
