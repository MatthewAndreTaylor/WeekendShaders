// Matthew Andre Taylor 2025

#define LENGTH 3.0
#define SPEED 0.3
#define MAX 1e10

vec2 route(float t) {
    float r = 1.5 * sin(2.3 * t) + 0.5 * cos(1.7 * t + sin(0.5 * t));
    float angle = t + 0.4 * sin(3.5 * t) + 0.2 * cos(7.1 * t);
    r *= 0.5 + 0.15 * sin(0.9 * t);
    return r * vec2(cos(angle), sin(angle));
}

float drawSegment(vec2 p, vec2 a, vec2 b, float thick) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - thick;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (2.0 * fragCoord.xy - iResolution.xy) / iResolution.y;
    float d = MAX;
    vec2 prev, neck, head;
    const int N = 300;

    for (int i = 1; i <= N; ++i) {
        float chunk = float(i) / float(N);
        float t = SPEED * iTime + chunk * LENGTH;
        vec2 p = route(t);

        if (i > 1) {
            d = min(d, drawSegment(uv, p, prev, 0.035 - 0.75 / float(i)));
        }

        if (i == N - 1) neck = p;
        if (i == N) head = p;

        prev = p;
    }

    vec2 headDir = normalize(head - neck);
    vec2 perp = vec2(-headDir.y, headDir.x);

    float eyeOffset = 0.018;
    float eyeRadius = 0.008;
    vec2 leftEye = head + perp * eyeOffset;
    vec2 rightEye = head - perp * eyeOffset;
    float aa = 2.0 / iResolution.y;

    float distL = length(uv - leftEye);
    float distR = length(uv - rightEye);
    float eyes = smoothstep(eyeRadius + aa, eyeRadius - aa, min(distL, distR));

    vec3 snake = mix(vec3(0.0, 0.55, 0.0), vec3(1.0), smoothstep(0.0, aa, d));
    vec3 color = mix(snake, vec3(0.1), eyes);
    fragColor = vec4(color, 1.0);
}
