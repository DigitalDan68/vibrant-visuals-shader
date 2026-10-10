#version 120
#define THE_END
// The final depth-masked sky supplies every face consistently. Native sky
// overlays (including dragon-death sky effects) must not accumulate over it.
/* DRAWBUFFERS:0 */
void main() { discard; }
