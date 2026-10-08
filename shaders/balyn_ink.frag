#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uColorA;
uniform vec4 uColorB;
uniform vec4 uColorC;
uniform float uStrength;
uniform float uSheen;

out vec4 fragColor;

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 size = max(uSize, vec2(1.0));
  vec2 uv = frag / size;

  float aspect = clamp(size.x / size.y, 0.75, 3.0);
  vec2 p = vec2(uv.x * aspect, uv.y);
  float t = uTime * 6.28318530718;

  float waveA = sin(p.x * 4.4 + p.y * 2.2 + t * 0.74);
  float waveB = cos(p.x * -2.3 + p.y * 5.2 - t * 0.53);
  float flow = 0.5 + 0.5 * (waveA * 0.62 + waveB * 0.38);
  flow = smoothstep(0.02, 0.98, flow);

  float band = 0.5 + 0.5 * sin((p.x + p.y * 0.45) * 5.4 - t * 0.42);
  vec3 animatedColor = mix(uColorA.rgb, uColorB.rgb, flow);
  animatedColor = mix(
    animatedColor,
    uColorC.rgb,
    smoothstep(0.46, 0.96, band) * 0.72
  );

  vec3 color = mix(uColorB.rgb, animatedColor, clamp(uStrength, 0.0, 1.0));

  // Strong travelling reflection from the original look, but intentionally
  // broad and noise-free so glyphs and 4 px bars stay clean.
  float sheen = smoothstep(
    0.76,
    1.0,
    sin((p.x * 0.92 + p.y * 0.25) * 8.0 - t * 0.58)
  );
  color += vec3(sheen * 0.095 * clamp(uSheen, 0.0, 1.0));

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
