// void mainImage(out vec4 fragColor, in vec2 fragCoord)
// {
//     vec2 uv = fragCoord.xy / iResolution.xy;
//     uv = uv * 2.0 - 1.0;
//     uv.x *= iResolution.x / iResolution.y;

//     vec3 col = vec3(0.0);
//     float space = 700.0;
    
//     // each star
//     for (int i = 0; i < 4000; i++) {
//         float fi = float(i);
//         float angle = fract(sin(fi * 12.9898) * 43758.5453) * 6.28318;
//         float raw = fract(sin(fi * 78.233) * 12345.6789);
        
//         // avoid divide by 0 (causes one stranded star in the middle)
//         float radius = sqrt(0.001 + 0.99 * raw) * space;
        
//         float x = cos(angle) * radius;
//         float y = sin(angle) * radius;
//         float z = mod(fi * 10.0 + iTime * 500.0, 700.0);

//         // Project to screen
//         float sx = x / z;
//         float sy = y / z;

//         float maxRadius = 13.0 + mod(fi, 5.0);
//         float r = mix(maxRadius, 0.0, z / space);

//         vec2 starPos = vec2(sx, sy);
//         float d = length(uv - starPos);

//         col += smoothstep(0.01, 0.0, d);
//     }

//     fragColor = vec4(col, 1.0);
// }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    vec3 col = vec3(0.0);
    float space = 700.0;
    
    //int start_index = int(iTime);
    // each star
    for (int i = 0; i < 3000; i++) {
        float fi = float(i);
        float angle = fract(sin(fi * 12.9898) * 43758.5453) * 6.28318;
        float raw = fract(sin(fi * 78.233) * 12345.6789);
        float radius = sqrt(0.001 + 0.99 * raw) * space;
        
        float x = cos(angle) * radius;
        float y = sin(angle) * radius;
        float z = mod(fi + iTime * 100.0, space);

        if (z < 1.0) continue;

        float sx = x / z;
        float sy = y / z;
        vec2 starPos = vec2(sx, sy);
        float d = length(uv - starPos);

        if (d > 0.05) continue;

        float brightness = smoothstep(0.005, 0.0, d) * (1.0 - z / space);
        float twinkle = 0.5 + 0.5 * sin(iTime * 10.0 + fi);
        vec3 color = vec3(
            0.8 + 0.2 * fract(sin(fi * 2.0) * 43758.5453),
            0.8 + 0.2 * fract(sin(fi * 3.0) * 43758.5453),
            1.0
        );

        col += color * brightness * twinkle;
    }

    fragColor = vec4(col, 1.0);
}