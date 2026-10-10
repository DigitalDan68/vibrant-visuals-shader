#if defined CLOUD_SHADOWS && defined OVERWORLD
uniform sampler2D cloudShadowTex;
uniform float frameTimeCounter;
float cloudTransmission(vec3 feetPos) {
   vec3 world = feet2world(feetPos);
   vec3 light = normalize(view2eye(shadowLightPosition));
   if (light.y <= 0.08 || world.y >= CLOUD_SHADOW_HEIGHT) return 1.0;
   vec2 projected = world.xz + light.xz * (CLOUD_SHADOW_HEIGHT-world.y)/light.y;
   // Vanilla cloud cells are twelve blocks wide; use the active resource texture.
   vec2 uv = fract((projected + vec2(frameTimeCounter*0.6,0.0))/3072.0);
   float coverage = 0.0;
   for (int x=-1;x<=1;++x) for (int y=-1;y<=1;++y)
      coverage += texture2D(cloudShadowTex,fract(uv+vec2(float(x),float(y))/256.0)).a;
   return 1.0-CLOUD_SHADOW_STRENGTH*coverage/9.0;
}
#endif
