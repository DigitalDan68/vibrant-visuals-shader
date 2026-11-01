vec3 getShadowDistortion(vec3 shadowClipPos){
  float detailScale=shadowDistance/min(shadowDistance,STABLE_SHADOW_RANGE);
  shadowClipPos.xy*=detailScale;
  return shadowClipPos;
}
