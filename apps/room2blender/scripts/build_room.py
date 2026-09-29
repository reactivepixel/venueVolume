"""Run with Blender 4.5+: blender -b --python scripts/build_room.py -- [--no-render]."""
import argparse
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
SPEC = json.loads((ROOT / "room_spec.json").read_text())
OUT = ROOT / "output"
OUT.mkdir(exist_ok=True)
parser = argparse.ArgumentParser()
parser.add_argument("--no-render", action="store_true")
parser.add_argument("--cpu", action="store_true", help="Render on CPU when GPU memory is busy")
args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
if not args.no_render:
    for name in ("interior.png", "cutaway.png", "floor-plan.png", "occlusion.png", "occlusion-reveal.png", "validation.json"):
        (OUT / name).unlink(missing_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.name = "01 | ROOM - walk and place assets"
scene.unit_settings.system = "METRIC"
scene.unit_settings.length_unit = "METERS"
scene.unit_settings.scale_length = 1
scene["scale_status"] = SPEC["scale_status"]
scene["source"] = "IMG_3153.MOV / photographic reference modeling, not photogrammetry"


def collection(name):
    c = bpy.data.collections.new(name)
    scene.collection.children.link(c)
    return c


shell = collection("01 Architecture")
ceiling = collection("02 Ceiling - hide for editing")
furniture = collection("03 Furniture - estimated layout")
equipment = collection("04 Observed equipment - simplified")
proxies = collection("05 COLLISION proxies - hidden")
tests = collection("06 TEST ASSETS - synthetic")
views = collection("07 Cameras and lighting")
refs = collection("08 Packed reference images - hidden")
proxies.hide_render = True
refs.hide_render = True


def mat(name, color, roughness=0.65, metal=0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metal
    return m


green = mat("Paint / sage green", (0.43, 0.51, 0.36))
cream = mat("Paint / warm ivory", (0.66, 0.61, 0.46))
white = mat("Whiteboard / warm white", (0.86, 0.85, 0.75), 0.3)
tile = mat("Acoustic ceiling / off white", (0.68, 0.68, 0.63))
dark = mat("Rubber and black equipment", (0.022, 0.028, 0.03), 0.8)
chairmat = mat("Chair / charcoal", (0.065, 0.073, 0.082), 0.72)
metal = mat("Frames / brushed metal", (0.4, 0.45, 0.47), 0.4, 0.6)
wood = mat("Desk / pale maple", (0.6, 0.39, 0.17), 0.55)
deskmat = mat("Table / light laminate", (0.73, 0.71, 0.64), 0.45)
glazing = mat("Glazing placeholder / opaque blue gray", (0.32, 0.46, 0.50), 0.28)
orange = mat("TEST / amber", (0.95, 0.24, 0.035), 0.33)
cyan = mat("TEST / cyan", (0.02, 0.63, 0.8), 0.32)
red = mat("Safety equipment / red", (0.55, 0.025, 0.025))
carpet = mat("Carpet / procedural gray weave", (0.18, 0.17, 0.16), 0.95)
nodes = carpet.node_tree.nodes
noise = nodes.new("ShaderNodeTexNoise")
noise.inputs["Scale"].default_value = 320
ramp = nodes.new("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].color = (0.09, 0.08, 0.075, 1)
ramp.color_ramp.elements[1].color = (0.28, 0.27, 0.25, 1)
carpet.node_tree.links.new(noise.outputs["Fac"], ramp.inputs[0])
carpet.node_tree.links.new(ramp.outputs[0], nodes.get("Principled BSDF").inputs["Base Color"])


def move_to(obj, col):
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    col.objects.link(obj)


def to_world(pos):
    # Specification Y is distance from the teaching wall. Final Blender Y points
    # toward that wall, keeping the windows on the viewer's right, as in the movie.
    return Vector((pos[0], D - pos[1], pos[2]))


def box(name, pos, size, material, col=shell, bevel=0, collision=False, evidence="estimated from movie references"):
    if min(size) <= 0:
        raise ValueError(f"Nonpositive dimensions for {name}: {size}")
    bpy.ops.mesh.primitive_cube_add(size=1, location=to_world(pos))
    o = bpy.context.object
    o.name = name
    o.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    move_to(o, col)
    o.data.materials.append(material)
    o["stable_id"] = name
    o["dimension_status"] = "estimated / unmeasured"
    o["evidence"] = evidence
    if bevel:
        mod = o.modifiers.new("Soft edges", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        o.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    if collision:
        p = bpy.data.objects.new("COL_" + name, o.data.copy())
        proxies.objects.link(p)
        p.location = o.location.copy()
        p.display_type = "WIRE"
        p.hide_render = True
        p.hide_set(True)
        p["source_object"] = name
        p["usage"] = "static surface proxy; application must attach its own physics components"
        o["collision_proxy"] = p.name
    return o


def cyl(name, pos, radius, depth, material, col=equipment, direction=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=radius, depth=depth, location=to_world(pos))
    o = bpy.context.object
    o.name = name
    move_to(o, col)
    o.data.materials.append(material)
    if direction:
        o.rotation_euler = Vector((direction[0], -direction[1], direction[2])).to_track_quat("Z", "Y").to_euler()
    return o


W, D, H, T = (SPEC["room"][key] for key in ("width", "depth", "height", "wall_thickness"))
box("floor", (W / 2, D / 2, -0.09), (W + 2*T, D + 2*T, 0.18), carpet, collision=True)
box("wall-back", (W / 2, D + T / 2, H / 2), (W, T, H), cream, collision=True)
door = SPEC["front_door"]
a, b, dh = door["x"], door["x"] + door["width"], door["height"]
for name, x0, x1 in (("left", 0, a), ("right", b, W)):
    box("wall-front-"+name, ((x0+x1)/2, -T/2, H/2), (x1-x0, T, H), green, collision=True)
box("wall-front-header", ((a+b)/2, -T/2, (H+dh)/2), (b-a, T, H-dh), green, collision=True)
box("door-front-closed", ((a+b)/2, 0, dh/2), (b-a-0.04, 0.055, dh), green, bevel=0.006, collision=True)
box("door-front-handle", (b-0.15, 0.045, 1.0), (0.14, 0.035, 0.035), metal)

# Window wall consists of solid segments around genuine apertures.
cursor = 0
for win in SPEC["windows"]:
    start, end = win["y_start"], win["y_start"] + win["width"]
    sill, top = win["sill"], win["sill"] + win["height"]
    if start > cursor:
        box(win["id"]+"-pier", (W+T/2, (cursor+start)/2, H/2), (T, start-cursor, H), green, collision=True)
    for label, z0, z1 in (("below", 0, sill), ("above", top, H)):
        box(win["id"]+"-"+label, (W+T/2, (start+end)/2, (z0+z1)/2), (T, end-start, z1-z0), green, collision=True)
    box(win["id"]+"-blind", (W+0.02, (start+end)/2, (sill+top)/2), (0.025, end-start, top-sill), white, collision=True)
    for z in (sill, top):
        box(win["id"]+f"-frame-{z}", (W-0.02, (start+end)/2, z), (0.08, end-start+0.08, 0.04), white)
    for i in range(win["panes"]+1):
        box(win["id"]+f"-mullion-{i}", (W-0.03, start+i*(end-start)/win["panes"], (sill+top)/2), (0.065, 0.04, top-sill), white)
    for i in range(1, 27):
        z = sill+(top-sill)*i/27
        box(win["id"]+f"-blind-slat-{i}", (W-0.004, (start+end)/2, z), (0.022, end-start, 0.009), tile)
    cursor = end
if cursor < D:
    box("window-wall-end", (W+T/2, (cursor+D)/2, H/2), (T, D-cursor, H), green, collision=True)
box("window-front-dark-panel", (W-0.10, 1.23, 2.05), (0.045, 1.14, 0.95), dark)

entry = SPEC["entrance"]
e0, e1 = entry["y_start"], entry["y_start"]+entry["width"]
box("wall-west-front-post", (-T/2, e0/2, H/2), (T, e0, H), cream, collision=True)
box("wall-west-main", (-T/2, (e1+D)/2, H/2), (T, D-e1, H), cream, collision=True)
box("entrance-header", (-T/2, (e0+e1)/2, (entry["height"]+H)/2), (T, e1-e0, H-entry["height"]), cream, collision=True)
box("entrance-transom", (0, (e0+e1)/2, (entry["door_height"]+entry["height"])/2), (0.045, e1-e0, entry["height"]-entry["door_height"]), glazing, collision=True)
# Door is near the front wall; sidelight is farther toward the rear.
doors_end = e1-entry["sidelight_width"]
for i in range(2):
    lo, hi = e0+i*(doors_end-e0)/2, e0+(i+1)*(doors_end-e0)/2
    box(f"entrance-leaf-{i}", (0, (lo+hi)/2, entry["door_height"]/2), (0.06, hi-lo-0.025, entry["door_height"]), wood, collision=True)
    box(f"entrance-vision-panel-{i}", (0.036, (lo+hi)/2, 1.1), (0.012, 0.30, 1.56), glazing)
    box(f"entrance-handle-{i}", (0.075, (lo+hi)/2+0.24, 1.05), (0.055, 0.035, 0.32), metal)
box("entrance-sidelight-sill", (0, (doors_end+e1)/2, 0.24), (0.075, e1-doors_end, 0.48), cream, collision=True)
box("entrance-sidelight", (0, (doors_end+e1)/2, 1.28), (0.04, e1-doors_end, 1.6), glazing, collision=True)
for y in (e0, (e0+doors_end)/2, doors_end, e1):
    box(f"entrance-mullion-{y}", (0.04, y, entry["height"]/2), (0.08, 0.035, entry["height"]), dark)
for z in (entry["height"], entry["door_height"]):
    box(f"entrance-crossbar-{z}", (0.04, (e0+e1)/2, z), (0.08, e1-e0, 0.035), dark)
rear_door = SPEC["rear_side_door"]
box("rear-side-door-placeholder", (0.025, rear_door["y_start"]+rear_door["width"]/2, rear_door["height"]/2), (0.03, rear_door["width"], rear_door["height"]), white)
box("rear-door-handle", (0.08, rear_door["y_start"]+0.15, 1.0), (0.08, 0.13, 0.025), metal)
pier = SPEC["west_pier"]
box("west-wall-projection", (pier["x_depth"]/2, pier["y_start"]+pier["y_length"]/2, H/2), (pier["x_depth"], pier["y_length"], H), cream, collision=True)
for name, pos, size in (
    ("east", (W-0.015, D/2, 0.055), (0.03, D, 0.11)),
    ("back", (W/2, D-0.015, 0.055), (W, 0.03, 0.11)),
    ("west", (0.015, (e1+D)/2, 0.055), (0.03, D-e1, 0.11)),
    ("front", ((b+W)/2, 0.015, 0.055), (W-b, 0.03, 0.11))):
    box("skirting-"+name, pos, size, dark)

board = SPEC["whiteboard"]
bx, bz = board["x_start"]+board["width"]/2, board["bottom"]+board["height"]/2
box("whiteboard-frame", (bx, 0.036, bz), (board["width"]+0.06, 0.06, board["height"]+0.06), metal)
box("whiteboard", (bx, 0.076, bz), (board["width"], 0.025, board["height"]), white)
box("whiteboard-tray", (bx, 0.12, board["bottom"]), (board["width"], 0.12, 0.018), metal)


def chair(name, x, y):
    box(name+"-seat", (x, y, 0.46), (0.45, 0.43, 0.075), chairmat, furniture, 0.04, True)
    box(name+"-back", (x, y+0.20, 0.74), (0.44, 0.07, 0.40), chairmat, furniture, 0.055, True)
    cyl(name+"-post", (x, y, 0.245), 0.035, 0.40, metal, furniture)
    for j in range(5):
        angle = j*2*math.pi/5
        arm = box(name+f"-base-{j}", (x+0.15*math.cos(angle), y+0.15*math.sin(angle), 0.10), (0.31, 0.037, 0.04), dark, furniture)
        arm.rotation_euler.z = -angle
        cyl(name+f"-caster-{j}", (x+0.28*math.cos(angle), y+0.28*math.sin(angle), 0.055), 0.035, 0.045, dark, furniture, (1, 0, 0))


ts = SPEC["tables"]
for row, y in enumerate(ts["y_centers"], 1):
    for column, x in enumerate(ts["x_centers"], 1):
        name = f"table-r{row}-c{column}"
        top = box(name+"-top", (x, y, ts["height"]-0.022), (ts["width"], ts["depth"], 0.044), deskmat, furniture, 0.012, True)
        top["placement_surface"] = True
        top["surface_z_m"] = ts["height"]
        box(name+"-modesty", (x, y-0.18, 0.48), (ts["width"]-0.10, 0.025, 0.35), dark, furniture)
        for side in (-1, 1):
            lx = x+side*(ts["width"]/2-0.14)
            box(name+f"-leg-{side}", (lx, y, 0.365), (0.055, 0.12, 0.69), metal, furniture, collision=True)
            box(name+f"-foot-{side}", (lx, y, 0.06), (0.09, 0.64, 0.065), metal, furniture, 0.025)
            box(name+f"-power-{side}", (x+side*0.44, y, ts["height"]+0.007), (0.16, 0.075, 0.014), metal, furniture)
            chair(name+f"-chair-{side}", x+side*0.44, y+0.61)

# Teaching area: wood desk, cabinet, monitor and the two speakers visible in footage.
desk = SPEC["instructor_desk"]
dx, dy, dz = desk["center"]
box("instructor-desk-top", (dx, dy, dz-0.025), (desk["width"], desk["depth"], 0.05), wood, furniture, 0.012, True)
for offset in (-0.67, 0.67):
    box(f"instructor-desk-leg-{offset}", (dx+offset, dy, dz/2), (0.045, 0.60, dz), metal, furniture, collision=True)
box("instructor-desk-screen", (dx, dy+0.27, 0.91), (1.57, 0.025, 0.42), metal, furniture)
chair("instructor-chair", dx, dy-0.55)
cab = box("AV-cabinet", (W-0.34, 1.36, 0.46), (0.58, 2.0, 0.92), wood, equipment, collision=True)
box("AV-counter", (W-0.35, 1.36, 0.945), (0.68, 2.06, 0.05), wood, equipment)
for y in (0.85, 1.55):
    box(f"AV-monitor-{y}", (W-0.54, y, 1.25), (0.055, 0.49, 0.30), dark, equipment, 0.012)
    box(f"AV-monitor-screen-{y}", (W-0.573, y, 1.25), (0.008, 0.44, 0.25), glazing, equipment)
    cyl(f"AV-monitor-stand-{y}", (W-0.52, y, 1.035), 0.025, 0.17, metal)
for name, x, y in (("left", 2.17, 0.31), ("right", W-0.62, 0.32)):
    box("speaker-"+name, (x, y, 1.15), (0.30, 0.26, 0.47), dark, equipment, 0.012, True)
    box("speaker-stand-"+name, (x, y, 0.45), (0.08, 0.08, 0.90), dark, equipment)
    box("speaker-base-"+name, (x, y, 0.025), (0.35, 0.32, 0.05), dark, equipment)
    for z, r in ((1.06, 0.085), (1.27, 0.045)):
        cyl(f"speaker-driver-{name}-{z}", (x, y+0.14, z), r, 0.018, chairmat, direction=(0, 1, 0))
box("extinguisher", (0.17, 0.30, 0.80), (0.13, 0.13, 0.36), red, equipment, 0.03)
box("rear-small-cabinet", (W-0.57, D-0.32, 0.44), (0.8, 0.55, 0.88), cream, furniture)

# Ceiling is a separate collection for an unobstructed editing / dollhouse view.
box("ceiling-slab", (W/2, D/2, H+0.05), (W, D, 0.10), tile, ceiling, collision=True)
for x in range(1, math.ceil(W/0.60)):
    box(f"ceiling-grid-x{x}", (x*0.60, D/2, H-0.012), (0.016, D, 0.024), white, ceiling)
for y in range(1, math.ceil(D/0.60)):
    box(f"ceiling-grid-y{y}", (W/2, y*0.60, H-0.012), (W, 0.016, 0.024), white, ceiling)
lampmat = mat("Ceiling diffuser", (0.96, 0.87, 0.69))
bsdf = lampmat.node_tree.nodes.get("Principled BSDF")
bsdf.inputs["Emission Color"].default_value = (1.0, 0.85, 0.62, 1)
bsdf.inputs["Emission Strength"].default_value = 2.5


def area(name, pos, energy, size, target=None, color=(1, 0.91, 0.78)):
    data = bpy.data.lights.new(name, "AREA")
    data.energy, data.shape, data.size, data.color = energy, "DISK", size, color
    obj = bpy.data.objects.new(name, data)
    views.objects.link(obj)
    obj.location = to_world(pos)
    if target is not None:
        obj.rotation_euler = (to_world(target)-obj.location).to_track_quat("-Z", "Y").to_euler()
    return obj


for i, (x, y) in enumerate(( (x,y) for x in (1.5, 5.7) for y in (1.5, 3.9, 6.3) )):
    box(f"ceiling-light-{i}", (x, y, H-0.023), (0.56, 0.56, 0.036), lampmat, ceiling)
    area(f"light-{i}", (x, y, H-0.06), 90, 0.54)
for i, (x, y) in enumerate(((3.0, 2.1), (3.0, 5.7), (6.3, 4.5))):
    box(f"ceiling-vent-{i}", (x, y, H-0.025), (0.53, 0.53, 0.035), metal, ceiling)
    box(f"ceiling-vent-inset-{i}", (x, y, H-0.045), (0.43, 0.43, 0.035), tile, ceiling)
box("projector", (4.0, 3.4, H-0.27), (0.44, 0.34, 0.16), white, ceiling, 0.015)
cyl("projector-mount", (4.0, 3.4, H-0.105), 0.03, 0.20, metal, ceiling)
cyl("projector-lens", (3.90, 3.21, H-0.27), 0.045, 0.06, dark, ceiling, (0,-1,0))
area("window-light-front", (W-0.12, 1.4, 2.05), 160, 1.5, (W/2, 2.5, 1), (0.78, 0.86, 1.0))
area("window-light-back", (W-0.12, 6.0, 2.05), 180, 2.2, (W/2, 5.8, 1), (0.78, 0.86, 1.0))

# Synthetic fixture rests precisely on the instructor desk; movable independent object.
fixture_parts = []
fixture_parts.append(box("TEST-fixture-base", (dx-0.38, dy, dz+0.055), (0.25, 0.24, 0.11), dark, tests, 0.02))
for side in (-1, 1):
    fixture_parts.append(box(f"TEST-fixture-yoke-{side}", (dx-0.38+side*0.11, dy, dz+0.27), (0.04, 0.07, 0.36), orange, tests, 0.008))
fixture_parts.append(cyl("TEST-fixture-head", (dx-0.38, dy, dz+0.41), 0.105, 0.18, dark, tests, (0,-1,0)))
fixture_parts.append(cyl("TEST-fixture-lens", (dx-0.38, dy-0.095, dz+0.41), 0.085, 0.015, cyan, tests, (0,-1,0)))
bpy.ops.object.select_all(action="DESELECT")
for obj in fixture_parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active = fixture_parts[0]
bpy.ops.object.convert(target="MESH")
bpy.ops.object.join()
fixture = bpy.context.object
fixture.name = "TEST_fixture_on_instructor_desk"
scene.cursor.location = to_world((dx-0.38, dy, dz))
bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
fixture["placement_surface"] = "instructor-desk-top"
fixture["synthetic"] = True
probe = box("TEST_occlusion_cube", (0.30, pier["y_start"]+pier["y_length"]+0.32, 0.3), (0.40, 0.40, 0.60), cyan, tests, 0.025)
probe["synthetic"] = True
probe["purpose"] = "Hidden behind west wall projection from Occlusion camera; visible in cutaway"
scene.cursor.location = to_world((SPEC["spawn"]["eye"][0], SPEC["spawn"]["eye"][1], 0))


def camera(name, pos, target, lens=23, ortho=None):
    data = bpy.data.cameras.new(name)
    obj = bpy.data.objects.new(name, data)
    views.objects.link(obj)
    obj.location = to_world(pos)
    obj.rotation_euler = (to_world(target)-obj.location).to_track_quat("-Z", "Y").to_euler()
    data.lens = lens
    data.clip_start, data.clip_end = 0.03, 150
    if ortho:
        data.type, data.ortho_scale = "ORTHO", ortho
    return obj


walk = camera("Walk start / back aisle", SPEC["spawn"]["eye"], SPEC["spawn"]["look_at"], 21)
camera("Front toward rear", (3.0, 0.52, 1.68), (3.7, 7.2, 1.2), 20)
occlusion_camera = camera("Occlusion check / cube behind pier", (0.30, 3.20, 1.25), (0.30, pier["y_start"]+pier["y_length"]+0.32, 0.3), 30)
cut_camera = camera("Cutaway overview", (-8.5, 18.5, 13), (3.6, 3.9, 0.55), ortho=12.7)
plan_camera = camera("Floor plan", (W/2, D/2, 18), (W/2, D/2, 0), ortho=12.0)
scene.camera = walk

# Pack references into the .blend so it remains useful away from the repository.
manifest = json.loads((ROOT / "references/manifest.json").read_text())
for ref in manifest["references"]:
    im = bpy.data.images.load(str(ROOT / "references" / ref["file"]))
    im.pack()
    im.use_fake_user = True
for filename in ("room_spec.json", "references/manifest.json", "README.md"):
    path = ROOT / filename
    if path.exists():
        text = bpy.data.texts.new(path.name)
        text.write(path.read_text())

world = bpy.data.worlds.new("Soft ambient")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.24, 0.28, 0.35, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.25
scene.world = world
scene.render.engine = "CYCLES"
scene.cycles.samples = 32
scene.cycles.use_denoising = True
try:
    if args.cpu:
        raise RuntimeError("CPU requested")
    preferences = bpy.context.preferences.addons["cycles"].preferences
    preferences.compute_device_type = "CUDA"
    preferences.get_devices()
    enabled = False
    for device in preferences.devices:
        device.use = device.type == "CUDA"
        enabled |= device.use
    if enabled:
        scene.cycles.device = "GPU"
except Exception as error:
    print("Using CPU for rendering:", error)
scene.render.resolution_x, scene.render.resolution_y = 1440, 1080
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.view_settings.view_transform = "AgX"

# Copy scenes, but share editable geometry. Visibility is per-scene view layer.
def scene_variant(name, cam, excluded_collections=(), hidden_objects=()):
    new = scene.copy()
    new.name = name
    new.use_fake_user = True
    new.camera = cam
    for name in excluded_collections:
        new.view_layers[0].layer_collection.children[name].exclude = True
    for obj in hidden_objects:
        obj.hide_set(True, view_layer=new.view_layers[0])
    return new


# For render cutaways use separate collection exclusions, never delete room geometry.
cutwalls = collection("09 Cutaway removable walls")
for obj in list(shell.objects):
    if (obj.name.startswith(("wall-back", "wall-west", "entrance-", "rear-side-door", "rear-door", "skirting-back", "skirting-west"))):
        move_to(obj, cutwalls)
cut = scene_variant("02 | CUTAWAY - layout overview", cut_camera, (ceiling.name, cutwalls.name))
plan = scene_variant("03 | PLAN - estimated dimensions", plan_camera, (ceiling.name,))

for s in bpy.data.scenes:
    s["scale_status"] = SPEC["scale_status"]
    s.view_layers[0].layer_collection.children[proxies.name].exclude = True
    s.view_layers[0].layer_collection.children[refs.name].exclude = True
for screen in bpy.data.screens:
    for area_ui in screen.areas:
        if area_ui.type == "VIEW_3D":
            area_ui.spaces.active.region_3d.view_perspective = "CAMERA"
            area_ui.spaces.active.clip_end = 150
            area_ui.spaces.active.shading.type = "MATERIAL"
bpy.ops.object.select_all(action="DESELECT")
fixture.select_set(True)
bpy.context.view_layer.objects.active = fixture
layout = {"room_id": SPEC["id"], "units": "meters", "up_axis": "Z", "scale_status": SPEC["scale_status"],
          "origin": "rear-left floor corner; +X toward windows, +Y toward teaching wall",
          "spawn": {k: list(to_world(v)) for k, v in SPEC["spawn"].items()}, "assets": [{"id": o.name, "location": list(o.location),
          "rotation_euler": list(o.rotation_euler), "scale": list(o.scale)} for o in (fixture, probe)],
          "placement_surfaces": [o.name for o in furniture.objects if o.get("placement_surface")],
          "conversion_to_y_up": "For future RealityKit ingestion map (x, y, z) to (x, z, -y). No native app integration in this prototype."}
(OUT / "placement.json").write_text(json.dumps(layout, indent=2)+"\n")
bpy.context.window.scene = scene
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "classroom.blend"), compress=True)
if not args.no_render:
    for s, filename in ((scene, "interior.png"), (cut, "cutaway.png"), (plan, "floor-plan.png")):
        bpy.context.window.scene = s
        s.render.filepath = str(OUT / filename)
        bpy.ops.render.render(write_still=True)
    bpy.context.window.scene = scene
    scene.camera = occlusion_camera
    scene.render.filepath = str(OUT / "occlusion.png")
    bpy.ops.render.render(write_still=True)
    # Same camera with only the architectural blocker hidden proves the probe position.
    scene.view_layers[0].objects.active = probe
    blocker = bpy.data.objects["west-wall-projection"]
    blocker.hide_render = True
    scene.render.filepath = str(OUT / "occlusion-reveal.png")
    bpy.ops.render.render(write_still=True)
    blocker.hide_render = False
    scene.camera = walk
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "classroom.blend"), compress=True)
print("Saved", OUT / "classroom.blend")
