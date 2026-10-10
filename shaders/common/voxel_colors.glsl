uint voxelPalette(uint id) {
 if (id==43301u || id==43302u) return 14u;
 if (id>=43201u && id<=43215u) return 10u+(id-43201u)/3u;
 if (id==42013u) return 9u;
 if (id==42015u) return 8u;
 if (id==10076u || id==10528u || id==10656u || id==42001u) return 1u;
 if (id==10604u || id==42007u || id==42013u) return 2u;
 if (id==10984u || id==42014u || (id>=43111u && id<=43113u)) return 3u;
 if (id==42002u || id==42006u || id==42008u) return 4u;
 if (id==42010u) return 5u;
 if (id==42011u) return 6u;
 if (id>=30020u && id<=30022u) return 7u;
 return 0u;
}
vec3 voxelPaletteColor(uint palette) {
 if (palette>=10u && palette<=14u) return vec3(1.0,0.015,0.005)*0.05*float(palette-9u);
 if (palette==9u) return vec3(0.4,0.006,0.002);
 if (palette==8u) return vec3(1.0,0.5,0.12)*3.0;
 if (palette==1u) return vec3(0.12,0.65,1.0)*1.5;
 if (palette==2u) return vec3(1.0,0.025,0.01)*1.2;
 if (palette==3u) return vec3(0.2,1.0,0.55)*1.5;
 if (palette==4u) return vec3(0.45,0.85,1.0)*1.5;
 if (palette==5u) return vec3(0.65,1.0,0.35)*1.5;
 if (palette==6u) return vec3(1.0,0.45,0.8)*1.5;
 if (palette==7u) return vec3(0.7,0.15,1.0)*1.5;
 return vec3(1.0,0.5,0.12)*1.5;
}
// Preserve the actual emitter location inside coarse cells. Low bits hold
// source flag (3; above solid=1 and partial=2) and a 4-bit palette; coordinates use 8/9/9 fractional bits.
uint packVoxelSource(uint id,vec3 position) {
 uvec3 fraction=uvec3(floor(fract(position)*vec3(255.0,511.0,511.0)+0.5));
 return 3u | (voxelPalette(id)<<2u) | (fraction.x<<6u) | (fraction.y<<14u) | (fraction.z<<23u);
}
vec4 unpackVoxelSource(uint sourceBits,ivec3 cell) {
 vec3 fraction=vec3(float((sourceBits>>6u)&255u),float((sourceBits>>14u)&511u),float((sourceBits>>23u)&511u))/vec3(255.0,511.0,511.0);
 return vec4(vec3(cell)+fraction,float(((sourceBits>>2u)&15u)+1u));
}
