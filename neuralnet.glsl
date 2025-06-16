// Matthew Andre Taylor 2025

const float segmentWidth = 0.004, speed = 0.12;
const float base = 22222.;
float rand(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * base); }

float line(vec2 uv, vec2 a, vec2 b) {
    vec2 pa = uv - a, ba = b - a;
    return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y) * 2.;
    float t = iTime;
    vec3 col = vec3(0);

    const int IN = 4, HN = 8, HL = 3, ON = 4, N = IN + HL * HN + ON;
    vec2 nodes[N];
    int layers[N];
    const float xs = 0.7, ys = 0.25;
    int i, j, idx = 0;

    for (i = 0; i < IN; i++) {
        nodes[idx] = vec2(-2.0 * xs, (float(i) - float(IN - 1) / 2.0) * (ys + 0.1));
        layers[idx++] = 0;
    }
    for (i = 0; i < HL * HN; i++) {
        float x = -xs + float(i / HN) * xs;
        float y = (float(i % HN) - float(HN - 1) / 2.0) * ys;
        nodes[idx] = vec2(x, y);
        layers[idx++] = 1 + i / HN;
    }
    for (i = 0; i < ON; i++) {
        nodes[idx] = vec2(2.0 * xs, (float(i) - float(ON - 1) / 2.0) * (ys + 0.1));
        layers[idx++] = HL + 1;
    }

    for (i = 0; i < N; i++) {
        for (j = i; j < N; j++) {
            if (layers[i] == layers[j]) continue;
            float h = rand(vec2(float(i), float(j)));
            vec2 a = nodes[i], b = nodes[j];
            float glow = exp(-pow(line(uv, a, b) / segmentWidth, 2.));
            float ppos = fract(t * speed + h);
            float pulse = exp(-pow(length(uv - mix(a, b, ppos)) / 0.005, 2.));

            float lh = rand(vec2(float(layers[i]), float(layers[j])));
            vec3 ca = vec3(rand(vec2(lh, 1.)), rand(vec2(lh, 2.)), rand(vec2(lh, 3.)));
            vec3 cb = vec3(rand(vec2(lh, 4.)), rand(vec2(lh, 5.)), rand(vec2(lh, 6.)));
            vec3 color = 0.5 * h + 0.5 * mix(ca, cb, 0.5 + 0.5 * sin(h + t));

            col += color * glow * 0.5 + color * pulse * 2.0;
        }
    }

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
