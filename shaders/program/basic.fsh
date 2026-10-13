#ifdef ENTITY_GLOW_PASS
#include "/shader.h"
#endif
#ifdef ENCHANTMENT_GLINT_PASS
#include "/shader.h"
#if HAND_DYNAMIC_LIGHTING >= 0 && !defined LAMB_DYNAMIC_LIGHTS
uniform int renderStage;
layout(r32ui) uniform uimage2D enchantedHeldImage;
#endif
#endif
uniform sampler2D gtexture;
uniform sampler2D lightmap;

varying vec2 lightUV;
varying vec2 texUV;
varying vec4 color;

void main() {
#ifdef ENTITY_GLOW_PASS
   /* DRAWBUFFERS:0 */
   vec4 emissive=texture2D(gtexture,texUV)*color;
   if (emissive.a<0.01) discard;
   gl_FragData[0]=emissive;
#elif defined ENCHANTMENT_GLINT_PASS
   // Glint geometry has UVs but no lightmap attributes. Preserve native tint,
   // animation and GlintAlpha; the render type supplies its overlay blending.
   /* DRAWBUFFERS:0 */
   vec4 glint = texture2D(gtexture,texUV)*color;
   if(glint.a<0.001) discard;
   gl_FragData[0]=glint;
#if HAND_DYNAMIC_LIGHTING >= 0 && !defined LAMB_DYNAMIC_LIGHTS
   // A frame-cleared flag avoids intensity depending on glint pixel count.
   if (renderStage == MC_RENDER_STAGE_HAND_SOLID || renderStage == MC_RENDER_STAGE_HAND_TRANSLUCENT || (renderStage == 0 && gl_FragCoord.z < 0.56))
      imageAtomicOr(enchantedHeldImage,ivec2(0),1u);
#endif
#else
   gl_FragData[0] = texture2D(gtexture, texUV)
                  * texture2D(lightmap, lightUV)
                  * color;
#endif
}
