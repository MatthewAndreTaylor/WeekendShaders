from pathlib import Path as SysPath


def parse_obj(text: str):
    verts = []
    faces = []

    for line in text.splitlines():
        if line.startswith("v "):
            _, x, y, z = line.split()
            verts.append((float(x), float(y), float(z)))

        elif line.startswith("f "):
            _, a, b, c = line.split()
            faces.append((int(a) - 1, int(b) - 1, int(c) - 1))

    return verts, faces


def pack_vertices(vertices):
    xs = [v[0] for v in vertices]
    ys = [v[1] for v in vertices]
    zs = [v[2] for v in vertices]
    min_v = (min(xs), min(ys), min(zs))
    max_v = (max(xs), max(ys), max(zs))
    center = (
        (min_v[0] + max_v[0]) * 0.5,
        (min_v[1] + max_v[1]) * 0.5,
        (min_v[2] + max_v[2]) * 0.5,
    )

    extent = max(max_v[0] - min_v[0], max_v[1] - min_v[1], max_v[2] - min_v[2]) * 0.5

    packed = []

    for x, y, z in vertices:
        x -= center[0]
        y -= center[1]
        z -= center[2]
        px = round(((x / extent) * 0.5 + 0.5) * 1023)
        py = round(((y / extent) * 0.5 + 0.5) * 1023)
        pz = round(((z / extent) * 0.5 + 0.5) * 1023)

        d = px | (py << 10) | (pz << 20)
        packed.append(d)

    return packed


def pack_faces(faces):
    packed = []
    for a, b, c in faces:
        d = a | (b << 9) | (c << 18)
        packed.append(d)
    return packed


glsl_code_template = """
// Unpacking logic
uint getIndex(int faceID, int vertexID)
{
    return (faces[faceID] >> (9 * vertexID)) & 511U;
}

vec3 getVertex(uint id)
{
    uint d = vertices[id];
    vec3 v = vec3(
        float(d & 1023U),
        float((d >> 10) & 1023U),
        float((d >> 20) & 1023U)
    ) / 1023.0;
    v = v * 2.0 - 1.0;
    return v;
}

const float PI = 3.14159;
const float PI2 = PI*2.0;

vec3 triIntersect(vec3 ro, vec3 rd, vec3 v0, vec3 v1, vec3 v2)
{
    vec3 v1v0 = v1 - v0;
    vec3 v2v0 = v2 - v0;
    vec3 rov0 = ro - v0;

    vec3 n = cross(v1v0, v2v0);
    vec3 q = cross(rov0, rd);

    float d = 1.0 / dot(rd, n);
    float u = d * dot(-q, v2v0);
    float v = d * dot(q, v1v0);
    float t = d * dot(-n, rov0);

    if (u < 0.0 || v < 0.0 || (u + v) > 1.0) t = -1.0;

    return vec3(t, u, v);
}

mat3 setCamera(vec3 ro)
{
    // Look at mesh center
    vec3 ta = vec3(0.0);
    vec3 f = normalize(ta - ro);
    vec3 r = normalize(cross(vec3(0.0, 1.0, 0.0), f));
    vec3 u = cross(f, r);
    return mat3(r, u, f);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec2 m = iMouse.xy / iResolution.xy;

    // default angle if mouse not pressed yet
    if (iMouse.x <= 0.0) m = vec2(0.5);
    float yaw = (m.x - 0.5) * PI2;
    float pitch = (m.y - 0.5) * PI;
    float camDist = 2.0;

    // orbit camera pos
    vec3 ro = vec3(
        camDist * sin(yaw) * cos(pitch),
        camDist * sin(pitch),
        camDist * cos(yaw) * cos(pitch)
    );

    mat3 cam = setCamera(ro);
    vec3 rd = normalize(cam * vec3(uv, 1.5));

    float minT = 1e10;
    vec3 normal = vec3(0.0);
    bool hit = false;

    for (int i = 0; i < numFaces; i++)
    {
        vec3 v0 = getVertex(getIndex(i, 0));
        vec3 v1 = getVertex(getIndex(i, 1));
        vec3 v2 = getVertex(getIndex(i, 2));

        vec3 h = triIntersect(ro, rd, v0, v1, v2);

        if (h.x > 0.0 && h.x < minT)
        {
            minT = h.x;
            normal = normalize(cross(v1 - v0, v2 - v0));
            hit = true;
        }
    }
    
    // bg
    vec3 col = vec3(1.0);

    if (hit)
    {
        vec3 hitPos = ro + rd * minT;
        normal = faceforward(normal, rd, normal);
        vec3 lightDir = normalize(vec3(1.0, 1.2, 0.8));
        float diff = max(dot(normal, lightDir), 0.0);
        float ambient = 0.3;
        float fill = max(dot(normal, normalize(vec3(-1.0, 0.5, -0.5))), 0.0) * 0.25;

        float lighting = ambient + diff + fill;

        vec3 baseColor = vec3(1.0, 0.5, 0.2);
        col = baseColor * lighting;
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
        obj_text = f.read()
        verts, faces = parse_obj(obj_text)
        vert_data = pack_vertices(verts)
        face_data = pack_faces(faces)

        print(
            f"Parsed {len(verts)} vertices and {len(faces)} faces from {args.input_obj}"
        )

        header = f"""const int numVertices = {len(vert_data)};const int numFaces = {len(face_data)};const uint vertices[numVertices] = uint[]({', '.join(str(v)+'U' for v in vert_data)});const uint faces[numFaces] = uint[]({', '.join(str(f)+'U' for f in face_data)});
        """
        full_shader = header + glsl_code_template
        SysPath(args.output).write_text(full_shader)

    print(
        f"Shader with {len(verts)} vertices and {len(faces)} faces written to {args.output}"
    )
