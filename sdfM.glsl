// Matthew Andre Taylor 2025

float rectSDF(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

float triPrismSDF( vec3 p, vec2 h )
{
  vec3 q = abs(p);
  return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}

// "M" as a signed distance function
float mSDF(vec3 p) {
    float legHeight = 1.0;
    float legWidth = 0.15;
    float legSpacing = 0.8;
    float diagHeight = 0.9;
    float diagWidth = 0.15;

    // Vertical legs
    float d1 = rectSDF(p - vec3(-legSpacing, 0.0, 0.0), vec3(legWidth, legHeight, legWidth));
    float d2 = rectSDF(p - vec3(legSpacing, 0.0, 0.0), vec3(legWidth, legHeight, legWidth));

    // Upside down triangle bottom
    vec3 pb = p - vec3(0.0, 0.55, 0.0);
    pb.y *= -1.0; // Flip vertically
    float prismB = triPrismSDF(pb, vec2(diagHeight, diagWidth));
    
    // Upside down triangle top
    vec3 pa = p - vec3(0.0, 1, 0.0);
    pa.y *= -1.0;
    float prismA = triPrismSDF(pa, vec2(diagHeight, 1.0));
    
    float d3 = max(-prismA, prismB); // subtract the top triangle from the bottom
    return min(min(d1, d2), d3);
}