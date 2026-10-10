# Miniature labPBR + DH — Vibrant edition v57 (live development)

v57 derives water absorption from the actual biome tint, using the same tint as the scattered water light. The dominant tint channel receives the least absorption and other channels absorb proportionally more. The calculation is shared by native water, DH water and the volume integration; the paths without volumetric water use it as well. Normalized tint separates hue from brightness, so illumination changes do not change the absorption color. Shallow-water transmission and Fresnel reflections remain present.

The authoritative development copy is now the unpacked shaderpacks/miniature-labpbr folder in the 26.3 Shader Testing instance. Changes are applied directly there and can be reloaded in Minecraft without creating a ZIP. Existing saved shader settings are preserved.

v56 addresses shadow-depth clipping after the user isolated the remaining popping by disabling Shadows. Explicit shadowNearPlane=-2048 and shadowFarPlane=2048 replace Iris's default -100.05/156 light-axis depth interval. The selected horizontal shadow distance and resolution stay unchanged. Receiver, colored-glass and volumetric depth offsets are scaled to preserve their previous world-space size. A GPU test rasterizing a ceiling 110 blocks toward the light reproduces the old receiver switching abruptly from lit to shadowed during camera movement; the expanded interval keeps it shadowed at every tested position. The installed Iris directive parser recognizes both new planes. The existing shadow-filter slope tests still pass. This is a controlled reproduction; the recorded world still needs confirmation.

The voxel capture also corrects partial-block classification: full-corner vertices mark a candidate solid cell (1), any inset vertex overrides it as partial (2), and emitter records (3 or greater) override either marker. Previously any outer corner of a slab or stair could close the entire lighting cell. Partial cells now allow voxel light propagation instead of acting as full cubes. This conservatively permits light through partial blocks rather than providing sub-block occlusion; directional shadows continue to use the actual geometry. GPU checks verify partial-cell transmission, full-cell blocking and absence of phantom light sources. No additional voxel textures or propagation passes are added.

v55 fixes missing emitters during Ultra voxel-grid transitions. The nearby field is now 64 cubed; the three distant fields remain 32 cubed, packed alongside it in 128 x 64 x 64 textures. Each transition reserves the full 16-block light influence radius plus interpolation margin. Previously a surface could still select a fine grid after its torch had left that grid, making illumination disappear and then return as the camera moved. This remains voxel replacement lighting, with no vanilla block-light fallback.

GPU regression: a receiver fixed 12 blocks from a torch dropped from 0.10310 radiance to zero in v54 as the camera moved between 16 and 22 blocks. v55 stays at 0.10310 while moving along each of the three axes through 128 blocks. Separate checks retain the v54 surface-normal correction, fine-grid wall blocking, empty-field darkness and source color. The new textures require 18 MiB versus 4.5 MiB previously; the flood has 2.75 times as many active cells, so Ultra lighting costs more. Other profiles do not run the voxel flood. This is a controlled GPU reproduction, not confirmation in the user's village.

v54 removes the Colors submenu from Lighting & Reflections, makes glow squids emissive in integrated and labPBR modes, and gently strengthens the Fresnel lobe on upward-facing water viewed from above. Sky reflection fallback now works in both grading modes; existing sky-access and reflection controls still apply. Underwater critical-angle behavior is retained.

Ultra surface lighting now offsets the voxel lookup along the geometric surface normal while evaluating attenuation at the original surface position. Previously every caller used a zero normal, blending solid (dark) cells with air near surfaces; the coarse grid has no solid cells, so moving the camera could double the same surface's block illumination. A GPU ground-plane regression reproduces radiance changing from 0.38054 to 0.76108 before the correction and remaining 0.76108 after it across camera positions from 0 to 128 blocks. This corrects a demonstrated source of the recorded symptom; real village occlusion and multiple-light behavior still require an in-game check.

v53 adds an untextured geometry pass for leads in every dimension. It preserves vertex color and opacity, applies the selected block-light system and fog, and writes surface metadata that excludes the rope from inherited water/reflection effects and DH overlays. Explicit textured fallback passes preserve texture sampling for other rendering paths; the existing eye and enchantment-glint programs retain their original shared code.

Validation: 240 basic/textured profile variants compile, and 40 Iris-transformed lead variants compile/link on NVIDIA. A GPU draw using the actual Iris-transformed fragment shader preserves brown rope color and opaque coverage, writes the signed entity tag, and clears background water/reflection metadata. In-game appearance still needs confirmation.

Current colored-light behavior: Ultra's voxel lighting replaces static vanilla block illumination, supplying both source color and brightness. The older version notes below describe their behavior at the time, including superseded additive implementations.

v51 removes Adaptive Quality, its target-FPS/minimum-budget controls, and the frame-time quality controller. Reflections, ambient occlusion and atmospheric/water rays always use their selected preset or manual sample counts. Adaptive Exposure retains its existing brightness adjustment and controls.

