#ifndef MINIATURE_BLOCK_LIGHT_VOLUME
#define MINIATURE_BLOCK_LIGHT_VOLUME
uniform sampler3D blockLightA;
#include "/common/voxel_grid.glsl"
#include "/common/voxel_colors.glsl"
vec3 sampleBlockClipmap(vec3 position,vec3 normal,int level,out float emissionBoost) {
 vec3 receiver=blockVoxelPosition(position,level);
 vec3 samplePosition=receiver+normal*0.65/blockVoxelScale(level)-0.5;
 ivec3 base=ivec3(floor(samplePosition));
 vec3 fraction=fract(samplePosition);
 vec3 radiance=vec3(0.0);
 float sourceWeight=0.0;
 float boostedWeight=0.0;

 // Adjacent interpolation cells usually share one source; reuse its wall test.
 for (int z=0;z<2;++z) for (int y=0;y<2;++y) for (int x=0;x<2;++x) {
  ivec3 cell=base+ivec3(x,y,z);
  if (any(lessThan(cell,ivec3(0))) || any(greaterThanEqual(cell,blockVoxelExtent(level)))) continue;
  vec4 source=texelFetch(blockLightA,cell+blockVoxelOffset(level),0);
  if (source.w<0.5) continue;
  float distanceToSource=length((receiver-source.xyz)*blockVoxelScale(level));
  if (distanceToSource>=16.0) continue;
  float falloff=exp(-0.22314355*distanceToSource)*(1.0-smoothstep(12.0,16.0,distanceToSource));
  vec3 weight=mix(vec3(1.0)-fraction,fraction,vec3(float(x),float(y),float(z)));
  float contribution=falloff*weight.x*weight.y*weight.z;
  sourceWeight+=contribution;
  boostedWeight+=contribution*(source.w==9.0 ? 2.0 : 1.0);
  radiance+=voxelPaletteColor(uint(source.w-1.0))*falloff*weight.x*weight.y*weight.z;
 }
 emissionBoost=sourceWeight>0.000001 ? boostedWeight/sourceWeight : 1.0;
 return radiance;
}
bool insideDetailedBlockLightGrid(vec3 position) {
 vec3 cell=blockVoxelPosition(position,0);
 vec3 edge=min(cell,vec3(blockVoxelExtent(0))-cell);
 return min(edge.x,min(edge.y,edge.z))>=21.0;
}
vec3 sampleColoredBlockLight(vec3 position,vec3 normal) {
 float emissionBoost;
 return sampleBlockClipmap(position,normal,0,emissionBoost);
}
vec3 sampleColoredBlockLight(vec3 position,vec3 normal,out float emissionBoost) {
 return sampleBlockClipmap(position,normal,0,emissionBoost);
}
#endif
