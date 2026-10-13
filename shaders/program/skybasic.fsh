#define GBUFFERS_SKYBASIC

#include "/shader.h"

uniform float viewHeight;
uniform float viewWidth;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform int isEyeInWater;

varying float fogMix;
varying vec4 color;

#include "/common/math.glsl"
#include "/common/dry_biome_fog.glsl"
#include "/common/transformations.glsl"

void main() {
	vec4 color = color;
   color.rgb=vvBiomeAtmosphereColor(color.rgb,1.0);

	vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
	vec3 screenPos = normalize(screen2view(uv, 0.999));
	float upDot = dot(screenPos, gbufferModelView[1].xyz);

	vec3 airHorizon = isEyeInWater == 1 ? mix(skyColor,vec3(max(skyColor.r,max(skyColor.g,skyColor.b))),0.35) : vvBiomeAtmosphereColor(fogColor,0.0);
	color.rgb = mix(color.rgb, airHorizon, max(fogMix, fogify(max(upDot, 0.0), 0.05)));

#ifdef OVERWORLD
   // Dense dust obscures the sky just as it obscures distant cloud geometry.
   if (isEyeInWater == 0)
      color.rgb = mix(color.rgb,vvDryBiomeFogColor(mix(fogColor,skyColor,0.35)),clamp(vvDryBiomeDust,0.0,1.0)*0.97);
#endif
   gl_FragData[0] = color;
}
