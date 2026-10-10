// Water transmits light; use the opaque bed depth behind its surface.
bool entityWaterPixel(vec2 uv) {
 float tag=texture(colortex7,uv).z;
 return abs(tag-0.25)<0.004 || abs(tag-0.26)<0.004;
}
float entityReceiverDepth(vec2 uv) {
 return entityWaterPixel(uv) ? texture(depthtex1,uv).r : texture(depthtex0,uv).r;
}
bool entityWithinLightRange(vec3 viewPosition) {
 vec3 relative=abs(view2feet(viewPosition)+mod(cameraPosition,vec3(1.0)));
 // Match the block field's 21-block propagation safety margin exactly.
 return relative.x<=float(BLOCK_LIGHT_HORIZONTAL_RADIUS)-21.0 &&
        relative.z<=float(BLOCK_LIGHT_HORIZONTAL_RADIUS)-21.0 &&
        relative.y<=float(BLOCK_LIGHT_VERTICAL_RADIUS)-21.0;
}