v52 corrects surface-shadow comparisons shared by Normal, High and Ultra (and Low when shadows are enabled). Four neighboring shadow texels now compare against the receiver plane's depth at each texel, rather than one depth for the entire footprint. Visibility is bilinearly weighted after comparison. Depth and glass-marker textures explicitly use nearest filtering, avoiding interpolated depth from unrelated surfaces. Shadow pixelization retains its world-anchored lookup while deriving depth and derivatives from the continuous surface, so quantization no longer moves the receiver into its own block. Shadow ranges, caster coverage, voxel lighting and water shading retain their existing settings.

GPU checks at Normal's 2048 map/384-block range and High/Ultra's 4096 map/768-block range reproduce false shadows on an unoccluded sloped receiver in v51. v52 stays fully lit through subtexel lookup motion, with pixelization both off and at its default 16, while real occluders remain shadowed. The installed Iris directive parser recognizes both nearest depth samplers and the nearest glass-marker sampler. These controlled checks still require an in-game appearance check.

v32 adds Ultra after High, inheriting all High quality settings and enabling Colored Block Lighting (64 samples). This is a screen-space irradiance estimate from visible emissive terrain using actual integrated/labPBR emission colors, receiver normals, eight-block falloff and four visibility checks. Both grading modes and all dimensions are supported. Off-screen, occluded, tiny or distant sources retain vanilla block lighting; screen-space lighting can fade or undersample as sources leave the view. DH and held lights retain their existing lighting. It supplements existing block illumination rather than providing full voxel colored lighting. The feature is disabled in all earlier profiles and can be toggled under Lighting & Reflections. Strength and sample controls are available. No FPS guarantee or in-game visual verification is claimed.



v31 adds integrated terrain-shadowed air haze and forward-scattered underwater light. Above-water air integration stops at the water surface. Surface sun glint is added after water-volume attenuation, retaining a sharp specular core and a softer specular skirt. Water fog density defaults to 0.5. Caustics default scale is 1.5 (three times finer than v30) with independent moving brightness noise; upward-face and sunlight gating remain. These are approximations of Bedrock volumetrics, not its renderer. Native wave random seeds are anchored to world coordinates. When volumetric water is enabled, native and DH water skip their duplicate per-surface absorption and depth-dependent opacity ramp. Native surface reflection is composited after volume shading; DH water now carries a valid normal for sun glint. DH water now uses the same final reflection path as native water, with a sky fallback instead of invalid native-depth SSR. Clear/stained glass blocks and panes have a distinct Fresnel reflection path with sky fallback, opaque-only SSR and adjustable strength 0.35; their texture alpha is preserved. The near-water line seen in the user recording still requires in-game confirmation.

v30 adds an Overworld sunset bloom multiplier (default 1.75), gated to evening and smoothly faded by solar elevation and rain. Daytime/deep night retain normal bloom. It also raises Water Glint Opacity to 9 and Bloom Radius to 3. Water glint uses a sharp sunlight specular lobe in Vibrant mode rather than a bright color-texture overlay. Water fog defaults to density 0.75 and scattering 0.8. Integrated obsidian uses roughness 0.35. Mapped portals receive controllable HDR emission (default 3). Custom Sift portal renderers must expose blockEntityId for their beam fallback emission. Caustics use animated pixel-aligned mottled highlights, reconstructed upward-facing bed normals, and shadow-map sunlight visibility. Water no longer casts an opaque shadow, allowing sunlight through it. Caustics outside the near shadow map or with shadows disabled are suppressed; depth discontinuities may produce minor edge masking artifacts.

v29 preserves all High preset values. Bloom now uses a half-resolution horizontal Gaussian pass plus five final vertical taps, replacing 25 final taps with five final taps plus five half-resolution taps. The weights retain unit energy and the same blur radius. Rough integrated materials skip GGX/environment and normal-variance work; zero diffuse/skylight skips cloud and shadow calculations. Integrated mode disables resource-pack normal/specular atlas loading, and Normal grading skips the unused bloom passes. No in-game FPS uplift is claimed: the user reports about 230 FPS before these changes.

v28 adds Material Mode: Integrated PBR (default) or labPBR 1.3. Integrated needs no normal/specular resource pack. Unclassified blocks are roughness 1; iron/gold/netherite blocks use 0.28, copper 0.55, diamond/emerald 0.2, ice 0.12, selected polished stone/quartz 0.7. Iron/gold/netherite/copper are metals; gems and ice remain dielectric. Emission uses color masks for bright parts of torches, lit campfires, lit redstone torches, glowstone, sea lanterns, froglights, shroomlights, lit lamps and jack-o-lanterns. Unknown/modded blocks fall back to rough surfaces. Masks depend on color textures; arbitrary packs may need tuning. Entities retain their existing shading; DH has coarse light/color data and retains its existing distant shading rather than detailed per-block materials.

Water retains 0.99 reflection capacity with dielectric Fresnel, so near-normal views still transmit light. Caustics now use a periodic 64-step cellular pattern on the world pixel grid with scale, animation speed, edge contrast and strength controls. This approximates Bedrock’s documented animated projected caustics, not its original texture or full water renderer. Settings now group materials, lighting, water, grading, atmosphere, dimensions and performance. Profiles preserve material mode; High enables enhanced block lighting.

