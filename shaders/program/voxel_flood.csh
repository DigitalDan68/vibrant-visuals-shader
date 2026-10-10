#include "/shader.h"
layout(local_size_x=8,local_size_y=8,local_size_z=8) in;
#if BLOCK_LIGHT_HORIZONTAL_RADIUS == 32
#define BLOCK_DISPATCH_X 8
#define BLOCK_DISPATCH_Z 8
#elif BLOCK_LIGHT_HORIZONTAL_RADIUS == 40
#define BLOCK_DISPATCH_X 10
#define BLOCK_DISPATCH_Z 10
#elif BLOCK_LIGHT_HORIZONTAL_RADIUS == 48
#define BLOCK_DISPATCH_X 12
#define BLOCK_DISPATCH_Z 12
#elif BLOCK_LIGHT_HORIZONTAL_RADIUS == 56
#define BLOCK_DISPATCH_X 14
#define BLOCK_DISPATCH_Z 14
#elif BLOCK_LIGHT_HORIZONTAL_RADIUS == 64
#define BLOCK_DISPATCH_X 16
#define BLOCK_DISPATCH_Z 16
#elif BLOCK_LIGHT_HORIZONTAL_RADIUS == 72
#define BLOCK_DISPATCH_X 18
#define BLOCK_DISPATCH_Z 18
#elif BLOCK_LIGHT_HORIZONTAL_RADIUS == 80
#define BLOCK_DISPATCH_X 20
#define BLOCK_DISPATCH_Z 20
#elif BLOCK_LIGHT_HORIZONTAL_RADIUS == 88
#define BLOCK_DISPATCH_X 22
#define BLOCK_DISPATCH_Z 22
#elif BLOCK_LIGHT_HORIZONTAL_RADIUS == 96
#define BLOCK_DISPATCH_X 24
#define BLOCK_DISPATCH_Z 24
#elif BLOCK_LIGHT_HORIZONTAL_RADIUS == 104
#define BLOCK_DISPATCH_X 26
#define BLOCK_DISPATCH_Z 26
#elif BLOCK_LIGHT_HORIZONTAL_RADIUS == 112
#define BLOCK_DISPATCH_X 28
#define BLOCK_DISPATCH_Z 28
#elif BLOCK_LIGHT_HORIZONTAL_RADIUS == 120
#define BLOCK_DISPATCH_X 30
#define BLOCK_DISPATCH_Z 30
#elif BLOCK_LIGHT_HORIZONTAL_RADIUS == 128
#define BLOCK_DISPATCH_X 32
#define BLOCK_DISPATCH_Z 32
#endif
#if BLOCK_LIGHT_VERTICAL_RADIUS == 32
#define BLOCK_DISPATCH_Y 8
#elif BLOCK_LIGHT_VERTICAL_RADIUS == 40
#define BLOCK_DISPATCH_Y 10
#elif BLOCK_LIGHT_VERTICAL_RADIUS == 48
#define BLOCK_DISPATCH_Y 12
#elif BLOCK_LIGHT_VERTICAL_RADIUS == 56
#define BLOCK_DISPATCH_Y 14
#elif BLOCK_LIGHT_VERTICAL_RADIUS == 64
#define BLOCK_DISPATCH_Y 16
#elif BLOCK_LIGHT_VERTICAL_RADIUS == 72
#define BLOCK_DISPATCH_Y 18
#elif BLOCK_LIGHT_VERTICAL_RADIUS == 80
#define BLOCK_DISPATCH_Y 20
#elif BLOCK_LIGHT_VERTICAL_RADIUS == 88
#define BLOCK_DISPATCH_Y 22
#elif BLOCK_LIGHT_VERTICAL_RADIUS == 96
#define BLOCK_DISPATCH_Y 24
#elif BLOCK_LIGHT_VERTICAL_RADIUS == 104
#define BLOCK_DISPATCH_Y 26
#elif BLOCK_LIGHT_VERTICAL_RADIUS == 112
#define BLOCK_DISPATCH_Y 28
#elif BLOCK_LIGHT_VERTICAL_RADIUS == 120
#define BLOCK_DISPATCH_Y 30
#elif BLOCK_LIGHT_VERTICAL_RADIUS == 128
#define BLOCK_DISPATCH_Y 32
#endif
const ivec3 workGroups=ivec3(BLOCK_DISPATCH_X,BLOCK_DISPATCH_Y,BLOCK_DISPATCH_Z);
#ifdef COLORED_BLOCK_LIGHTING
uniform usampler3D blockVoxelSampler;
#if FLOOD_PASS % 2 == 0
uniform sampler3D blockLightA;
layout(rgba32f) uniform writeonly image3D blockLightBImage;
#define LIGHT_IN blockLightA
#define LIGHT_OUT blockLightBImage
#else
uniform sampler3D blockLightB;
layout(rgba32f) uniform writeonly image3D blockLightAImage;
#define LIGHT_IN blockLightB
#define LIGHT_OUT blockLightAImage
#endif
#include "/common/voxel_colors.glsl"
uniform vec3 cameraPosition;
#include "/common/voxel_grid.glsl"
vec4 neighbor(ivec3 cell,int level) {
 if (any(lessThan(cell,ivec3(0))) || any(greaterThanEqual(cell,blockVoxelExtent(level)))) return vec4(0.0);
 cell+=blockVoxelOffset(level);
 return texelFetch(LIGHT_IN,cell,0);
}
void considerSource(vec4 candidate,vec3 receiver,inout vec4 source,inout float bestDistance) {
 if (candidate.w<0.5) return;
 vec3 delta=candidate.xyz-receiver;
 float distanceSquared=dot(delta,delta);
 // Keep a deterministic winner when sources are equally close; neighbor order
 // must not change the selected light as the camera-aligned grid moves.
 bool tied=abs(distanceSquared-bestDistance)<0.00001;
 bool precedes=candidate.x<source.x || (candidate.x==source.x && (candidate.y<source.y || (candidate.y==source.y && (candidate.z<source.z || (candidate.z==source.z && candidate.w<source.w)))));
 if (distanceSquared<bestDistance-0.00001 || (tied && precedes)) {source=candidate;bestDistance=distanceSquared;}
}
#endif
void main() {
#ifdef COLORED_BLOCK_LIGHTING
 ivec3 cell=ivec3(gl_GlobalInvocationID);
 if (any(greaterThanEqual(cell,ivec3(2*BLOCK_LIGHT_HORIZONTAL_RADIUS,2*BLOCK_LIGHT_VERTICAL_RADIUS,2*BLOCK_LIGHT_HORIZONTAL_RADIUS)))) return;
 int level=0;
 ivec3 localCell=cell-blockVoxelOffset(level);
 if (any(greaterThanEqual(localCell,blockVoxelExtent(level)))) return;
 uint block=texelFetch(blockVoxelSampler,cell,0).r;
 vec4 source=vec4(0.0);
 if (block>2u) source=unpackVoxelSource(block,localCell);
 if (block==0u || block==2u) {
  vec3 receiver=vec3(localCell)+0.5;
  float bestDistance=1e20;
  // Retain valid paths discovered in earlier passes instead of alternating
  // between neighboring wavefronts. The volume is cleared before each frame.
  considerSource(neighbor(localCell,level),receiver,source,bestDistance);
  considerSource(neighbor(localCell+ivec3(1,0,0),level),receiver,source,bestDistance);
  considerSource(neighbor(localCell-ivec3(1,0,0),level),receiver,source,bestDistance);
  considerSource(neighbor(localCell+ivec3(0,1,0),level),receiver,source,bestDistance);
  considerSource(neighbor(localCell-ivec3(0,1,0),level),receiver,source,bestDistance);
  considerSource(neighbor(localCell+ivec3(0,0,1),level),receiver,source,bestDistance);
  considerSource(neighbor(localCell-ivec3(0,0,1),level),receiver,source,bestDistance);
 }
 if (source.w>0.5 && length((source.xyz-(vec3(localCell)+0.5))*blockVoxelScale(level))>(16.0+1.732051*blockVoxelScale(level))) source=vec4(0.0);
 imageStore(LIGHT_OUT,cell,source);
#endif
}
