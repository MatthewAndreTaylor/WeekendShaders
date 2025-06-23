const float PI_2 = 1.57;
const vec3 baseColor = vec3(1.2, 0.6, 1.0);

vec2 rotate(vec2 p, float angle) {
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c) * p;
}

float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

float sdCapsule(vec2 p, float r, float h) {
    p.y -= smoothstep(0.0, h, abs(p.y)) * h * sign(p.y);
    return sdCircle(p, r);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 color = vec3(0.1, 0.05, 0.1); // Background

    float scale = 0.5;
    float t = iTime * 5.0;
    float jumpPhase = sin(t / 3.0);
    float jumpOffset = smoothstep(0.9, 1.0, abs(jumpPhase)) * 0.25;
    
    vec2 p = (uv - vec2(0.0, jumpOffset)) / scale;
    vec2 op = p;
    vec3 c = vec3(0.9);

    float f = ((p.y + 0.6) / 1.2) * sin(t);
    p.x += cos(t) * 0.2;
    p = rotate(p, f);
    op = p;
    float body = sdCapsule(p, 0.2, 0.3);

    // Eyes
    float eyes = 1.0 - smoothstep(0.02, 0.02, length(p + vec2(0.1, -0.4)));
    eyes += 1.0 - smoothstep(0.02, 0.02, length(p + vec2(-0.1, -0.4)));
    c += vec3(3.0) * eyes;

    // Nose
    float nose = sdCircle(p + vec2(0.0, -0.39), 0.015);
    c += vec3(1.0, 0.5, 0.5) * (1.0 - smoothstep(0.0, 0.0, nose));

    // Mouth
    float mouth = sdCircle((p + vec2(0.0, -0.35)) * vec2(0.6 + cos(t * 2.0) * 0.2, 1.0), 0.03);
    
    // Hat
    float hatTop = sdBox(p + vec2(0.0, -0.55), vec2(0.12, 0.08));
    float hatBrim = sdBox(p + vec2(0.0, -0.45), vec2(0.2, 0.02));
    float hat = min(hatTop, hatBrim);

    // Arms
    p = op;
    p.y -= 0.1;
    p = rotate(p, sin(t * 2.0) * 0.25 * smoothstep(0.5, 0.6, abs(p.x)) + PI_2);
    float arms = sdCapsule(p, 0.08, 0.4);

    // Legs
    p = op;
    p.y += 0.3;
    p = rotate(p, PI_2 - p.x * 3.0);
    float legs = sdCapsule(p, 0.1, 0.3);

    body = max(body, -mouth);
    body = min(min(body, arms), legs);
    body = min(body, hat);
    float shape = 1.0 - smoothstep(0.0, 0.0, body);

    c += baseColor * shape;
    color += c * (shape * 0.2);
    color += c * (hat * 0.1); // Gradient around hat
    
    fragColor = vec4(color, 1.0);
}
