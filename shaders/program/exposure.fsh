#include "/shader.h"
uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;
uniform float frameTime;
uniform int frameCounter;
void main() {
   float exposure = 1.0;
   float meteredLuminance = 0.22;
   #if COLOR_GRADING == 1 && defined AUTO_EXPOSURE
      float logSum = 0.0;
      float weightSum = 0.0;
      // One-pixel pass: meter a fixed scene grid, independently of resolution.
      for (int y = 0; y < 9; y++) for (int x = 0; x < 16; x++) {
         vec2 uv = (vec2(float(x), float(y)) + 0.5) / vec2(16.0, 9.0);
         float depth = texture2D(depthtex0, uv).x;
         if (depth < 0.56) continue; // Exclude the held-item depth range.
         vec3 linearColor = pow(max(texture2D(colortex0, uv).rgb, vec3(0.0)), vec3(2.2));
         float luminance = dot(linearColor, vec3(0.2126, 0.7152, 0.0722));
         vec2 center = uv - 0.5;
         float weight = exp(-4.0 * dot(center, center));
         if (depth >= 1.0) weight *= 0.35; // Sky must not dominate land/cave exposure.
         logSum += log(clamp(luminance, 0.001, 64.0)) * weight;
         weightSum += weight;
      }
      if (weightSum > 0.0) meteredLuminance = exp(logSum / weightSum);
      float target = clamp(0.22 / max(meteredLuminance, 0.001), EXPOSURE_MIN, max(EXPOSURE_MIN, EXPOSURE_MAX));
      vec4 history = texture2D(colortex3, vec2(0.5));
      bool validHistory = history.r >= EXPOSURE_MIN && history.r <= max(EXPOSURE_MIN, EXPOSURE_MAX)
                       && abs(history.b - 42.0) < 0.01;
      float previous = validHistory && frameCounter > 1 ? history.r : 1.0;
      float rate = target < previous ? 3.0 : 1.2;
      float blend = 1.0 - exp(-clamp(frameTime, 0.0, 0.25) * rate * EXPOSURE_SPEED);
      exposure = mix(previous, target, blend);
   #endif
   /* DRAWBUFFERS:3 */
   gl_FragData[0] = vec4(exposure, meteredLuminance, 42.0, 1.0);
}
