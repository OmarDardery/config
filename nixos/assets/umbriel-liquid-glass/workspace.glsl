// A directional liquid-glass wipe with a small refractive seam.
// The first/last frames are exactly the outgoing/incoming scene respectively.
vec4 animation(vec2 uv) {
  float t = umbriel_clamped_progress;
  float bend = sin(uv.y * 11.0 + t * 3.0) * 0.011
      * sin(3.14159265 * t);
  float front = mix(-0.12, 1.12, t) + bend;
  float incoming = 1.0 - smoothstep(front - 0.065, front + 0.065, uv.x);
  float distance_to_seam = abs(uv.x - front);
  float lens = (1.0 - smoothstep(0.0, 0.16, distance_to_seam))
      * sin(3.14159265 * t);
  vec2 offset = vec2(0.012 * lens, 0.0);
  vec4 previous_scene = umbriel_sample(uv + offset);
  vec4 next_scene = umbriel_sample_incoming(uv - offset);
  return mix(previous_scene, next_scene, incoming);
}
