# Animated emission reference

Derived per-pixel RGB and brightness bounds from all frames of native Minecraft Java 26.3 block animations, extracted from the installed client. Original assets: Mojang / Microsoft. No external texture is loaded during a render pass.

Static texels have zero emission; varying texels emit only while brighter than their darkest animation state. Existing material/color masks still restrict flames, lantern interiors, and cyan sculk pixels. These bounds target the stock textures; replacement texture packs need matching envelopes or authored emission maps.

{
  "sculk": {
    "frames": 4,
    "animated_pixels": 21,
    "total_pixels": 256
  },
  "sculk_vein": {
    "frames": 4,
    "animated_pixels": 27,
    "total_pixels": 256
  },
  "sea_lantern": {
    "frames": 5,
    "animated_pixels": 245,
    "total_pixels": 256
  },
  "lantern": {
    "frames": 3,
    "animated_pixels": 18,
    "total_pixels": 256
  },
  "soul_lantern": {
    "frames": 3,
    "animated_pixels": 14,
    "total_pixels": 256
  },
  "copper_lantern": {
    "frames": 3,
    "animated_pixels": 18,
    "total_pixels": 256
  },
  "exposed_copper_lantern": {
    "frames": 3,
    "animated_pixels": 18,
    "total_pixels": 256
  },
  "weathered_copper_lantern": {
    "frames": 3,
    "animated_pixels": 18,
    "total_pixels": 256
  },
  "oxidized_copper_lantern": {
    "frames": 3,
    "animated_pixels": 18,
    "total_pixels": 256
  },
  "lava_still": {
    "frames": 20,
    "animated_pixels": 256,
    "total_pixels": 256
  },
  "lava_flow": {
    "frames": 16,
    "animated_pixels": 1024,
    "total_pixels": 1024
  },
  "fire_0": {
    "frames": 32,
    "animated_pixels": 198,
    "total_pixels": 256
  },
  "fire_1": {
    "frames": 32,
    "animated_pixels": 203,
    "total_pixels": 256
  },
  "soul_fire_0": {
    "frames": 32,
    "animated_pixels": 203,
    "total_pixels": 256
  },
  "soul_fire_1": {
    "frames": 32,
    "animated_pixels": 198,
    "total_pixels": 256
  },
  "campfire_fire": {
    "frames": 8,
    "animated_pixels": 158,
    "total_pixels": 256
  },
  "campfire_log_lit": {
    "frames": 4,
    "animated_pixels": 87,
    "total_pixels": 256
  },
  "soul_campfire_fire": {
    "frames": 8,
    "animated_pixels": 157,
    "total_pixels": 256
  },
  "soul_campfire_log_lit": {
    "frames": 4,
    "animated_pixels": 87,
    "total_pixels": 256
  },
  "crimson_stem": {
    "frames": 5,
    "animated_pixels": 63,
    "total_pixels": 256
  },
  "warped_stem": {
    "frames": 5,
    "animated_pixels": 63,
    "total_pixels": 256
  },
  "nether_portal": {
    "frames": 32,
    "animated_pixels": 256,
    "total_pixels": 256
  }
}

Also includes both sculk shrieker inner-top animations (normal and can-summon). The shader does not emit from its static casing.
