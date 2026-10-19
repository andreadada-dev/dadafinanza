#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform float uDark;

out vec4 fragColor;

// Slow, seamless fluid domain warping rather than rows of sine-wave ribbons.
// All temporal terms use integer harmonics of the full 72 second period.
void main() {
  vec2 uv = FlutterFragCoord().xy / max(uSize, vec2(1.0));
  vec2 p = uv - vec2(0.5);
  float t = uTime * 6.28318530718;

  // Distort the coordinates in both directions. No hard edges or grain.
  vec2 drift = vec2(
    0.09 * sin(p.y * 3.6 + t) + 0.044 * cos(p.x * 4.5 - t * 2.0),
    0.08 * cos(p.x * 3.1 - t) + 0.045 * sin(p.y * 4.2 + t * 2.0)
  );
  vec2 flow = p + drift;

  // Soft overlapping translucent clouds with independently drifting centers.
  vec2 a = (flow - vec2(-0.25 + 0.12 * sin(t),
                          -0.18 + 0.09 * cos(t))) / vec2(0.43, 0.47);
  vec2 b = (flow - vec2(0.25 + 0.13 * cos(t),
                           0.19 + 0.10 * sin(t))) / vec2(0.46, 0.44);
  vec2 c = (flow - vec2(0.00 + 0.18 * sin(t * 2.0),
                           0.02 - 0.12 * cos(t))) / vec2(0.57, 0.39);

  float cloudA = exp(-1.65 * dot(a, a));
  float cloudB = exp(-1.75 * dot(b, b));
  float cloudC = exp(-2.15 * dot(c, c));

  // Advected detail creates silky liquid swirls, not high-contrast stripes.
  float swirling = 0.5 + 0.5 * sin(
    flow.x * 5.6 + flow.y * 3.4 +
    0.75 * sin(flow.y * 3.2 - t) - t
  );
  float folding = 0.5 + 0.5 * cos(
    flow.y * 5.1 - flow.x * 2.3 +
    0.52 * sin(flow.x * 4.1 + t) + t
  );

  float violet = cloudA * (0.55 + 0.45 * swirling) +
                 cloudC * (0.16 + 0.21 * folding);
  float indigo = cloudB * (0.53 + 0.47 * folding) +
                 cloudC * (0.10 + 0.18 * swirling);

  // Both themes keep a very clean foundation with slow, coherent movement.
  // Colors are soft violet/blue light, not opaque stripes or large flat bands.
  vec3 darkColor = vec3(0.0014, 0.0015, 0.0032);
  darkColor += vec3(0.098, 0.040, 0.185) * violet;
  darkColor += vec3(0.037, 0.055, 0.132) * indigo;

  vec3 lightColor = vec3(1.0);
  lightColor -= vec3(0.060, 0.061, 0.024) * violet;
  lightColor -= vec3(0.042, 0.043, 0.018) * indigo;

  vec3 color = mix(lightColor, darkColor, clamp(uDark, 0.0, 1.0));
  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
