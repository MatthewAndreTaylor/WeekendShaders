// Matthew Andre Taylor 2025

const float pc = 6.;

bool voxelChicken(vec3 p){
    p = floor(p);
    
    // Body
    if (
        p.x >= 5. && p.x <= 9. &&
        p.y >= 5.  && p.y <= 9. &&
        p.z >= 2. && p.z <= 4.
    ) return true;

    // Head
    if (
        p.x >= 5. && p.x <= 6. &&
        p.y >= 6. && p.y <= 8. &&
        p.z >= 4. && p.z <= 9.
    ) return true;
    
    // Beek
    if (
        p.x >= 3. && p.x <= 4. &&
        p.y == 7. &&
        p.z == 8.
    ) return true;
    
    // Feet
    if (
        p.x == 6. &&
        p.y >= 6.  && p.y <= 8. &&
        p.z >= 0. && p.z <= 1. &&
        p.y != 7.
    ) return true;

    return false;
}

float line(vec2 uv, vec2 a, vec2 b){
    float x = min(length(uv-a),length(uv-b));
    vec2 v = normalize(b-a);
    if (dot(v, uv-a) > 0. && dot(v, uv-a) < length(a-b)) x = min(x, abs(dot(uv-a, v.yx*vec2(-1,1)))); 
    return x;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 res = iResolution.xy;
    vec2 uv = fragCoord / res;
    vec2 cuv = (2.0 * fragCoord - res) / res.y;
    vec2 muv = vec2(iTime/4., -.2);

    const int lines = 16;
    const float flines = float(lines);

    vec2 camM = muv*2.;
    vec3 camF = vec3(sin(camM.x)*cos(camM.y), cos(camM.x)*cos(camM.y), sin(camM.y));
    vec3 camR = normalize(cross(camF, vec3(0,0,1)));
    vec3 camU = cross(camR, camF);
    vec3 camOrigin = vec3(0.4) - 4.0 * camF;

    // Box vertices
    vec3 boxVerts[8] = vec3[](
        vec3(0,0,0), vec3(0,0,1), vec3(0,1,0), vec3(0,1,1),
        vec3(1,0,0), vec3(1,0,1), vec3(1,1,0), vec3(1,1,1)
    );

    // Project box to camera space
    vec3 projected[8];
    for (int i = 0; i < 8; ++i) {
        vec3 rel = boxVerts[i] - camOrigin;
        projected[i] = vec3(
            dot(camR, rel),
            dot(camU, rel),
            dot(camF, rel) / pc
        );
    }

    // Draw grid lines
    float minDist = 1e5;
    for (int i = 0; i <= lines; ++i) {
        float f = float(i) / flines;
        vec3 a = mix(projected[0], projected[4], f);
        vec3 b = mix(projected[2], projected[6], f);
        minDist = min(minDist, line(cuv, a.xy / a.z, b.xy / b.z));
        a = mix(projected[0], projected[2], f);
        b = mix(projected[4], projected[6], f);
        minDist = min(minDist, line(cuv, a.xy / a.z, b.xy / b.z));
    }

    float grid = 0.5 * exp(-pow(minDist / (1. / res.y), 2.));
    vec3 rayDir = camF + camR * (cuv.x / pc) + camU * (cuv.y / pc);
    float t = 0.;
    vec3 voxelCoords;
    vec3 stepDist, hitNormal = vec3(0.0);
    bvec3 positiveDir = greaterThan(rayDir, vec3(0.0));
    bool hit = false;

    for (int i = 0; i < 256; ++i) {
        voxelCoords = camOrigin * flines + rayDir * t;

        if (voxelChicken(voxelCoords)) {
            hit = true;
            break;
        }

        for (int j = 0; j < 3; ++j) {
            float delta = positiveDir[j] ? ceil(voxelCoords[j]) - voxelCoords[j]: floor(voxelCoords[j]) - voxelCoords[j];
            stepDist[j] = delta / rayDir[j];
        }

        float stepMin = min(min(stepDist.x, stepDist.y), stepDist.z);
        t += stepMin + 1e-4;
    }

    if (hit) {
        int l = stepDist.x < stepDist.y ? (stepDist.x < stepDist.z ? 0 : 2): (stepDist.y < stepDist.z ? 1 : 2);
        hitNormal[l] = -sign(rayDir[l]);
        fragColor = vec4(hitNormal.xyzz * 0.5 + 1.) / log(t * 0.5);
    } else {
        fragColor = vec4(vec3(grid), 1.);
    }
}