v27 changes Sift motes to camera-facing square planes. Shafts use narrower soft bands, stronger scattering, broader viewing-angle visibility, and twice the previous integration samples (16 Normal / 32 High). Existing terrain shadow occlusion remains; these are stylized beams rather than a reproduction of a proprietary renderer.

v26 replaces the procedural End nebula and stars with Minecraft’s native end_sky.png on six sky faces. Enhanced native-event flashes remain, and the same sky texture fills the horizon and void. End Sky Glow controls brightness.



v25 removes shader-generated Nether cubes and their controls, preserving native biome particles. A shader pack cannot increase native particle spawn counts; that requires a client mod. It also fixes black patches around the sun by using additive celestial blending: the native sun texture has an opaque black background.



v24 fixes an Iris pack-loading crash in DispatchingDirectiveHolder. colortex2/7 clear-color directives now use four explicit float components instead of the GLSL-valid scalar vec4 constructor that this Iris parser does not accept. The installed Iris parser harness now registers all eight buffers and verifies both clear colors as well as the HDR formats; the earlier format-only check registered only buffers 0/3/4 and missed this issue. The original exception was reproduced before fixing it.



v23 adds a dedicated Overworld celestial sprite pass. The sun receives HDR emission before half-resolution bloom extraction, instead of relying on a display-white sprite just reaching the bloom threshold. Sun Bloom Strength is in Color Grading and scales the sun only; zero restores native brightness. Moon brightness stays unchanged, resource-pack sprite opacity is preserved, and rain reduces added emission. Bloom requires Vibrant Visuals and Bloom Strength above zero; Lowest keeps bloom disabled by default. Normal grading keeps the native sprite brightness.



v22 protects rendered surfaces and depthless beacon/particle overlays from End/Sift sky replacement. Mielonâ€™s Sift 1.1.2 uses an animated beacon-style textured fallback when Iris shaders are active; the shader now preserves that texture rather than classifying a depthless portal face as empty sky. The modâ€™s fallback remains its original texture/UV animation, not the separate no-shader procedural pipeline. Sky classification checks a cleared surface marker as well as vanilla and DH depth. This also protects entity rendering when its draw has metadata but no depth entry. Live portal/player verification is still required.



v21 removes the legacy End textured-sky/star projection when the custom sky is enabled. Final now supplies the End sky once instead of adding it to the native background, which could change during the dragon battle. This removes the duplicate star layer and native background tint contribution, retains the native-event sky rift, and keeps near/DH depth masking. Sky direction reconstruction also uses a finite depth to avoid infinite-far projection artifacts. The dragon-fight appearance still needs live verification.



v20 adds a purple-white sky rift with branching streaks and a violet halo synchronized to Iris endFlashIntensity and endFlashPosition. It uses Minecraftâ€™s actual event, rather than adding random flash timers, and is only drawn on sky pixels after checking both normal and DH depth. End Flash Sky Rift and strength controls are in Atmosphere. Works across grading/quality profiles with Sky enabled; the flash is visible when looking toward its native position. This is an original procedural rift, not the vanilla flash texture.



v19 separates opaque and translucent entity passes and prevents water/material metadata blending across entities. Opaque entity color is written without alpha blending; genuine translucent effects retain sprite opacity. Water volume now reads the biome vertex tint carried by visible water, including DH water. Underwater pixels without a visible water surface use native local fog color. These player-opacity and color changes require an in-game check.



v19 adds a dedicated full-bright beacon beam pass with texture/vertex opacity, per-fragment fog and cleared material metadata in every dimension. Material Settings now exposes Metal Factor from zero (dielectric) to one (resource-pack metal), preserving nonmetal values.



v19 removes Nether volumetric scattering. Stronger normal biome-colored fog now applies across both grading modes and all quality profiles, independent of Volumetric Quality. Nether Fog Distance defaults to 96; its falloff is stronger even when old distance settings persist. Shader-generated Sift/Nether motes now use world-oriented cube silhouettes and End sparkles use square masks. Drifting depth-limited shader particles cover Crimson Forest, Warped Forest, Soul Sand Valley and Basalt Deltas, with biome-colored motes, and exclude Nether Wastes via Iris biome constants. Other Nether biomes receive a warm fallback. The player biome selects the style, so the exclusion changes at biome boundaries. These are analytic shader motes rather than spawned Minecraft particle entities. Toggle and amount controls are in Atmosphere.



v18 retunes The Sift to the supplied Dungeons reference: mint/pink pastel sky, pale atmospheric mist, neutral ambient fill, warm key light, depth-limited warm shafts and analytic luminous motes. The sky replaces the native saturated blue only on sky pixels, with DH depth protection. Shafts/motes require Vibrant Visuals and Normal/High; each has a zero-disable strength control in The Sift Atmosphere. Shafts use nearby shadow-map occlusion and approximate parallel atmospheric bands. Motes are shader effects, not spawned entities; this does not reproduce the reference terrain, vegetation, creatures or art assets. Visual matching still requires in-game review.



