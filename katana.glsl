float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

float sdRoundedRect(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b;
    return length(max(q, 0.0)) - r + min(max(q.x, q.y), 0.0);
}

float sdDiamond(vec2 p, float s) {
    p = abs(p);
    return (p.x + p.y - s) * 0.7071;
}

vec3 blend(vec3 base, vec3 color, float d) {
    float edge = 0.002;
    float t = smoothstep(edge, 0.0, d);
    return mix(base, color, t);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 col = vec3(0.1);

    vec2 bladePos = uv - vec2(-0.05, 0.2);
    float blade = sdRoundedRect(bladePos, vec2(0.07, 0.25), 0.05);
    blade = max(blade, -bladePos.x);
    vec3 topColor = vec3(0.5, 0.7, 1.0);
    vec3 bottomColor = vec3(0.3, 0.5, 0.8);
    float gradientT = clamp((bladePos.y + 0.25) / 0.5, 0.0, 1.0);
    vec3 bladeColor = mix(topColor, bottomColor, gradientT);
    col = blend(col, bladeColor, blade);

    vec2 guardPos = uv - vec2(0.0, -0.075);
    float guard = sdRoundedRect(guardPos, vec2(0.12, 0.02), 0.02);
    col = blend(col, vec3(1.0, 0.6, 0.3), guard);

    vec2 handlePos = uv - vec2(0.0, -0.25);
    float handle = sdBox(handlePos, vec2(0.05, 0.15));
    col = blend(col, vec3(0.7, 0.9, 0.7), handle);

    vec2 pommelPos = uv - vec2(0.0, -0.42);
    float pommel = sdCircle(pommelPos, 0.06);
    col = blend(col, vec3(1.0, 0.6, 0.3), pommel);

    for (float y = -0.16; y >= -0.32; y -= 0.12) {
        vec2 diamondPos = uv - vec2(0.0, y);
        float diamond = sdDiamond(diamondPos, 0.05);
        col = blend(col, vec3(0.4, 0.3, 0.6), diamond);
    }

    fragColor = vec4(col, 1.0);
}
