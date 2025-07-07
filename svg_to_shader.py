from svgpathtools import svg2paths2, Line, QuadraticBezier, CubicBezier, Arc
from pathlib import Path as SysPath

def cubic_split_half(cubic):
    p0, p1, p2, p3 = cubic.start, cubic.control1, cubic.control2, cubic.end
    q0 = (p0 + p1) / 2
    q1 = (p1 + p2) / 2
    q2 = (p2 + p3) / 2
    r0 = (q0 + q1) / 2
    r1 = (q1 + q2) / 2
    s = (r0 + r1) / 2

    left = CubicBezier(p0, q0, r0, s)
    right = CubicBezier(s, r1, q2, p3)
    return left, right

def cubic_to_quadratic(cubic):
    p0, p1, p2, p3 = cubic.start, cubic.control1, cubic.control2, cubic.end
    ctrl = (3*p1 - p0 + 3*p2 - p3) / 4
    return QuadraticBezier(p0, ctrl, p3)

def cubic_to_quadratic_simple(cubic):
    p0, p1, p2, p3 = cubic.start, cubic.control1, cubic.control2, cubic.end
    return QuadraticBezier(p0, p1, p3)

def cubic_to_two_quadratics(cubic):
    left, right = cubic_split_half(cubic)
    
    # Curves are more accurate however, they may miss some details
    # quad_left = cubic_to_quadratic(left)
    # quad_right = cubic_to_quadratic(right)
    
    # Simple quadratics are less accurate but seem to preserve the shape better
    quad_left = cubic_to_quadratic_simple(left)
    quad_right = cubic_to_quadratic_simple(right)
    return [quad_left, quad_right]

def segment_to_quadratics(segment):
    if isinstance(segment, QuadraticBezier):
        return [segment]
    elif isinstance(segment, Line):
        return [QuadraticBezier(segment.start, segment.end, segment.end)]
    elif isinstance(segment, CubicBezier):
        return cubic_to_two_quadratics(segment)
    elif isinstance(segment, Arc):
        raise NotImplementedError("Arc to quadratic conversion not implemented")
    else:
        raise TypeError(f"Unsupported segment type: {type(segment)}")

def compute_bbox(beziers):
    xs, ys = [], []
    for path_beziers in beziers:
        for bez in path_beziers:
            for pt in [bez.start, bez.end]:
                xs.append(pt.real)
                ys.append(pt.imag)
    xmin, xmax = min(xs), max(xs)
    ymin, ymax = min(ys), max(ys)
    return xmin, xmax, ymin, ymax

def normalize(c, xmin, xmax, ymin, ymax):
    cx, cy = (xmin + xmax) / 2, (ymin + ymax) / 2
    scale = max(xmax - xmin, ymax - ymin) / 2
    return complex((c.real - cx) / scale, -(c.imag - cy) / scale)

def complex_to_vec2(c):
    return f"vec2({c.real:.3f}, {c.imag:.3f})"

def generate_chained_min(beziers, xmin, xmax, ymin, ymax):
    exprs = []
    
    for path_beziers in beziers:
        prev_end = None
        
        for bez in path_beziers:
            a = normalize(bez.start, xmin, xmax, ymin, ymax)
            b = normalize(bez.control, xmin, xmax, ymin, ymax)
            c = normalize(bez.end, xmin, xmax, ymin, ymax)
            
            # join all segments into one if they are all connected
            # moving prev_end to the outer scope treats each path as a single segment
            if prev_end is not None:
                if prev_end != a:
                    a = prev_end
                    
            expr = f"sdBezier(pos, {complex_to_vec2(a)}, {complex_to_vec2(b)}, {complex_to_vec2(c)})"
            exprs.append(expr)
            prev_end = c
            
    res = exprs[0]
    for e in exprs[1:]:
        res = f"min({res}, {e})"
    return res

def convert_svg_to_glsl(input_svg):
    paths, _, _ = svg2paths2(input_svg)
    all_beziers = []

    for path in paths:
        path_beziers = []
        for segment in path:
            path_beziers.extend(segment_to_quadratics(segment))
            
        all_beziers.append(path_beziers)

    xmin, xmax, ymin, ymax = compute_bbox(all_beziers)
    shape_expr = generate_chained_min(all_beziers, xmin, xmax, ymin, ymax)

    shader = f"""\
float sdBezier(vec2 pos, vec2 A, vec2 B, vec2 C)
{{    
    vec2 a = B - A;
    vec2 b = A - 2.0*B + C;
    vec2 c = a * 2.0;
    vec2 d = A - pos;
    float kk = 1.0 / dot(b, b + 1e-8);
    float kx = kk * dot(a, b);
    float ky = kk * (2.0 * dot(a, a) + dot(d, b)) / 3.0;
    float kz = kk * dot(d, a);      
    float res = 0.0;
    float p = ky - kx * kx;
    float p3 = p * p * p;
    float q = kx * (2.0 * kx * kx - 3.0 * ky) + kz;
    float h = q * q + 4.0 * p3;

    if (h >= 0.0) 
    {{ 
        h = sqrt(h);
        vec2 x = (vec2(h, -h) - q) / 2.0;
        vec2 uv = sign(x) * pow(abs(x), vec2(1.0 / 3.0));
        float t = clamp(uv.x + uv.y - kx, 0.0, 1.0);
        vec2 pt = d + (c + b * t) * t;
        res = dot(pt, pt);
    }}
    else
    {{
        float z = sqrt(-p);
        float v = acos(q / (2.0 * p * z)) / 3.0;
        float m = cos(v);
        float n = sin(v) * 1.732050808;
        vec3 t = clamp(vec3(m + m, -n - m, n - m) * z - kx, 0.0, 1.0);
        vec2 pt1 = d + (c + b * t.x) * t.x;
        vec2 pt2 = d + (c + b * t.y) * t.y;
        res = min(dot(pt1, pt1), dot(pt2, pt2));
    }}
    return sqrt(res);
}}

float shape(vec2 pos)
{{
    return {shape_expr};
}}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float d = shape(p);

    float thickness = 0.005;
    float alpha = smoothstep(thickness, 0.0, abs(d));
    vec3 color = mix(vec3(1.0), vec3(0.2, 0.6, 1.0), alpha);
    
    fragColor = vec4(color, 1.0);
}}"""
    return shader

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Convert SVG to GLSL shader with normalized Bézier curves.")
    parser.add_argument("input_svg", type=str, help="Path to the input SVG file")
    parser.add_argument("--output", type=str, default="output_shader.glsl", help="Path to the output GLSL file")
    args = parser.parse_args()
    
    glsl_code = convert_svg_to_glsl(args.input_svg)
    SysPath(args.output).write_text(glsl_code)
    print(f"Shader with normalized Bézier curves written to {args.output}")
