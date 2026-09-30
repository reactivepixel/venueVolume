"""Reopen output/classroom.blend in background Blender, then run this script."""
import json
import argparse
import hashlib
import sys
import math
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector
import numpy as np

parser = argparse.ArgumentParser()
parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parents[1])
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
ROOT = args.project.resolve()
sys.path.insert(0, str(Path(__file__).resolve().parent))
SPEC = json.loads((ROOT / 'room_spec.json').read_text())
scene = bpy.data.scenes["01 | ROOM - walk and place assets"]
bpy.context.window.scene = scene
checks = []


def check(name, condition, detail):
    checks.append({"check": name, "passed": bool(condition), "detail": detail})


check("meters", scene.unit_settings.system == "METRIC" and scene.unit_settings.scale_length == 1,
      "Blender units are meters; physical scale is still estimated")
check("review scenes", len(bpy.data.scenes) == 6, [s.name for s in bpy.data.scenes])
manifest = json.loads((ROOT / "references/manifest.json").read_text())
packed = [i for i in bpy.data.images if i.packed_file]
check("portable references", len(packed) == len(manifest["references"]), f"{len(packed)} images packed")
from review_views import CORNERS, WALL_NAMES
for key, sx, sy, sides in CORNERS:
    cut = next(s for s in bpy.data.scenes if s.get('review_key') == 'cutaway-'+key)
    direction = cut.camera.rotation_euler.to_matrix() @ Vector((0,0,-1))
    check('true isometry / '+key, max(abs(v) for v in direction)-min(abs(v) for v in direction) < 1e-5, list(direction))
    excluded = {side for side, name in WALL_NAMES.items() if cut.view_layers[0].layer_collection.children[name].exclude}
    check('cutaway wall selection / '+key, excluded == set(sides), sorted(excluded))

deps = bpy.context.evaluated_depsgraph_get()


def cast(origin, direction):
    result = scene.ray_cast(deps, Vector(origin), Vector(direction).normalized(), distance=100)
    return result[0], result[1], result[4].name if result[4] else None


hit, location, name = cast(scene.camera.location, (0, 0, -1))
check("walk start over clear floor", hit and name == "floor" and abs(location.z) < 1e-5, name)
if SPEC.get('recipe', 'classroom-v1') == 'classroom-v1':
    table = bpy.data.objects["table-r2-c2-top"]
    hit, location, name = cast(table.location + Vector((0.1, 0.1, 1)), (0, 0, -1))
    check("table accepts downward placement ray", hit and name == table.name and abs(location.z-SPEC["tables"]["height"]) < 1e-5,
          {"hit": name, "surface_height_m": location.z})
    fixture = bpy.data.objects["TEST_fixture_on_instructor_desk"]
    fixture_min = min((fixture.matrix_world @ v.co).z for v in fixture.data.vertices)
    check("fixture rests on instructor desk", abs(fixture_min - SPEC["instructor_desk"]["center"][2]) < 1e-5,
          {"fixture_base_m": fixture_min, "desk_surface_m": SPEC["instructor_desk"]["center"][2]})

    probe = bpy.data.objects["TEST_occlusion_cube"]
    cam = bpy.data.objects["Occlusion check / cube behind pier"]
    hit, location, name = cast(cam.location, probe.location-cam.location)
    check("wall projection occludes probe", hit and name == "west-wall-projection", name)
    hit, location, name = cast((3.6, 3.9, 1.7), (1, 0, 0))
    check("room wall blocks outward ray", hit and name.startswith("window"), name)


proxies = list(bpy.data.collections["05 COLLISION proxies - hidden"].objects)
bad = []
for obj in proxies:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    if not all(e.is_manifold for e in bm.edges):
        bad.append(obj.name)
    bm.free()
check("closed collision proxies", len(proxies) > 0 and not bad, {"count": len(proxies), "nonmanifold": bad})
check("proxies excluded from normal rendering", all(o.hide_render for o in proxies), len(proxies))
bad = [o.name for o in bpy.data.objects if not all(math.isfinite(v) for row in o.matrix_world for v in row)]
check("finite transforms", not bad, bad)
saved = json.loads((ROOT / "output/placement.json").read_text())
bad = [a["id"] for a in saved["assets"] if (bpy.data.objects[a["id"]].location-Vector(a["location"])).length > 1e-5]
check("saved asset positions survive reopening", not bad, bad)

if SPEC.get('recipe', 'classroom-v1') == 'classroom-v1':
    counts = {}
    for name in ("occlusion.png", "occlusion-reveal.png"):
        path = ROOT / "output" / name
        if path.exists():
            im = bpy.data.images.load(str(path), check_existing=False)
            pixels = np.asarray(im.pixels[:], dtype=np.float32).reshape(-1, 4)
            # Compare the synthetic cyan probe against otherwise neutral room materials.
            counts[name] = int(np.sum((pixels[:, 1] > pixels[:, 0] * 1.45) &
                                      (pixels[:, 2] > pixels[:, 0] * 1.45) & (pixels[:, 1] > 0.12)))
            bpy.data.images.remove(im)
    check("rendered depth occlusion", len(counts) == 2 and counts["occlusion.png"] < 100 and counts["occlusion-reveal.png"] > 200,
          counts)


triangles = 0
for o in bpy.data.objects:
    if o.type == "MESH" and not o.name.startswith("COL_"):
        o.data.calc_loop_triangles()
        triangles += len(o.data.loop_triangles)
geometry = []
for obj in sorted(bpy.data.objects, key=lambda o: o.name):
    if obj.type != 'MESH':
        continue
    evaluated = obj.evaluated_get(deps)
    mesh = evaluated.to_mesh()
    vertices = [[round(v, 6) for v in vertex.co] for vertex in mesh.vertices]
    faces = [list(face.vertices) for face in mesh.polygons]
    shape = hashlib.sha256(json.dumps([vertices, faces], separators=(',', ':')).encode()).hexdigest()
    geometry.append({'id': obj.name, 'mesh_sha256': shape,
                     'matrix': [[round(v, 6) for v in row] for row in obj.matrix_world]})
    evaluated.to_mesh_clear()
geometry_hash = hashlib.sha256(json.dumps(geometry, sort_keys=True).encode()).hexdigest()
(ROOT / 'output/geometry.json').write_text(json.dumps({'sha256': geometry_hash, 'objects': geometry}, indent=2)+'\n')
report = {"passed": all(c["passed"] for c in checks), "geometry_sha256": geometry_hash, "blender_version": bpy.app.version_string,
          "mesh_triangles_before_unapplied_modifiers": triangles,
          "dimension_accuracy": "unmeasured; not validated against a survey", "checks": checks}
(ROOT / "output/validation.json").write_text(json.dumps(report, indent=2)+"\n")
print(json.dumps(report, indent=2))
if not report["passed"]:
    raise RuntimeError("Room validation failed; see output/validation.json")
