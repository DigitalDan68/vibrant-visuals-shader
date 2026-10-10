// Use world texel centers, matching the fixed 16x16 block shadow grid.
vec3 entityShadowGridReceiver(vec3 receiver,vec3 viewNormal) {
 vec3 world=feet2world(view2feet(receiver));
 vec3 snapped=(floor(world*16.0+0.01)+0.5)/16.0;
 vec3 worldNormal=view2eye(viewNormal);
 float normalLength=dot(worldNormal,worldNormal);
 if(normalLength>0.00001) {
  worldNormal*=inversesqrt(normalLength);
  // Keep the quantized lookup on the receiving plane to avoid self-shadow bias.
  snapped-=worldNormal*dot(snapped-world,worldNormal);
 }
 return feet2view(world2feet(snapped));
}
