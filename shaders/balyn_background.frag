#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform float uDark;

out vec4 fragColor;

float hash21(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 size = max(uSize, vec2(1.0));
  vec2 uv = frag / size;
  float aspect = size.x / size.y;
  vec2 p = vec2(uv.x * aspect, uv.y);
  float t = uTime * 6.28318530718;

  float waveA = sin(p.x * 2.15 + p.y * 1.10 + t * 0.72);
  float waveB = sin(p.x * -1.35 + p.y * 2.75 - t * 0.43);
  float waveC = sin(length(p - vec2(aspect * 0.58, 0.42)) * 7.0 - t * 0.31);
  float field = waveA * 0.48 + waveB * 0.31 + waveC * 0.21;
  field = smoothstep(-0.72, 0.90, field);

  float ribbon = sin((p.x + p.y * 0.34) * 4.0 - t * 0.26);
  ribbon = smoothstep(0.42, 1.0, ribbon) * 0.60;

  float grain = (hash21(floor(frag * 0.48) + floor(t * 1.7)) - 0.5);

  vec3 black = vec3(0.0);
  vec3 violet = vec3(0.20, 0.075, 0.42);
  vec3 indigo = vec3(0.055, 0.10, 0.30);
  vec3 darkColor = black;
  darkColor += violet * (0.018 + field * 0.060);
  darkColor += indigo * ribbon * 0.038;
  darkColor += vec3(grain * 0.0035);

  vec3 white = vec3(1.0);
  vec3 pearl = vec3(0.91, 0.90, 1.0);
  vec3 lightColor = mix(white, pearl, field * 0.13 + ribbon * 0.045);
  lightColor += vec3(grain * 0.006);

  vec3 color = mix(lightColor, darkColor, clamp(uDark, 0.0, 1.0));
  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
