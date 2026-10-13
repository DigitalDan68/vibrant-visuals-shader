# Vibrant Visuals debug-world checklist

Record Minecraft, Iris, Sodium, DH and LDL versions, GPU, profile, resource packs and shader settings for each test. Take matching screenshots before changing one setting at a time. Label failures with coordinates and steps to reproduce. This is a manual checklist, not a claim of tested compatibility.

## 1. Redstone signal station
- Build a repeater feeding exactly 15 dust segments. Label powers 15 through 1; add a disconnected power-0 segment.
- Check at night and noon: strongest glow at 15, clearly decreasing brightness toward 1, no emission at 0. Compare bloom on/off.
- Add powered/unpowered repeaters, comparators in both modes, floor/wall torches, lamps and redstone blocks. Check stone bases do not glow accidentally.
- Test vanilla textures and the pack that routes dust through the translucent pass.

## 2. Emissive materials station
- Arrange regular/soul/copper torches, lanterns, fire and campfires; glowstone, sea lanterns, shroomlights, all froglights, end rods, beacon, glow lichen and copper bulbs.
- Include lit/unlit bulbs of every oxidation stage, waxed and unwaxed. Check lit faces bloom and unlit faces remain ordinary.
- Add ores, crimson/warped stems and stripped variants. Check emission stays on intended flecks/veins.
- Fire and soul fire should not cast flame-shaped shadows; supporting blocks should still cast shadows.

## 3. Metal and resource-pack station
- Iron blocks, bars, doors, trapdoors and chains.
- Copper blocks, cut/chiseled blocks, stairs, slabs, grates, doors, trapdoors, chains, bars, rods and other available copper models; all oxidation stages, waxed/unwaxed.
- Rotate and change sun angle: highlights should be visible, copper should retain its color, and oxidation should progressively reduce shine.
- Compare vanilla, an outline/glint pack, a higher-resolution pack and a labPBR normal/specular pack. Check alpha holes, texture seams and material-map overrides.

## 4. Items and LDL station
- Hold each emitter in main hand and offhand; swap quickly and empty both hands. Drop enchanted/unenchanted items and light-emitting items.
- Check glints on held, dropped and inventory items; outline textures should preserve their intended colors and transparency.
- With LDL installed, enable shader LDL compatibility and the companion resource pack. Check moving lights do not fight or flicker, enchanted items illuminate more strongly, and no stale lights remain after removal.
- Repeat without LDL with shader compatibility disabled. Shader entity illumination and colored block lighting are intentionally absent; surface glow remains. LDL light colors are not custom RGB colors.

## 5. Water, glass and fog station
- Build shallow/deep pools, a flowing channel, waterfall, glass walls and submerged glass. Include several biome water colors.
- Walk along the surface and dive repeatedly; inspect underside tint, reflections, shoreline edges and surface popping.
- Look through water toward clouds and distant terrain; air fog should remain consistent and volumetric fog should cover water correctly.
- Look straight up on land and underwater: no circular cloud cutout. Check Fancy/Fast clouds and several view distances.
- Build a dark cave with close walls and a long opening: fog should not appear inside solid blocks or leak through walls.

## 6. Entities and dimensions
- Spawn blazes, drowned, endermen, spiders and glow squid; check emissive texture areas, particles and transparency from front/back.
- Check mob shadows on terrain/other mobs and unwanted self-shadow artifacts. With LDL, test species rules in a dark enclosure.
- Nether: lava, soul fire, portals and fog. End: sky texture repetition, horizon seams and purple flash brightness before/after dragon death; flash should illuminate fog without a sky graphic.

## 7. Distant Horizons and quality matrix
- From a marked viewpoint, toggle DH and inspect glass, bars, leaves, water and terrain transition boundaries for outlines, halos and gaps.
- Compare all five profiles. High should use volumetric resolution 32; Ultra should increase quality rather than enable colored/entity lighting.
- Record FPS/frame-time after the scene settles at fixed resolution, render distance and camera position; test dense foliage, water/reflections, cave fog and crowded mobs.
- Repeat core stations on 1.21.1 and 1.21.11 with matching mod builds. Test AMD/Intel hardware when available; record unsupported configurations rather than assuming support.

## Suggested layout
Use a flat daylight platform with numbered rows, a dark enclosed copy of the lighting stations, a water/biome area, a cave corridor and a distant viewing tower. Keep separate Nether and End stations. Provide time/weather buttons and teleport markers so comparisons are repeatable.
