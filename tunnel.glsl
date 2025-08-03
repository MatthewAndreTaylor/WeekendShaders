const float farPlane = 128.;
const float pix2 = 6.28;

mat2 rot2(float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

const float base = 22222.;
float rand(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * base); }

float hexagonSDF(vec3 p, vec3 b) {
    p = abs(p);
    p.yz = vec2(p.y * 0.8660254 + p.z * 0.5, p.z);
    p -= b;
    return min(max(max(p.x, p.y), p.z), 0.) + length(max(p, 0.)) - .01;
}

vec2 map(vec3 p, float c) {
    p.xy -= vec2(sin(p.z * .085) * c, cos(p.z * .085) * c);
    const float aNum = 6.0;
    float tunRad = 1.;
    float zScale = 2.;
    float blockRad = 0.05;
    vec3 wd = vec3(blockRad, .3 * zScale, .3 * zScale);
    p.z /= zScale;

    vec3 q = p;
    float a = atan(q.y, q.x);
    float sector = floor(aNum * mod(a / pix2, 1.));
    float depth = floor(p.z);
    q.xy = rot2(a) * q.xy;
    q = vec3(q.x - (tunRad + blockRad), (mod(a / pix2, 1. / aNum) - .5 / aNum) * pix2, mod(q.z, 1.0) - 0.5);
    q.z *= zScale;
    float d = hexagonSDF(q, wd);
    return vec2(d, rand(vec2(sector, depth)));
}

vec3 getNormal(vec3 p, float c) {
    vec2 e = vec2(0.01, 0);
    return normalize(vec3(
        map(p + e.xyy, c).x - map(p - e.xyy, c).x,
        map(p + e.yxy, c).x - map(p - e.yxy, c).x,
        map(p + e.yyx, c).x - map(p - e.yyx, c).x
    ));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 camPos = vec3(0, 0, iTime * 3.);
    vec3 lookAt = camPos + vec3(0, 0, 0.5);
    float c = clamp(((iMouse.x / iResolution.x) * 2.0 - 1.0) * 5.0, -5.0, 5.0);

    lookAt.xy += vec2(sin(lookAt.z * .085) * c, cos(lookAt.z * .085) * c);
    camPos.xy += vec2(sin(camPos.z * .085) * c, cos(camPos.z * .085) * c);

    vec3 forward = normalize(lookAt - camPos);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x));
    vec3 up = cross(forward, right);
    vec3 rd = normalize(forward + uv.x * right + uv.y * up);
    rd.xy = rot2(sin(lookAt.z * .085) * 7. / 32.) * rd.xy;

    float t = 0.0;
    vec2 res;
    for (int i = 0; i < 128; i++) {
        res = map(camPos + t * rd, c);
        if (abs(res.x) < 0.001 || t > farPlane) break;
        t += res.x;
    }

    vec3 color = vec3(0);
    if (t < farPlane) {
        vec3 pos = camPos + t * rd;
        float hash = res.y;

        vec3 normal = getNormal(pos, c);
        float diff = max(dot(normal, normalize(vec3(-0.35, 0, -0.25))), 0.0);
        
        vec3 baseColor = vec3(
            0.5 + 0.5 * sin(hash * 12.9898),
            0.5 + 0.5 * sin(hash * 78.233),
            0.5 + 0.5 * sin(hash * 47.719)
        );
        color = baseColor * diff;
    }

    fragColor = vec4(color, 1.0);
}