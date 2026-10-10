#ifdef COLORED_BLOCK_LIGHTING
attribute vec4 at_midBlock;
const float voxelDistance=0.0;
uniform mat4 shadowModelViewInverse;
uniform vec3 cameraPosition;
#include "/common/voxel_grid.glsl"
#include "/common/voxel_colors.glsl"
layout(r32ui) uniform uimage3D blockVoxelImage;
void writeBlockVoxel() {
 // Only terrain has block-centre attributes; entities must not become blockers.
 if (renderStage!=MC_RENDER_STAGE_TERRAIN_SOLID && renderStage!=MC_RENDER_STAGE_TERRAIN_CUTOUT && renderStage!=MC_RENDER_STAGE_TERRAIN_CUTOUT_MIPPED && renderStage!=MC_RENDER_STAGE_TERRAIN_TRANSLUCENT) return;
 vec3 centre=(shadowModelViewInverse*gl_ModelViewMatrix*vec4(gl_Vertex.xyz+at_midBlock.xyz/64.0,1.0)).xyz;
 // at_midBlock identifies a block centre. Remove camera-transform rounding
 // before packing so every vertex of the same source writes the same record.
 centre=floor(centre+cameraPosition+vec3(0.001))+vec3(0.5)-cameraPosition;
 uint id=uint(max(mc_Entity.x,0.0));
 bool emitter=id==43301u || id==43302u || (id>=43201u && id<=43215u) || at_midBlock.w>0.0 || id==10068u || id==10072u || id==10076u || (id>=10496u && id<=10984u) || (id>=42001u && id<=42014u) || (id>=43111u && id<=43113u) || (id>=30020u && id<=30022u);
 bool transparent=id==10008u || id==30030u || id==10031u || (id==10059u || id==42015u);
 vec3 vertexWorld=(shadowModelViewInverse*gl_ModelViewMatrix*gl_Vertex).xyz+cameraPosition;
 vec3 corner=fract(vertexWorld);
 bool solid=all(lessThan(min(corner,vec3(1.0)-corner),vec3(0.02)));
 for (int level=0;level<1;++level) {
  vec3 sourcePosition=blockVoxelPosition(centre,level);
  ivec3 cell=ivec3(floor(sourcePosition));
  if (any(lessThan(cell,ivec3(0))) || any(greaterThanEqual(cell,blockVoxelExtent(level)))) continue;
  cell+=blockVoxelOffset(level);
  if (emitter) imageAtomicMax(blockVoxelImage,cell,packVoxelSource(id,sourcePosition));
  // Keep blockers at block resolution: one block cannot occlude an entire coarse cell.
  else if (!transparent && level==0) {
   // A single outer corner does not prove a full cube (slabs/stairs share corners).
   // Any inset vertex marks this cell partial, regardless of vertex submission order.
   // Source records are >=3 and always take priority over either shape marker.
   imageAtomicMax(blockVoxelImage,cell,solid ? 1u : 2u);
  }
 }
}
#endif
