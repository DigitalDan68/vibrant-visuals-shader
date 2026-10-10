// Adjustable block-resolution field with overlapping distant light grids.
#ifndef BLOCK_FAR_DECLARED
uniform float far;
#define BLOCK_FAR_DECLARED
#endif
ivec3 blockVoxelExtent(int level) { return level==0 ? ivec3(2*BLOCK_LIGHT_HORIZONTAL_RADIUS,2*BLOCK_LIGHT_VERTICAL_RADIUS,2*BLOCK_LIGHT_HORIZONTAL_RADIUS) : ivec3(32); }
ivec3 blockVoxelOffset(int level) {
 if (level==0) return ivec3(0);
 if (level==1) return ivec3(2*BLOCK_LIGHT_HORIZONTAL_RADIUS,0,0);
 if (level==2) return ivec3(2*BLOCK_LIGHT_HORIZONTAL_RADIUS+32,0,0);
 return ivec3(2*BLOCK_LIGHT_HORIZONTAL_RADIUS,32,0);
}
float blockVoxelScale(int level) {
 if (level==0) return 1.0;
 if (level==1) return 8.0;
 if (level==2) return 16.0;
 return max(32.0,far/16.0);
}
vec3 blockVoxelPosition(vec3 relativePosition,int level) {
 float scale=blockVoxelScale(level);
 return (relativePosition+mod(cameraPosition,vec3(scale)))/scale+vec3(blockVoxelExtent(level))*0.5;
}
