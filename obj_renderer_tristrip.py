from pathlib import Path as SysPath
from collections import defaultdict


def parse_obj(text: str):
    verts, faces = [], []
    for line in text.splitlines():
        if line.startswith("v "):
            _, x, y, z = line.split()
            verts.append((float(x), float(y), float(z)))
        elif line.startswith("f "):
            parts = line.split()
            a, b, c = [int(p.split("/")[0]) - 1 for p in parts[1:4]]
            faces.append((a, b, c))
    return verts, faces


def pack_vertices(vertices):
    qbits = 10
    max_v = (1 << qbits) - 1
    xs = [v[0] for v in vertices]
    ys = [v[1] for v in vertices]
    zs = [v[2] for v in vertices]
    min_v = (min(xs), min(ys), min(zs))
    max_v_world = (max(xs), max(ys), max(zs))
    center = (
        (min_v[0] + max_v_world[0]) * 0.5,
        (min_v[1] + max_v_world[1]) * 0.5,
        (min_v[2] + max_v_world[2]) * 0.5,
    )
    extent = (
        max(
            max_v_world[0] - min_v[0],
            max_v_world[1] - min_v[1],
            max_v_world[2] - min_v[2],
        )
        * 0.5
    )
    packed = []

    for x, y, z in vertices:
        x -= center[0]
        y -= center[1]
        z -= center[2]
        px = round(((x / extent) * 0.5 + 0.5) * max_v)
        py = round(((y / extent) * 0.5 + 0.5) * max_v)
        pz = round(((z / extent) * 0.5 + 0.5) * max_v)
        d = px | (py << qbits) | (pz << (2 * qbits))
        packed.append(d)

    return packed


def build_triangle_strip(faces):
    RESTART = 0xFFFFFFFF

    edge_to_faces = defaultdict(list)
    for fi, (a, b, c) in enumerate(faces):
        for u, v in ((a, b), (b, c), (c, a)):
            for e in ((u, v), (v, u)):
                edge_to_faces[e].append(fi)

    used = set()
    strip = []

    for start_face in range(len(faces)):
        if start_face in used:
            continue

        if strip:
            strip.append(RESTART)

        used.add(start_face)
        a, b, c = faces[start_face]
        strip.extend([a, b, c])
        last_a, last_b = b, c

        while True:
            next_face = None
            for fi in edge_to_faces[(last_a, last_b)]:
                if fi not in used:
                    next_face = fi
                    break

            if next_face is None:
                break

            used.add(next_face)
            next_vertex = None
            for v in faces[next_face]:
                if v != last_a and v != last_b:
                    next_vertex = v
                    break

            strip.append(next_vertex)
            last_a, last_b = last_b, next_vertex

    return strip


def format_uvec4_array(data, name):
    padded_data = list(data)
    while len(padded_data) % 4 != 0:
        padded_data.append(0)

    vecs = []
    for i in range(0, len(padded_data), 4):
        vecs.append(
            f"uvec4({padded_data[i]}U,{padded_data[i+1]}U,{padded_data[i+2]}U,{padded_data[i+3]}U)"
        )

    return f"const uvec4 {name}[{len(vecs)}] = uvec4[](\n    {','.join(vecs)}\n);\n"


