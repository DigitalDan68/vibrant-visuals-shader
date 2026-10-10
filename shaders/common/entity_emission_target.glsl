// A separate target captures only resource-pack emission and its exact depth.
const int colortex8Format = RGBA32F;
const bool colortex8Clear = true;
const vec4 colortex8ClearColor = vec4(0.0,0.0,0.0,0.0);
const int colortex9Format = RGBA16F;
// Preserve the previous illumination image for depth-checked temporal smoothing.
const bool colortex9Clear = false;
const vec4 colortex9ClearColor = vec4(0.0,0.0,0.0,0.0);
