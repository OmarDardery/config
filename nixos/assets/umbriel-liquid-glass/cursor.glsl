// Optional glass halo; not activated by default to retain direct scanout.
vec4 cursor(vec2 uv) {
  vec4 base = umbriel_sample(uv);
  float distance_px = length((uv - umbriel_pointer) * umbriel_size);
  float halo = exp(-distance_px * distance_px / (2.0 * 23.0 * 23.0)) * 0.14;
  vec3 accent = umbriel_palette_count > 0
      ? umbriel_palette_at(0.0).rgb
      : vec3(0.62, 0.76, 0.94);
  vec3 reflected = mix(base.rgb, accent * base.a, halo);
  return vec4(reflected, base.a);
}
