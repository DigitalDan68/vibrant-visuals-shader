// Water transmits light; use the opaque bed depth behind its surface.
bool entityWaterPixel(vec2 uv) {
 float tag=texture(colortex7,uv).z;
 return abs(tag-0.25)<0.004 || abs(tag-0.26)<0.004;
}
float entityReceiverDepth(vec2 uv) {
 return entityWaterPixel(uv) ? texture(depthtex1,uv).r : texture(depthtex0,uv).r;
}


