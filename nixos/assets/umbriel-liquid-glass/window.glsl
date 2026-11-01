// A short glass-lens transition on opening/closing, with exact clean endpoints.
// No feedback, and no content distortion after the transition has finished.
vec4 animation(vec2 uv) {
  float visibility = umbriel_direction > 0.0
      ? umbriel_clamped_progress
      : 1.0 - umbriel_clamped_progress;
  float t = smoothstep(0.0, 1.0, visibility);
  vec2 from_center = uv - vec2(0.5);
  float core = 1.0 - smoothstep(0.05, 0.75, length(from_center));
  vec2 source_uv = uv + from_center * ((1.0 - t) * 0.055 * core);
  vec4 sampled = umbriel_sample(source_uv);

  float top_light = (1.0 - t) * (1.0 - smoothstep(0.0, 0.6, uv.y));
  sampled.rgb += sampled.a * vec3(0.88, 0.94, 1.0) * (top_light * 0.045);
  return sampled * smoothstep(0.0, 0.15, t);
}
