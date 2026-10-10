const float SPEED = 0.7;
const int BALL_COUNT = 12;
const float BALL_RADIUS = 14.0;
const bool SHOW_LINES = true;
const float PI = 3.14159265359;

vec3 palette(float t)
{
    return 0.55 + 0.45 * cos(6.2831853 * (t + vec3(0.0, 0.33, 0.67)));
}

vec2 ballPosition(float angle, float time)
{
    // Equally spaced diameter oscillators generalize the Java's eight paths.
    return 300.0 * vec2(cos(angle), sin(angle)) * sin(time + angle);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float pixel = 800.0 / max(min(iResolution.x, iResolution.y), 1.0);
    vec2 p = (fragCoord - 0.5 * iResolution.xy) * pixel;
    p.y = -p.y;
    float time = SPEED * iTime;
    float radius = length(p);
    float disk = 1.0 - smoothstep(310.0 - pixel, 310.0 + pixel, radius);
    vec3 col = mix(vec3(0.006, 0.009, 0.02), vec3(0.018, 0.03, 0.05), disk);
    col += vec3(0.012, 0.025, 0.045) * exp(-radius * radius / 90000.0);

    if (SHOW_LINES)
    {
        float angle = atan(p.y, p.x + 0.0001);
        float spokes = abs(sin(angle * float(BALL_COUNT))) * radius / float(BALL_COUNT);
        float rings = abs(mod(radius + 37.5, 75.0) - 37.5);
        float grid = 1.0 - smoothstep(0.3, 0.3 + pixel, min(spokes, rings));
        col += vec3(0.018, 0.045, 0.065) * grid * disk;
    }
    float rim = abs(radius - 310.0);
    col += vec3(0.04, 0.45, 0.7) * (exp(-rim * 0.65) + 0.12 * exp(-rim * 0.08));

    vec3 glow = vec3(0.0);
    float shadow = 0.0;
    float nearest = -1.0;
    float coverage = 0.0;
    vec3 sphereColor = vec3(0.0);
    for (int i = 0; i < BALL_COUNT; ++i)
    {
        float id = float(i) / float(BALL_COUNT);
        float angle = PI * id;
        vec2 center = ballPosition(angle, time);
        vec2 delta = p - center;
        vec3 tint = palette(id);
        float distanceToBall = length(delta);
        vec2 shadowDelta = p - center - vec2(7.0, 10.0);
        shadow += 0.45 * exp(-dot(shadowDelta, shadowDelta) / (BALL_RADIUS * BALL_RADIUS * 1.8));

        for (int j = 1; j <= 6; ++j)
        {
            float age = float(j) * 0.035;
            vec2 trailDelta = p - ballPosition(angle, time - age);
            glow += tint * 0.035 * (1.0 - float(j) / 7.0)
                    * exp(-dot(trailDelta, trailDelta) / 65.0);
        }

        float mask = 1.0 - smoothstep(BALL_RADIUS - pixel, BALL_RADIUS + pixel, distanceToBall);
        if (mask > 0.0)
        {
            vec2 xy = delta / BALL_RADIUS;
            float z = sqrt(max(1.0 - dot(xy, xy), 0.0));
            // Compare sphere surfaces so overlaps do not depend on drawing order.
            if (z > nearest)
            {
                nearest = z;
                coverage = mask;
                vec3 normal = normalize(vec3(xy, max(z, 0.001)));
                float diffuse = max(dot(normal, normalize(vec3(-0.5, -0.6, 1.0))), 0.0);
                sphereColor = tint * (0.55 + 0.45 * diffuse);
            }
        }
    }
    col = col * exp(-shadow) + glow;
    col = mix(col, sphereColor, coverage);
    col *= 1.0 - 0.3 * smoothstep(300.0, 650.0, radius);
    col = col / (1.0 + col);
    fragColor = vec4(pow(max(col, 0.0), vec3(1.0 / 2.2)), 1.0);
}
