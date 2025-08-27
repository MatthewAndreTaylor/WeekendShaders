// Infinite Tower of Lire - Matthew Taylor
// https://en.wikipedia.org/wiki/Block-stacking_problem

struct Camera {
    vec3 Obs;
    vec3 View;
    vec3 Up;
    vec3 Horiz;
    float H;
    float W;
    float z;
};

struct Ray {
    vec3 Origin;
    vec3 Dir;
};

Camera camera(in vec3 Obs, in vec3 LookAt, in float aperture) {
   Camera C;
   C.Obs = Obs;
   C.View = normalize(LookAt - Obs);
   C.Horiz = normalize(cross(vec3(0.0, 0.0, 1.0), C.View));
   C.Up = cross(C.View, C.Horiz);
   C.W = float(iResolution.x);
   C.H = float(iResolution.y);
   C.z = (C.H/2.0) / tan((aperture * 3.1415 / 180.0) / 2.0);
   return C;
}

Ray launch(in Camera C, in vec2 XY) {
   return Ray(
      C.Obs,
      normalize(C.z*C.View+(XY.x-C.W/2.0)*C.Horiz+(XY.y-C.H/2.0)*C.Up)
   );
}

float sdBox(vec3 p, vec3 c, vec3 b) {
    vec3 d = abs(p-c) - b;
    return length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
}

float blockSDF(vec3 p, float bw, float bh, float bd, float offset) {
    return sdBox(p, vec3(offset, 0.0, 0.0), vec3(bw*0.5, bd, bh*0.5));
}

float towerSDF(vec3 p, float bw, float bh, float bd) {
    float spacing = bh * 1.5;
    float layer = floor(p.z / spacing);
    if (layer < 2.0){
        return 1.0;
    }

    // local z coordinate inside this layer
    vec3 q = p;
    q.z = mod(p.z, spacing) - 0.1 * spacing;

    // Layer index -> harmonic offset
    float offset = bw / (2.0 - abs(layer));  
    return blockSDF(q, bw, bh, bd, offset);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float time = (100.0 + float(iFrame)) / 100.0;

    // Block dimensions are effected by time
    float bw = 1.0 / time;   // block length
    float bh = bw * 0.2;     // block height
    float bd = bw * 0.5;     // depth

    // Camera
    float beta = 3.14/4.0 + 0.2;
    float s = sin(beta), c = cos(beta);
    Camera C = camera(vec3(1.0*c,7.0*s,3.0), vec3(0.0,0.0,2.5), 50.0);
    Ray R = launch(C, fragCoord);

    // Raymarch
    float t = 0.0;
    float dist = 0.0;
    vec3 col = vec3(0.7,0.8,1.0);
    for(int steps=0; steps<128; steps++) {
        vec3 p = R.Origin + t*R.Dir;

        float d = towerSDF(p, bw, bh, bd);
        dist = d;
        if(dist < 0.001) {
            col = vec3(0.75,0.55,0.3);
            break;
        }
        t += dist;
        if(t > 50.0) break;
    }

    fragColor = vec4(col,1.0);
}
