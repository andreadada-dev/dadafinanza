#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform float uDark;

out vec4 fragColor;

// Two broad liquid ribbons drift across the screen over a seamless 72 s loop.
// No per-pixel glitter, sharp edges or high-frequency noise.
void main() {
  vec2 size = max(uSize, vec2(1.0));
  vec2 uv = FlutterFragCoord().xy / size;
  float t = uTime * 6.28318530718;

  // The moving centerlines use only integer multiples of t, so wrapping
  // the phase from 1 back to 0 never produces a visible jump.
  float upperPath = 0.27
      + 0.14 * sin(uv.x * 4.4 + t)
      + 0.035 * sin(uv.x * 8.2 - t);
  float lowerPath = 0.73
      + 0.12 * sin(uv.x * 3.7 - t + 1.8);

  float upperDistance = (uv.y - upperPath) / 0.25;
  float lowerDistance = (uv.y - lowerPath) / 0.30;
  float upperRibbon = exp(-upperDistance * upperDistance);
  float lowerRibbon = exp(-lowerDistance * lowerDistance);

  // Slowly shifting concentrations give the ribbons organic texture without
  // granular artifacts. These terms are periodic over the full 72 s cycle.
  float upperFlow = 0.64 + 0.36 * (0.5 + 0.5 * sin(uv.x * 4.0 - t));
  float lowerFlow = 0.60 + 0.40 * (0.5 + 0.5 * cos(uv.x * 3.2 + t));
  float violetWave = upperRibbon * upperFlow;
  float indigoWave = lowerRibbon * lowerFlow;

  // Dark mode stays black between waves but now has a readable #1B1036-like
  // violet highlight instead of the previous near-invisible few RGB levels.
  vec3 darkColor = vec3(0.0);
  darkColor += vec3(0.13, 0.052, 0.28) * violetWave;
  darkColor += vec3(0.055, 0.093, 0.21) * indigoWave;

  // On white, subtract a soft lavender tint so the animation is also visible.
  // White remains pure where the ribbons are absent.
  vec3 lightColor = vec3(1.0);
  lightColor -= vec3(0.18, 0.17, 0.058) * violetWave;
  lightColor -= vec3(0.105, 0.095, 0.034) * indigoWave;

  vec3 color = mix(lightColor, darkColor, clamp(uDark, 0.0, 1.0));
  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