v17 adds toggleable cloud texture shadows under Shadows, with strength and cloud height controls. These affect direct sunlight/specular lighting on near and DH terrain; block light remains independent. Requires Shadows enabled and the Overworld. The active Minecraft/resource-pack cloud texture is projected at the configured height, with approximate drift; exact cloud geometry synchronization is not claimed. Disable the toggle when clouds are hidden. Lightmap alpha is now explicitly excluded from surface opacity, and caustic highlights are restored at a moderate default after v16 over-reduced them. Player transparency still needs live confirmation.



v16 softens caustics, limits their brightness relative to the receiving surface, and attenuates them with water distance before water fog. Water fog integrates only the visible water segment, with moving ambient scattering on Normal/High and uniform extinction on Low/Lowest. Both grading modes are supported. Water settings expose density, scattering, and a toggle. This is ambient scattering, not shadowed underwater sun shafts.



v9 fixed the undefined RGBA16F compile error. The validation harness no longer

substitutes format identifiers, so it checks the shipped declarations.



v10 samples opaque depth for water SSR, fades uncertain reflection hits, and

labels water explicitly in the material buffer. Caustics are brighter, world-pixel

aligned (16 cells per block by default), and visible on the lake bed from above

as well as underwater. They remain a procedural approximation without temporal

reflection accumulation; screen-space reflections can still miss offscreen objects.



v12 restores Nether atmosphere: fog builds from 8 blocks with a dedicated

distance control, independent of near/DH render distance. Ambient fill follows

the current biome fog color. Both controls are under Atmosphere, work with both

grading modes and all profiles, and retain reduced-distance environmental fog.



v13 restores End atmosphere with dimension-specific purple fog and ambient

lighting, plus a depth-masked purple sky/star fallback for modern Minecraft.

End Fog Distance, End Ambient Fill and End Sky Glow are under Atmosphere.

Both grading modes and all profiles are supported; DH depth protects distant

islands from the sky overlay. Environmental fog remains separate.



v14 adds ray-marched Nether/End fog with moving world-space density, extinction,

and ambient scattering, terminated at normal/DH scene depth. It replaces simple

fog in Vibrant Visuals when enabled and quality is above zero. Normal grading,

Lowest/Low, disabled volumetrics and zero strength retain simple dimension fog.

Atmosphere exposes the toggle, density, dimension fog distances and quality.

This is ambient volumetric scattering, not lava point-light shadowing.



View-frustum culling is explicitly enabled through Iris; occlusion culling remains

enabled. The renderer decides which terrain/entities are outside the camera view.

Shader optimizations stop offscreen reflection rays, skip SSR when Reflections is

zero, skip daylight scattering at night, and terminate dense dimension fog rays

early. Shadow casters are not culled by player look direction because offscreen

objects can cast visible shadows. No frame-rate improvement has been measured.



v15 adds a dedicated configuration for Mielon's The Sift 1.1.2, verified from the

installed mod: `the_sift:the_sift`. It provides cool directional/ambient lighting,

violet shadow grading, world-anchored low mist, subtle animated cyan/violet sky

ribbons, and separately adjustable bloom. **The Sift Atmosphere** contains the

custom controls. Shared Volumetric Quality and dimension volumetric toggle apply:

Normal/High use 8/16 samples; Low/Lowest retain simple Sift fog. Dedicated terrain,

water, particle, shadow, bloom/exposure, final and DH programs are supplied.

Mod vegetation is mapped to thin-plant lighting. Existing mod particles are retained;

no new game entities or particles are spawned. The look is Dungeons-inspired,

not a pixel-perfect reproduction. In-game detection and appearance need testing.



Material format: **labPBR 1.3**. Based on mateuskreuch/minecraft-miniature-shader

at commit `bdb6e0020b4318d4e845902cbcc3e3552b0e9274`. Original MIT license retained.



## Install and enable



1. Copy `Miniature-labPBR-DH-v31.zip` into your instance's `shaderpacks` folder.

2. Select v31 in Iris and enable your labPBR resource pack.

3. **Shader Options â†’ Color Grading â†’ Vibrant Visuals** enables the new rendering

   style. This is the default in v15; Normal remains available.

4. Select **Normal** or **High** quality. High enables Enhanced Block Lighting.



The quality profile and the color-grading mode are separate controls. Selecting

Normal *quality* still allows Vibrant Visuals *color grading*. Most new effects

apply only in Vibrant Visuals mode. Material strengths remain independently editable.

DH rendering is automatic when a compatible Distant Horizons installation is present.

The target tested by compilation is Iris 1.11.7 with Minecraft 26.3. In-game

appearance and mod integration still require testing. OptiFine is unverified.



## New rendering features



- **HDR scene color:** RGBA16F retains bright lighting through the scene and

  reflection passes, with a hue-preserving shoulder applied after exposure.

