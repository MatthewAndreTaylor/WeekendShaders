#define MAX_LEVEL 5
#define MAX_BRANCHES 256

const float PI = 3.14159265;

vec2 rand2(float i) {
    return vec2(
        fract(sin(i * 12.9898 + iMouse.x) * 43758.5453),
        fract(sin(i * 78.233 + iMouse.x) * 12345.6789)
    );
}

vec3 drawLine(vec2 uv, vec2 a, vec2 b, float thickness) {
    vec2 pa = uv - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float dist = length(pa - ba * h);
    float edge = fwidth(dist);
    float t = smoothstep(thickness + edge, thickness - edge, dist);
    return vec3(t);
}

float drawCircle(vec2 uv, vec2 center, float radius) {
    float dist = length(uv - center);
    float edge = fwidth(dist);
    return smoothstep(radius + edge, radius - edge, dist);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord.xy / iResolution.xy) * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    vec3 col = vec3(0.9); // background (0.0 black)
    vec2 root = vec2(0.0, -0.8);
    float baseLength = 0.5;
    float baseWeight = 10.0;

    vec2 startPos[MAX_BRANCHES];
    vec2 endPos[MAX_BRANCHES];
    float thickness[MAX_BRANCHES];
    int levelIndex[MAX_BRANCHES];
    float offset = rand2(0.0).x * 0.2 - 0.1;

    int branchCount = 1;
    startPos[0] = root;
    endPos[0] = root + vec2(sin(offset), cos(offset)) * baseLength;
    thickness[0] = baseWeight;
    levelIndex[0] = 0;
    int cursor = 0;

    for (int level = 0; level < MAX_LEVEL; level++) {
        int prevCount = branchCount;
        for (int i = cursor; i < prevCount; i++) {
            int n = (level >= 2) ? 3 + int(rand2(float(i)).x * 7.0) : 4 + int(rand2(float(i)).x * 3.0);
            for (int j = 0; j < n; j++) {
                levelIndex[branchCount] = level + 1;
                if (branchCount >= MAX_BRANCHES) break;
                float a = atan(endPos[i].x - startPos[i].x, endPos[i].y - startPos[i].y);
                float offset = rand2(float(i * 10 + j)).x * (PI * 0.6 + float(level) * 0.1) - (PI * 0.3 + float(level) * 0.05);
                float len = baseLength * pow(0.7, float(level + 1));
                vec2 dir = vec2(sin(a + offset), cos(a + offset)) * len;

                startPos[branchCount] = endPos[i];
                endPos[branchCount] = endPos[i] + dir;
                thickness[branchCount] = thickness[i] * 0.5;
                branchCount++;
            }
        }
        cursor = prevCount;
    }

    for (int i = 0; i < MAX_BRANCHES; i++) {
        vec3 lineCol = vec3(0.15, 0.1, 0.05);
        col = mix(col, lineCol, drawLine(uv, startPos[i], endPos[i], thickness[i] / iResolution.y).x);
    }
    
    // Draw the tree leaves
    for (int i = 0; i < MAX_BRANCHES; i++) {
        if (levelIndex[i] >= MAX_LEVEL-2){
            float purple = (endPos[i].x + 0.5) * (endPos[i].y + 0.9) + 0.5;
            vec3 leafColor = vec3(purple, 0.145, 0.67);
            float radius = 0.01 + rand2(float(i)).y * 0.015;
            col = mix(col, leafColor, drawCircle(uv, endPos[i], radius));
        }
    }

    fragColor = vec4(col, 1.0);
}
