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

  // Never let very wide/thin widgets multiply the shader frequency.
  // This keeps 4 px progress bars and small text completely smooth.
  float aspect = clamp(size.x / size.y, 0.75, 2.35);
  vec2 p = vec2(uv.x * aspect, uv.y);
  float t = uTime * 6.28318530718;

  float waveA = sin(p.x * 2.15 + p.y * 1.20 + t);
  float waveB = cos(p.x * -1.35 + p.y * 2.05 - t * 2.0);
  float flow = 0.5 + 0.5 * (waveA * 0.58 + waveB * 0.42);
  flow = smoothstep(0.06, 0.94, flow);

  float band = 0.5 + 0.5 * sin((p.x + p.y * 0.32) * 2.45 - t);
  vec3 animatedColor = mix(uColorA.rgb, uColorB.rgb, flow);
  animatedColor = mix(
    animatedColor,
    uColorC.rgb,
    smoothstep(0.58, 0.98, band) * 0.42
  );

  // Strength controls how far the material travels from the seed colour.
  // Text uses a low value; larger icons/surfaces can stay more expressive.
  vec3 color = mix(uColorB.rgb, animatedColor, clamp(uStrength, 0.0, 1.0));

  // One broad soft reflection instead of per-pixel glitter/noise.
  // This preserves the living/iridescent feel without dotted glyphs.
  float sheenWave = 0.5 + 0.5 * sin(
    (p.x * 0.82 + p.y * 0.22) * 3.15 - t * 2.0
  );
  float sheen = smoothstep(0.78, 1.0, sheenWave);
  color += vec3(sheen * 0.032 * clamp(uSheen, 0.0, 1.0));

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
