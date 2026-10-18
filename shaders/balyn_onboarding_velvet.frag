#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uPhase;
uniform float uBeamStrength;

out vec4 fragColor;

const float TAU = 6.28318530718;

// Original Flutter velvet material. Silk-like moving folds inspired by the
// visual language of Not Found Pages (MIT); the soft diagonal lights are an
// independent implementation, not React Bits Pro/Axial Beam source code.
// Every time term is periodic over the shared Balyn 72-second clock.
float velvetHeight(vec2 p, float t) {
  vec2 flow = p + vec2(
    0.068 * sin(p.y * 3.4 + t) + 0.027 * cos(p.x * 4.3 - t),
    0.061 * cos(p.x * 3.1 - t) - 0.023 * sin(p.y * 5.0 + t)
  );

  float large = sin(
    flow.x * 7.0 + flow.y * 3.7
    + 0.52 * sin(flow.y * 2.9 + t) - t
  );
  float secondary = sin(
    flow.x * 12.0 - flow.y * 5.5
    + 0.35 * sin(flow.x * 4.1 - t) + t
  );
  float small = sin(
    flow.x * 20.0 + flow.y * 9.0
    + 0.28 * cos(flow.y * 6.0 + t)
  );

  return large * 0.71 + secondary * 0.22 + small * 0.07;
}

float softBeam(vec2 uv, float origin, float slope, float width, float t) {
  // A volumetric-looking highlight with no sharp boundary or flashing.
  float center = origin + slope * uv.y + 0.022 * sin(t);
  float sigma = width + uv.y * 0.23;
  float x = (uv.x - center) / sigma;
  float envelope = smoothstep(1.0, 0.0, uv.y) * 0.83 + 0.17;
  return exp(-x * x * 1.45) * envelope;
}

float stableNoise(vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / max(uSize, vec2(1.0));
  float aspect = uSize.x / max(uSize.y, 1.0);
  vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
  float t = uPhase * TAU;

  // Derive a virtual surface normal from neighboring height samples so the
  // highlight hugs each actual fold (rather than looking like moving stripes).
  float h = velvetHeight(p, t);
  float stepSize = 0.0038;
  vec2 slope = vec2(
    velvetHeight(p + vec2(stepSize, 0.0), t) - h,
    velvetHeight(p + vec2(0.0, stepSize), t) - h
  ) / stepSize;
  vec3 normal = normalize(vec3(-slope.x * 0.095, -slope.y * 0.095, 1.0));
  vec3 light = normalize(vec3(-0.48, 0.63, 1.0));
  vec3 halfway = normalize(light + vec3(0.0, 0.0, 1.0));

  float diffuse = clamp(dot(normal, light) * 0.5 + 0.5, 0.0, 1.0);
  float satin = pow(max(dot(normal, halfway), 0.0), 18.0);
  float foldLight = clamp(0.40 + 0.28 * h + 0.40 * diffuse
      + 0.12 * satin, 0.0, 1.0);

  // Purple velvet, never a washed-out white acrylic or rainbow mesh.
  vec3 shadow = vec3(0.025, 0.010, 0.045);
  vec3 middle = vec3(0.135, 0.047, 0.220);
  vec3 raised = vec3(0.330, 0.145, 0.465);
  vec3 color = mix(shadow, middle, smoothstep(0.12, 0.71, foldLight));
  color = mix(color, raised, smoothstep(0.65, 0.99, foldLight) * 0.62);

  // Beam-like light is intentionally subdued to preserve text readability.
  // This is original math; no code or assets from the paid Axial Beam effect.
  float beam = softBeam(uv, 0.23, 0.37, 0.075, t)
      + 0.55 * softBeam(uv, 0.83, -0.43, 0.060, -t);
  float beamLevel = clamp(beam, 0.0, 1.0) * uBeamStrength;
  color += vec3(0.090, 0.052, 0.156) * beamLevel;

  // Very subtle, fixed-pixel microtexture; never animate noise independently.
  float grain = stableNoise(FlutterFragCoord().xy) - 0.5;
  color += vec3(grain * 0.009);
  float vignette = 1.0 - 0.19 * smoothstep(0.23, 0.85,
      length((uv - vec2(0.50, 0.48)) * vec2(1.0, 0.90)));
  color *= vignette;

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
