# Particle Rain reference

`particle_rain_reference.png` is the unmodified Minecraft Java 26.3
`assets/minecraft/textures/environment/rain.png`, extracted from the installed client.
Original asset: Mojang / Microsoft.

This is a shader lookup reference, not a replacement for the mod texture or configuration.
It identifies Particle Rain sprites generated from the stock rain texture. Resource packs
that replace the rain texture may need a matching reference.

The reference is bundled so Iris loads it during pack setup. A resource-location sampler
can lazily upload the texture inside a render pass on Minecraft 26.3, which causes
`Close the existing render pass before performing additional commands`.