- **Adaptive exposure:** scene luminance is metered on a center-weighted 16Ã—9 grid,

  excluding the held-item depth range and reducing sky influence. A persistent

  one-pixel HDR buffer smooths exposure over time using frame duration. Minimum,

  maximum and speed are editable; manual Exposure multiplies the adapted value.

  This replaces the earlier eye-light-level approximation. Requires Vibrant

  Visuals grading and Adaptive Exposure enabled.

- **Balanced sunsets:** warmer sunlight, readable outdoor shadow detail, moderate

  saturation, and less uniformly orange fog. Cave lighting is not raised by the

  outdoor shadow adjustment.

- **Height fog:** altitude-dependent atmospheric density with editable base height

  and density. Nearby and DH terrain share this approximation; environmental

  fog, including underwater and blindness, keeps its own distance controls.

- **Sun rays:** ray-marched atmospheric scattering tests the existing shadow map

  so nearby walls and terrain can occlude light. Overworld only; limited to the

  available shadow coverage. It does not create DH shadow geometry.

- **Contact occlusion:** a deterministic depth/hemisphere screen-space approximation

  darkens nearby creases. Excludes sky, the held-item depth range, and translucent

  surfaces. It complements material AO rather than replacing it.

- **Bloom:** a half-resolution HDR bright-pass buffer is filtered in the final

  pass. Strength and radius are editable. This is screen-space glow, not emitted

  light illuminating neighboring geometry.

- **Sky reflections:** an analytic sky/horizon environment fills missing labPBR

  and water reflections. Roughness softens the procedural material fallback;

  indoor skylight suppresses it on labPBR terrain. This is not a captured cubemap,

  filtered environment map, or a reflection of offscreen buildings.

- **Water:** depth-dependent absorption and opacity, grazing-angle Fresnel,

  sky reflection fallback, underwater colored attenuation, and an animated

  caustic-pattern approximation on visible submerged surfaces. Glass keeps its existing path.

  DH water receives simplified absorption and sky reflection but has no waves.



## Quality profiles



| Quality | Bloom strength | Contact AO samples | Sun-ray samples | Enhanced block lighting |

| --- | --- | --- | --- | --- |

| Lowest | Off | Off | Off | Off |

| Low | 0.05 | Off | Off | Off |

| Normal | 0.12 | 4 | 8 | Off |

| High | 0.20 | 8 | 16 | On |



These defaults accompany the existing shadow resolution/distance and SSR settings.

Effects can be adjusted individually under **Color Grading** and **Water**. Selecting

another profile reapplies its effect defaults. Exposure, grading choice, fog height,

material strengths, and other controls remain independent of profile presets.



## labPBR materials



Opaque/cutout terrain uses `_n` and `_s` atlases in all four dimensions. DirectX

normal RG channels affect surface lighting; normal blue supplies material AO.

Specular red provides perceptual smoothness converted to linear roughness. Green

0â€“229 provides linear F0; metal IDs 230â€“255 use linear albedo as approximate F0.

Specular alpha 0â€“254 provides emission; 255 is explicitly non-emissive.



Normal strength, roughness scale, specular strength, occlusion strength, and emission

brightness are editable. Thin crossed vegetation preserves Miniature's flat plant

lighting and avoids solid-surface highlights. Material AO is applied in linear

lighting. Surface-normal variation broadens undersampled specular highlights.



**Enhanced Block Lighting** applies local lightmap/held-light intensity directly

to diffuse and reflective materials, including metals. High enables it; the other

profiles disable it. Off retains the previous ambient-dependent torch contribution.

This is isotropic lighting: the shader has no individual emitting-block positions

for directional block-light highlights or shadows. Emissive textures do not cast

light onto adjacent blocks. Metals do not use individually measured optical constants.



No parallax displacement, wetness/porosity, subsurface scattering, global illumination,

ray tracing, or temporal antialiasing is implemented. Entities/held items keep their

original material path while receiving global postprocessing.



## Distant Horizons and particles



Dedicated DH terrain/water programs exist in Overworld, Nether and End. They use

LOD vertex colors, face normals and normalized lightmap data; distant geometry has

no labPBR atlas. Terrain receives nearby shadows within the useful shadow-map range.

DH shadow casting is disabled. Fog and final grading include distant terrain.



DH depth is reconstructed using `dhProjectionInverse`. DH water checks nearby

opaque depth in view space to avoid drawing over Minecraft blocks. SSR validates

surface thickness to reject hits across silhouettes; offscreen geometry cannot be

reflected. Near/LOD color and geometric transitions can remain visible.



Both DH stages contain Chunks Fade In's supported `_cfi_ignoreMarker` opt-out to

avoid its faulty DH fog-declaration reordering. Its DH fading/motion/LOD-mask

injections are bypassed. Dedicated opaque/translucent particle passes preserve

sprite alpha and vertex opacity, lightmap brightness, and shared fog in all dimensions.



## Validation and test checklist



Compiler checks cover all four profiles, both grading modes, labPBR on/off, and

terrain, entities, hand, water, particles, bloom composite, final, available sky/cloud

