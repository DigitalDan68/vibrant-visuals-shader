vec3 getWaterWave(float random,vec3 feetPos) {
   vec2 world=feetPos.xz+cameraPosition.xz;
   float t=frameTimeCounter*float(WATER_WAVE_SPEED);
   float strength=0.01*float(WATER_WAVE_SIZE);
   // Continuous world-space phase avoids floor/hash jumps at moving-camera vertex boundaries.
   return strength*vec3(sin(dot(world,vec2(0.7,0.42))+t*0.7),0.0,
                        cos(dot(world,vec2(-0.37,0.61))+t*0.58));
}
