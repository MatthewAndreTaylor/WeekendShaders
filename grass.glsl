// Matthew Andre Taylor 2025

#define MAX_BLADES 400.0
#define PI2 6.28318530
#define SWAY_TIME 8.0

float rand(float seed) {
    return fract(sin(seed * 12.9898) * 43758.5453);
}

float drawBlade(vec2 uv, vec2 base, float height, float width, float bend, float t) {
    vec2 tip = base + vec2(bend, -height);
    vec2 pa = uv - base;
    vec2 ba = tip - base;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    vec2 proj = base + ba * h;
    float d = length(uv - proj);
    float tap = mix(width, 0.0, pow(h, 2.0)); // grass tip
    float edge = fwidth(d);
    return smoothstep(tap + edge, tap - edge, d);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv.y = 1.0 - uv.y;
    vec3 colorTop = vec3(0.47, 0.73, 0.8);
    vec3 colorBottom = vec3(0.55, 0.75, 0.56);
    vec3 col = mix(colorBottom, colorTop, uv.y);
    float t = mod(iTime, SWAY_TIME);
    float closestDepth = -1.0;
    vec3 grassColorFinal = col;

    for (float i = 0.0; i < MAX_BLADES; i++) {
        float seed = i + 42.0;
        float r = rand(seed);
        float x = r * 1.2 - 0.1;
        float yb = pow(rand(seed + 1.0), 1.1) * 1.1;
        float height = yb * 0.2 + 0.1;
        float variance = r;
        float jiggle0 = sin(variance + t * (PI2 * 2.0 / SWAY_TIME)) * height * 0.1;
        float jiggle1 = sin(variance * 30.0 + t * (PI2 * ceil(variance * 5.0) / SWAY_TIME)) * height * variance * 0.005;
        float bend = jiggle0 + jiggle1;

        vec2 grassBase = vec2(x, yb);
        float blade = drawBlade(uv, grassBase, height, 0.01, bend, t);

        if (blade > 0.001 && yb > closestDepth) {
            closestDepth = yb;
            float sat = rand(seed + 3.0) * 0.2 + 0.3;
            float light = rand(seed + 4.0) * 0.2 + 0.7;
            vec3 green = vec3(0.0, 1.0, 0.0);
            vec3 grey = vec3(light);
            grassColorFinal = mix(grey, green, sat);
        }
    }

    fragColor = vec4(grassColorFinal, 1.0);
}