passes, and DH terrain/water in all four dimensions. Additional checks cover the

new final/bloom/material/water paths without DH. Standalone compilation promotes

legacy GLSL 120 to 130, expands includes, supplies DH IDs, and leaves the

format declarations intact. The shader defines RGBA16F explicitly as a GLSL

integer constant while retaining symbolic format directives for Iris. NVIDIA driver checks compile/link these programs.

Iris's installed transformer is also exercised for DH and postprocessing programs

using minimal game/device/configuration stubs. These are not Minecraft rendering

or frame-rate tests and do not certify visual correctness.



Check daylight, sunset, caves, emissive textures, moving specular highlights,

normal-mapped blocks, crossed grass, torch particles, water through/behind walls,

shallow/deep water, underwater scenes, the near/DH transition, Nether, End, and The Sift.

Try Normal grading as well as Vibrant Visuals. For performance, reduce sun-ray

quality first, then contact AO and bloom. This edition adds an HDR scene buffer

and a half-resolution HDR bloom buffer; High performs more texture samples.



References:

- https://shaderlabs.org/wiki/LabPBR_Material_Standard

- https://shaders.properties/current/reference/mod-support/distant_horizons/

- https://learn.microsoft.com/en-us/minecraft/creator/documents/vibrantvisuals/lightingcustomization



Exposure validation: an isolated NVIDIA rendering test executes the actual

composite1 shader against synthetic dark and bright scene textures, updates its

RGBA16F history for 180 frames, and verifies exposure moves toward the dark/bright

limits. Frame-duration adaptation is also checked at 30, 60 and 144 FPS numerically.

This verifies metering/history math, not live Minecraft framebuffer integration.


Translucent solid blocks discard back-facing fragments. Water and portal surfaces remain two-sided for underwater and portal viewing.

v32 also makes the glass strength apply to the legacy translucent fallback and clamps the final glass reflection explicitly. Water classification uses a dedicated water flag, independent of reflectivity sliders. Volumetric/Vibrant water supplies surface reflection plus volume absorption/scattering without extra surface tint blending in native/DH overlap. DH water uses matching world-anchored waves and untampered biome tint, and opaque reconstruction compares native/DH view-space depths. These changes target the DH-dependent line/pop reported by the user; in-game verification remains necessary. Water Sun Glint is independently adjustable (default 2). Glass casts neutral sun shadows; Ultra enables transmission-tinted stained-glass shadows (single front-most shadow layer). Clear glass transmits neutral light.

v33 masks the native water sun reflection with the animated water atlas. Texture detail appears only within the directional sun highlight, with no separate water overlay. Textured Sun Reflection defaults to 1.0 (fully textured); 0.0 restores the smooth highlight. The mask is independent of surface alpha, preserving the DH overlap changes. DH has no animated atlas and retains its smooth distant sun reflection. Both material modes and all five quality presets retain the option.

v34 replaces procedural caustic shapes with the resource-pack water_still sprite used by the animated native water mask. The vertical animation sheet advances at the vanilla rate of ten frames per second at Caustics Speed 1. Custom frame order/timing from resource-pack mcmeta files is not interpreted. Pixel alignment, spatial brightness noise, upward-face gating, sun shadows, rainfall attenuation and exponential water-depth falloff remain. Sun color is white at midday and smoothly warms toward sunrise and orange sunset; daylight fades it at night. Default Water Caustics strength is 2.0, up from 0.6, with expanded adjustment range up to 4.0. In-game appearance remains to be verified.

v34 also adds a weaker textured moon reflection (Water Moon Glint 0.15 versus Water Sun Glint 2.0). Moon elevation, lunar phase, rain and shadow visibility attenuate it; a new moon produces no lunar highlight. The existing moon RGB controls tint it. Both grading modes support it.

v34 checks DH water against both current native depth and the opaque depth snapshot. DH water receives a separate material tag so final can reject water fog/reflections when a nearer native player, entity or block occupies the pixel. The screenshot-reported player overlap requires in-game confirmation.

v35 hotfix: bundles the vanilla 16x512 water animation sheet as a shader-owned custom PNG. This avoids the runtime TextureManager/GeckoLibAnimatedTexture upload that crashes Minecraft 26.3 with an active render pass. GLSL animation and lighting are unchanged. Caustics now use the bundled vanilla water pattern; resource-pack water sprite overrides are not automatically loaded for caustics. Native surface highlights still use the active resource-pack atlas. In-game launch confirmation remains necessary.

v36 adds low-skylight Overworld ambient fill (Cave Ambient Brightness 0.08) and disables Glowing Ores by default. Opaque/translucent entity programs now decode labPBR normal/specular maps using derivative tangents for entity meshes. Integrated mobs default to rough materials, with neutral iron-golem texture regions using roughness 0.45 and metallic response; vines remain rough, and bright warm blaze/magma-cube pixels emit. Existing shared material controls apply. Custom mod renderers that bypass these entity programs may not expose PBR textures. In-game visual verification remains necessary.


