# Vibrant Visuals Shader: A fork of Miniature shader by ukrech

A modified fork of [Miniature shader by ukrech](https://github.com/mateuskreuch/minecraft-miniature-shader). The original MIT license and copyright notice are included in LICENSE; the original README is preserved in README_ORIGINAL.md.

## Installation

Download the shader ZIP from Releases, place it in your Minecraft shaderpacks folder, and select it in Iris. For development, put this repository folder in shaderpacks; its shaders directory must be directly inside that folder.

Developed against Minecraft 26.3 with Iris 1.11.7, Sodium, and Distant Horizons. Includes Lowest, Low, Normal, High, and Ultra profiles, plus Overworld, Nether, End, and The Sift dimension programs.

## Settings

Shader entity illumination and colored block lighting have been removed. Emissive textures and bloom remain. Ultra increases quality settings and enables underwater light shafts and colored glass shadows.

Integrated materials allow resource-pack normal and specular maps to override their defaults. Resource-pack compatibility options are available under Materials.

## Water and atmosphere

Water includes animated Bedrock normal and caustics assets, turquoise absorption and scattering, textured reflections and independent water volumetric quality. Water and atmosphere support up to 128 samples. Water light shafts are enabled by Ultra; lower profiles disable them. Shafts appear only underwater, scale with murkiness, and fade out between 22 and 30 blocks. Conduit Power and Night Vision reduce underwater fog. Caustics default to scale 2 and strength 6. Asset origins are recorded in shaders/textures/WATER_ASSET_SOURCE.md.

Biome atmosphere and dry-biome storms include smooth palette transitions and square wind-blown particles. Integrated PBR specular is capped at 25%, with texture-selective emission for lanterns, glow lichen, sculk and other emitters.

Caustics through underwater glass enclosures remain unresolved; the experimental changes were reverted.

## LambDynamicLights

Enable LambDynamicLights Compatibility under Lighting when using the mod. LDL supplies dynamic light through the native lightmap; the shader preserves surface glow and avoids competing held lights. LDL does not supply custom RGB light colors.

Install the separate Dynamic Lights ZIP from the release into resourcepacks and enable it for enchanted items, custom emitters and supported emissive mobs. The companion pack currently targets Minecraft 26.3. Its mob rules are species-wide approximations; see companion-resourcepack/README.txt for state-only emission limitations.

## Compatibility and development status

Version 1.0.0 is the first stable release of this fork. Minecraft 1.21.1 and 1.21.11 are planned compatibility targets and have not yet been tested. Current validation used an NVIDIA RTX 5060 Ti; AMD and Intel hardware have not been tested. The current shader requires OpenGL 4.3 across all profiles and does not support native macOS OpenGL on Apple Silicon.

The End retains stars against a black sky, with native flashes illuminating a void-origin gradient colored from the Enderman eye texture. Biome sky transitions use a direct cross-dissolve. Darkness uses a consistent final-scene fade; Night Vision, Nausea, Blindness and Conduit Power have been checked in-game by the player.

## Credits

Original Miniature shader: ukrech (Mateus A. Kreuch). Fork maintained by DigitalDan68. This project is not an official Mojang or Microsoft shader pack. Original MIT license retained.

## Disclaimer 

This Shader fork heavily relies on Generative AI (Codex) for code. I'm not the best programmer but plan on learning as time goes on. I really want this shader to just exist and this was my way of getting it here. Thank you for your understanding.  
