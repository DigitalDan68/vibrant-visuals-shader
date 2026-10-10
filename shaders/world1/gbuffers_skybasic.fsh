#version 120
#define THE_END
// Background geometry must never inherit solid-object material/depth tags.
/* DRAWBUFFERS:0 */
void main() { gl_FragData[0] = vec4(0.0,0.0,0.0,1.0); }