### v37 cave water
Water sky reflections and celestial highlights now require local skylight. Water scattering uses local sky and block light, and sloped flowing water retains its surface normal.


### v38 iron golem
Integrated iron golem materials use a broader body mask, reduced metal response, and higher roughness for subtle reflections. Vines and eyes stay matte. LabPBR texture-pack materials remain controlled by their maps.

Integrated materials also give Drowned cyan markings a restrained glow and metal tool heads subtle specular response. Tool handles stay matte. Item identification follows Iris currentRenderedItemId.


### v39 water normal fix
Wave strength is applied once before normal encoding for native and DH water. Removes the normal-angle threshold that could leave full-amplitude waves and warp reflections into large patches. Preserves sloped flowing-water normals and v37 local cave lighting.


### v40 tool highlights
Integrated metal tool heads have lower roughness for visible moving highlights. Held tools retain directional celestial highlights without shadow maps in the Overworld. Local block-light irradiance remains isotropic; the lightmap supplies intensity, not source positions.

Water transmission uses the same Fresnel response in Normal and Vibrant grading. Two-sided water faces use absolute view cosine, preventing underside faces from becoming opaque mirrors. SSR sky depths are rejected with or without DH.

Vibrant water absorption is reduced for better underwater visibility. Broad water reflections retain at least 25% transmission; the separate celestial glint is unaffected.


### v41 twilight rays and profile order
Warm sunrise/sunset shafts reuse the shadowed air volumetric pass with a smooth sun-elevation envelope. Enabled by default on Normal/High/Ultra in Vibrant grading; toggle and strength are in Atmosphere. Presets now constrain the same options so Iris cycles Lowest, Low, Normal, High, Ultra.


### v42 adaptive quality
Optional Adaptive Quality under Performance targets 120 FPS by default. A persistent controller, smoothed frame times, an 8% dead band, startup delay and slower recovery adjust SSR, AO, colored lights and volumetric sample budgets between 50% and the selected preset maximum. Brightness and ray coverage are normalized to the active budget. Shadow resolution stays fixed. CPU stalls, VSync/FPS limits and scene complexity can affect the controller; FPS is not guaranteed. Disabled by default so existing manual presets retain their quality.

Twilight beams now scatter additively with a broader angular response and soft highlight limiting. Increasing beam visibility does not increase fog opacity.

Sift shafts use broader soft edges, stronger illumination and the same soft limiting, independently of fog and mote brightness.

Colored-light source sampling now filters premultiplied emission over each sample footprint to suppress repeated flame-shaped patches near wall torches.


### v43 world-space colored light
Original 32-cubed block volume, shadow-stage voxelization and 16 compute flood passes replace screen-space source sampling. Ultra requires Iris custom images/compute support. Known vanilla sources have distinct colors, with warm fallback for other emitting blocks. Captured lights can illuminate while off screen within 16 blocks of the player; edge fading and approximate full-block occlusion apply. Adaptive Quality is on by default; fog rays are brighter. Architecture references: https://github.com/sixthsurge/photon/tree/main/shaders/include/lighting/lpv and https://github.com/ComplementaryDevelopment/ComplementaryReimagined .

In v43 the obsolete colored-light sample slider is removed. Adaptive quality adjusts reflection, AO and fog samples; the colored-light volume retains a fixed propagation budget. Colored-light compute passes and the added Nether/End voxel shadow capture are disabled when Colored Block Lighting is off.

### v44 narrow atmospheric rays
Twilight and Sift rays use smaller soft light columns, reduced intensity and a faint fringe. Sift columns drift slowly while a separate moving cloud-opening noise modulates their intensity. This is procedural overhead occlusion, combined with terrain shadows; it does not add visible clouds. Fog opacity remains unchanged.

### v45 colored-light coverage
Four packed 32-cubed light clipmaps replace the fixed near-camera volume. The outer coverage tracks native render distance; overlapping cascades blend to retain color as the camera moves away. Outer cells are coarser and omit solid-block voxel occlusion to avoid oversized false blockers; distant illumination is approximate and may leak through walls. Source falloff is separate from the render-distance cutoff. Compute volume work is four times v43/v44; benchmark Ultra in game. Redstone blocks are integrated emissive red sources.

Sun rays return to the v43 shadow-driven distribution and intensity, with only a 5.5% soft shadow-edge fringe. Removes v44 periodic sunlight columns; Sift movement is retained.

### v46 source-colored block illumination
With Colored Block Lighting enabled (Ultra default), the native terrain, entity and translucent block-light palette samples the propagated source hue instead of adding warm torch light beneath every colored source. Lightmap intensity and held-light falloff remain. Soul fire/torches/campfires/lanterns use blue; copper torches and all copper lantern weathering/waxed variants use green. Copper lanterns have a dedicated source ID. No colored volume means the existing warm fallback.

Ultra shadow capture uses a positive render multiplier; the v45 zero multiplier could set Iris terrain shadow render distance to zero. Low/Normal now enable entity shadows, and entity shadow distance uses the terrain range. Lowest remains shadow-free. In-game shadow confirmation is pending.