glsl_code_template = """const uint RESTART = 0xFFFFFFFFu;
const float INV_MAX_IDX = 2.0 / 1023.0;
const float PI = 3.14159;

uint getIndex(int i) { 
    return idx[i / 4][i % 4]; 
}

uint getVertData(int id) {
    return vertices[id / 4][id % 4];
}

vec3 getVertex(uint id) {
    uint d = getVertData(int(id));
    return vec3(float(d & 1023u), float((d >> 10) & 1023u), float((d >> 20) & 1023u)) * INV_MAX_IDX - 1.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec2 m = iMouse.x <= 0.0 ? vec2(0.5) : iMouse.xy / iResolution.xy;

    float yaw = (m.x - 0.5) * PI;
    float pitch = (m.y - 0.5) * PI;
    vec3 ro = 2.0 * vec3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch));
    vec3 f = normalize(-ro), r = normalize(cross(vec3(0.0, 1.0, 0.0), f));
    vec3 rd = normalize(r * uv.x + cross(f, r) * uv.y + f * 1.5);

    float minT = 1e10;
    vec3 normal = vec3(0.0);
    vec3 invRd = 1.0 / rd;
    vec3 t0 = (-1.0 - ro) * invRd, t1 = (1.0 - ro) * invRd;
    vec3 tmin = min(t0, t1), tmax = max(t0, t1);
    float tnear = max(max(tmin.x, tmin.y), tmin.z);
    float tfar = min(min(tmax.x, tmax.y), tmax.z);

    if (tnear < tfar && tfar > 0.0) {
        uint i0, i1 = getIndex(0), i2 = getIndex(1);
        vec3 v0, v1 = vec3(0), v2 = vec3(0);
        if (i1 != RESTART) v1 = getVertex(i1);
        if (i2 != RESTART) v2 = getVertex(i2);

        for (int i = 0; i < numIdx - 2; i++) {
            i0 = i1; v0 = v1;
            i1 = i2; v1 = v2;
            i2 = getIndex(i + 2);
            if (i2 != RESTART) v2 = getVertex(i2);
            if (i0 == RESTART || i1 == RESTART || i2 == RESTART) continue;
            vec3 a = (i % 2 == 0) ? v0 : v1;
            vec3 b = (i % 2 == 0) ? v1 : v0;
            vec3 v1v0 = b - a, v2v0 = v2 - a, rov0 = ro - a;
            vec3 n = cross(v1v0, v2v0), q = cross(rov0, rd);
            float d = 1.0 / dot(rd, n);
            float u = d * dot(-q, v2v0), v = d * dot(q, v1v0), t = d * dot(-n, rov0);

            if (u >= 0.0 && v >= 0.0 && (u + v) <= 1.0 && t > 0.0 && t < minT) {
                minT = t;
                normal = n;
            }
        }
    }
    
    // bg
    vec3 col = vec3(1.0);
    if (minT < 1e9) {
        normal = normalize(normal); 
        normal = faceforward(normal, rd, normal);
        float diff = max(dot(normal, normalize(vec3(1.0, 1.2, 0.8))), 0.0);
        float fill = max(dot(normal, normalize(vec3(-1.0, 0.5, -0.5))), 0.0) * 0.25;
        col = vec3(1.0, 0.5, 0.2) * (0.3 + diff + fill);
    }
    fragColor = vec4(col, 1.0);
}
"""


# Some examples from the objaverse dataset:
# https://huggingface.co/datasets/dylanebert/objaverse-lowpoly-obj/blob/main/000-078/0ac45bd0290846c0adccc9adffcec477.obj
# https://huggingface.co/datasets/dylanebert/objaverse-lowpoly-obj/blob/main/000-078/43eecbdc415541848e3864b72bd05477.obj

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Convert OBJ file to GLSL shader ready for rendering"
    )
    parser.add_argument("input_obj", type=str, help="Path to the input OBJ file")
    parser.add_argument(
        "--output",
        type=str,
        default="obj_renderer.glsl",
        help="Path to the output GLSL file",
    )
    args = parser.parse_args()

    with open(args.input_obj, "r") as f:
        verts, faces = parse_obj(f.read())
        vert_data = pack_vertices(verts)
        strip = build_triangle_strip(faces)

        print(
            f"Parsed {len(verts)} vertices and {len(faces)} faces from {args.input_obj}"
        )

        header = (
            f"const int numIdx = {len(strip)};\n"
            + format_uvec4_array(vert_data, "vertices")
            + format_uvec4_array(strip, "idx")
        )
        full_shader = header + glsl_code_template
        SysPath(args.output).write_text(full_shader)

    print(
        f"Shader with {len(verts)} vertices and {len(faces)} faces written to {args.output}"
    )
