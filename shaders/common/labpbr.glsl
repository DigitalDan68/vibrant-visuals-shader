// labPBR 1.3: linear F0, perceptual smoothness. Metal IDs use albedo F0.
// https://shaderlabs.org/wiki/LabPBR_Material_Standard
vec3 labSkyEnvironment(vec3 direction, float roughness, vec3 sky, vec3 horizon) {
   float elevation = clamp(direction.y * 0.5 + 0.5, 0.0, 1.0);
   vec3 environment = mix(horizon, sky, smoothstep(0.35, 0.9, elevation));
   environment *= mix(0.3, 1.0, smoothstep(0.0, 0.5, elevation));
   return pow(max(mix(environment, mix(horizon, sky, 0.5), roughness * roughness), vec3(0.0)), vec3(2.2));
}
vec3 labFresnel(vec3 f0, float cosine) {
   return f0 + (vec3(1.0) - f0) * pow(1.0 - clamp(cosine, 0.0, 1.0), 5.0);
}
vec3 labSpecular(vec3 N, vec3 V, vec3 L, vec3 f0, float roughness) {
   vec3 sum = V + L;
   if (dot(sum, sum) < 0.00001) return vec3(0.0);
   vec3 H = normalize(sum);
   float nv = max(dot(N, V), 0.0);
   float nl = max(dot(N, L), 0.0);
   float nh = max(dot(N, H), 0.0);
   float a2 = roughness * roughness;
   float d = nh * nh * (a2 - 1.0) + 1.0;
   float D = a2 / max(3.141592653 * d * d, 0.000001);
   float gv = 2.0 * nv / max(nv + sqrt(a2 + (1.0-a2)*nv*nv), 0.00001);
   float gl = 2.0 * nl / max(nl + sqrt(a2 + (1.0-a2)*nl*nl), 0.00001);
   return D * gv * gl * labFresnel(f0, max(dot(V, H), 0.0)) * nl / max(4.0*nv*nl, 0.00001);
}

// Compress bright material lighting before the normalized scene buffer clips it.
// Scale all channels together to preserve colored metal/highlight hues.
vec3 labHighlightShoulder(vec3 color, float shoulder) {
   color = max(color, vec3(0.0));
   float peak = max(color.r, max(color.g, color.b));
   if (peak <= shoulder) return color;
   float excess = peak - shoulder;
   float headroom = 1.0 - shoulder;
   float mapped = shoulder + headroom * excess / (headroom + excess);
   return color * (mapped / peak);
}