Water reflections are now composed on the underwater surface in Vibrant grading. Water-to-air critical-angle reflection makes the underside visible at grazing angles while retaining overhead transmission. Default caustics strength is 3.0 (was 2.0).

### v47 water and shadow fixes
Underwater reflection misses retain transmission instead of forcing an opaque blue fog fill; SSR still requires a visible scene hit. Thin terrain and entities carry a negative eligibility tag in the preserved opaque material buffer, excluding them from caustics. Player skin draws opaque covered texels on the translucent entity path. Shadow lookup includes opaque entity depth from shadowtex0 while preserving glass transmission. Default shadow ranges: Low 128, Normal 384, High/Ultra 768 blocks, with fade restricted to the outer range. Normal uses a 2048 shadow map. Actual loaded terrain bounds shadow coverage; in-game verification remains required.

Default auto-exposure maximum is 2.0 (was 4.0); the existing adjustment range remains available.

### v48 recording follow-up
Player opacity mapping includes Iris current_player and player_cape IDs. Entity shadow stages no longer use terrain mc_Entity flags or vertex alpha, preserving skin texture cutouts. Shadow comparison uses direct depth visibility with four filtered taps; default shadow darkness is 0.3. Water waves use continuous world-space phases instead of floor/hash seeds that can switch at camera-dependent vertex boundaries, and SSR confidence fades over a wider error interval. Recording inspected; actual fixes still require in-game verification.

Native water entry reconstruction now uses native depth whenever present, rather than preferring a nearer DH sample. Both DH terrain and water reject nearer native surfaces, and an explicit opaque-entity material tag protects already-rendered entities from later DH overwrites.

Validation: 1,320 profile/program pairs compile. Hidden NVIDIA OpenGL draw checks confirm covered player pixels output alpha 1 and write depth, and entity/block-entity shadow geometry writes depth even with stale water attributes and zero vertex alpha. These are controlled shader tests, not confirmation inside the modded game.

### v49 shadow coverage and player atmosphere
The shadow shader uses output alpha zero for opaque casters and one for glass transmission. Iris's inherited cutout test was rejecting opaque shadow output after the shader's own texture-coverage test. `alphaTest.shadow=off` delegates coverage to the explicit shader test, retaining transparent texture cutouts and excluding water. The previous shadow draw test omitted Iris's inherited test; v49 reproduces the rejection with an actual Iris-transformed fragment shader before checking the corrected draw.

The preserved material buffer now uses RGBA16F on every profile. Previously High and lower profiles used normalized RGBA8, which clamped the negative entity/vegetation tags to zero. Signed entity tags now remain available to the DH overlay guard; vegetation remains excluded from caustics. Above-water atmospheric scattering stops at the front depth of marked entities, including player render types omitted from the opaque-only depth buffer, rather than integrating sky-colored haze to the background behind them. Water shading is unchanged.

Validation: 1,320 profile/program pairs compile; Iris parses the float formats and clear colors; NVIDIA compilation/linking passes for 162 Iris-transformed program variants. GPU regression draws reproduce v48 opaque-shadow rejection and verify v49 depth coverage, texture-coverage rejection, opaque player output and the signed entity tag through the High shader's actual material output. These checks do not establish the final appearance in the modded game.

### v50 exclusive and stable voxel block lighting
Colored Block Lighting (Ultra default) now replaces the static vanilla block-light term with voxel-derived radiance in terrain, entity, translucent and DH shading. The final-pass additive light is removed, and an empty voxel field no longer falls back to warm vanilla illumination. Sun/moon lighting, ambient fill, material emission and held-item dynamic light remain separate. Turning Colored Block Lighting off restores the previous vanilla block-light path; Colored Light Strength scales the voxel contribution only.

The clipmaps propagate emitter position and source palette instead of attenuated cell brightness. Receivers evaluate falloff in world units, then interpolate radiance rather than source coordinates or palette IDs. This avoids oversized coarse-cell light footprints and the changing brightness when moving between clipmaps. Source influence fades naturally between 12 and 16 blocks; viewer coverage still follows native render distance. Sources use one dominant emitter per cell, and distant clipmaps still omit solid occluders, so this remains approximate lighting with possible distant leaks or source collisions.

The four 32-cubed clipmaps use 32 propagation passes and two RGBA32F source textures (4 MiB combined, plus the 0.5 MiB capture texture). This increases Ultra's compute work and memory compared with v49; other profiles keep their existing lighting and disable the voxel passes. No in-game FPS change is claimed.

Validation: 1,320 profile/program pairs and 256 enabled/disabled compute variants compile. NVIDIA compilation/linking passes for 162 shadow regression variants and 88 DH variants after Iris transformation. A NVIDIA GPU regression reproduces more than 2x brightness variation in v49 at a fixed world point as the camera moves, while v50 stays within floating-point noise across the same near/coarse transitions. Draw checks verify blue and green source colors, fine-grid wall blocking, independence from native block-light intensity, and zero static illumination for an empty field. These controlled checks do not confirm the modded game's final appearance or performance.
