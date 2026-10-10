# Vibrant Visuals Shader: A fork of Miniature shader by ukrech

A modified fork of [Miniature shader by ukrech](https://github.com/mateuskreuch/minecraft-miniature-shader). The original MIT license and copyright notice are included in LICENSE; the original README is preserved in README_ORIGINAL.md.

## Installation

Download the shader ZIP from Releases, place it in your Minecraft shaderpacks folder, and select it in Iris. For development, put this repository folder in shaderpacks; its shaders directory must be directly inside that folder.

Developed against Minecraft 26.3 with Iris 1.11.7, Sodium, and Distant Horizons. Includes Lowest, Low, Normal, High, and Ultra profiles, plus Overworld, Nether, End, and The Sift dimension programs.

## Settings

Entity Emission Lighting is under Lighting & Reflections. It is enabled by default on Ultra. Disabling it preserves texture glow while removing nearby illumination. Emission from fully culled entities cannot be captured by the shader.

Integrated materials allow resource-pack normal and specular maps to override their defaults. Resource-pack compatibility options are available under Materials.

## Compatibility and development status

This is a development fork. Minecraft 1.21.1 and 1.21.11 are planned compatibility targets and have not yet been tested. Current validation used an NVIDIA RTX 5060 Ti; AMD and Intel hardware have not been tested. The current shader requires OpenGL 4.3 across all profiles and does not support native macOS OpenGL on Apple Silicon.

## Credits

Original Miniature shader: ukrech (Mateus A. Kreuch). Fork maintained by DigitalDan68. This project is not an official Mojang or Microsoft shader pack. Original MIT license retained.

## Disclaimer 

This Shader fork heavily relies on Generative AI (Codex) for code. I'm not the best programmer but plan on learning as time goes on. I really want this shader to just exist and this was my way of getting it here. Thank you for your understanding.  
