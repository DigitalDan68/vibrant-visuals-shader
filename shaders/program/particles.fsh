#include "/shader.h"
uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform float rainStrength;
varying vec2 texUV;
varying vec2 lightUV;
varying vec4 particleColor;
varying float particleFog;
varying vec3 particleFogColor;
#include "/common/particle_rain.glsl"
void main() {
   vec4 albedo = texture2D(gtexture, texUV) * particleColor;
   if (albedo.a < 0.001) discard;
   // Preserve sprite/animation opacity; lighting affects RGB only.
   // Iris supplies no particle-type ID. Redstone dust uses a saturated red
   // vertex tint; classify that tint rather than red pixels in other sprites.
   float redTint = smoothstep(0.08,0.16,particleColor.r)
                 * (1.0-smoothstep(0.08,0.18,max(particleColor.g,particleColor.b)/max(particleColor.r,0.001)));
   vec3 litParticle = albedo.rgb * texture2D(lightmap, lightUV).rgb;
   float rainParticle = 0.0;
   if (rainStrength>0.001 && redTint<0.01)
      rainParticle=vvParticleRainSprite(texUV);
   litParticle *= mix(vec3(1.0),vec3(0.28,0.38,0.48),rainParticle);
   albedo.a *= mix(1.0,WEATHER_OPACITY,rainParticle);
   // Full-bright red with a small HDR lift for bloom. Keep sprite alpha intact.
   albedo.rgb = mix(litParticle,albedo.rgb*1.8,redTint);
   albedo.rgb = mix(albedo.rgb, particleFogColor, particleFog);
   /* DRAWBUFFERS:07 */
   gl_FragData[0] = albedo;
   gl_FragData[1] = vec4(0.0,0.0,0.9,1.0);
}
