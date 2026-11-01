// Soft, directionally lit glass edge. A static effect avoids needless redraws.
// Umbriel clips the client hole. All output colors are premultiplied RGBA.
vec4 border(vec2 uv) {
  vec4 native = umbriel_sample(uv);
  float distance_px = max(0.0, umbriel_border_distance(uv));
  vec2 p = uv - vec2(0.5);
  float highlight = pow(clamp(0.58 - p.x * 0.55 - p.y * 0.70, 0.0, 1.0), 2.0);
  float rim = exp(-distance_px * 0.80);
  float fringe = exp(-distance_px * 0.26);

  vec3 accent = umbriel_palette_count > 0
      ? umbriel_palette_at(0.0).rgb
      : vec3(0.61, 0.76, 0.93);
  vec3 glass = mix(vec3(0.68, 0.76, 0.84), accent, 0.32);
  glass = mix(glass, vec3(0.96, 0.98, 1.0), 0.72 * highlight);

  float opacity = clamp(
      native.a * 0.48 + rim * (0.26 + 0.34 * highlight) + fringe * 0.07,
      0.0, 0.88
  );
  return vec4(glass * opacity, opacity);
}
