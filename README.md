# Vibrant Visuals Shader: A fork of Miniature shader by ukrech

A modified fork of [Miniature shader by ukrech](https://github.com/mateuskreuch/minecraft-miniature-shader). The original MIT license and copyright notice are included in LICENSE; the original README is preserved in README_ORIGINAL.md.

## Installation

Download the shader ZIP from Releases, place it in your Minecraft shaderpacks folder, and select it in Iris. For development, put this repository folder in shaderpacks; its shaders directory must be directly inside that folder.

Developed against Minecraft 26.3 with Iris 1.11.7, Sodium, and Distant Horizons. Includes Lowest, Low, Normal, High, and Ultra profiles, plus Overworld, Nether, End, and The Sift dimension programs.

## Settings

Entity Emission Lighting is under Lighting & Reflections. It is enabled by default on Ultra. Disabling it preserves texture glow while removing nearby illumination. Emission from fully culled entities cannot be captured by the shader.

Integrated materials allow resource-pack normal and specular maps to override their defaults. Resource-pack compatibility options are available under Materials.

## LambDynamicLights

Enable LambDynamicLights Compatibility under Lighting when using the mod. It disables competing shader held/entity cast lights, preserves emissive textures, and blends known held-source hues with static voxel lighting. Lightmap-only moving-source colors are approximate. Install the companion resource-pack ZIP from the same release into resourcepacks for enchanted items, custom emitters and supported emissive mobs. Enable it in Resource Packs, then reload resources. See its README for species-wide approximations and unsupported state-only emission.

## Validation

2026-10-10: 2,100 profile/program compilation checks, 440 targeted checks without Distant Horizons, 256 block-light compute checks, and 8 entity compute checks passed. GPU checks cover entity alpha and ETF overlays, emission capture across layers, hidden-face capture, the disabled toggle, underwater illumination, wall/range rejection, and temporal smoothing. All shader files and includes were audited.

These checks do not establish in-game FPS or confirm every previously reported visual issue. Reload and test the final package in your world.

## Compatibility and development status

This is a development fork. Minecraft 1.21.1 and 1.21.11 are planned compatibility targets and have not yet been tested. Current validation used an NVIDIA RTX 5060 Ti; AMD and Intel hardware have not been tested. The current shader requires OpenGL 4.3 across all profiles and does not support native macOS OpenGL on Apple Silicon.

Recent changes include LambDynamicLights compatibility, continuous held/static color blending, two-source voxel propagation, enchanted held-item lighting and emissive redstone-tinted particles. Without LambDynamicLights compatibility, held enchantment lighting is controlled by Hand Dynamic Lighting and depends on the held glint render pass. With compatibility enabled, enchantment rules in the companion resource pack control it. Redstone particles are identified by their vertex tint, so similarly tinted custom particles may also glow.

## Credits

Original Miniature shader: ukrech (Mateus A. Kreuch). Fork maintained by DigitalDan68. This project is not an official Mojang or Microsoft shader pack. Original MIT license retained.
