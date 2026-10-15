"""Generic reviewed box geometry; no camera/geometry inference from images."""
import argparse
import json
from pathlib import Path
import sys
import bpy
from mathutils import Vector
sys.path.insert(0, str(Path(__file__).resolve().parent))
from review_views import configure, make_review_scenes, render_all

p = argparse.ArgumentParser()
p.add_argument('--project', type=Path, required=True)
p.add_argument('--blend-name', default='room.blend')
p.add_argument('--samples', type=int, default=32)
p.add_argument('--width', type=int, default=1440)
p.add_argument('--cpu', action='store_true')
p.add_argument('--no-render', action='store_true')
a = p.parse_args(sys.argv[sys.argv.index('--')+1:])
root = a.project.resolve()
spec = json.loads((root/'room_spec.json').read_text())
out = root/'output'
out.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.name = '01 | ROOM - walk and place assets'
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
scene['scale_status'] = spec['scale_status']
scene['recipe'] = spec['recipe']


def collection(name):
    col = bpy.data.collections.new(name)
    scene.collection.children.link(col)
    return col


geometry = collection('01 Reviewed geometry')
ceiling = collection('02 Ceiling - hide for editing')
proxies = collection('05 COLLISION proxies - hidden')
views = collection('07 Cameras and lighting')
materials = {}
for name, rgb in spec['materials'].items():
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*rgb, 1)
    mat.use_nodes = True
    mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (*rgb, 1)
    mat.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value = 0.7
    materials[name] = mat
walls = {side: [] for side in ('front', 'rear', 'left', 'right')}
for item in spec['objects']:
    bpy.ops.mesh.primitive_cube_add(size=1, location=item['position'])
    obj = bpy.context.object
    obj.name = item['id']
    obj.dimensions = item['size']
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for col in list(obj.users_collection):
        col.objects.unlink(obj)
    (ceiling if item.get('cutaway_wall') == 'ceiling' else geometry).objects.link(obj)
    obj.data.materials.append(materials[item['material']])
    obj['evidence'] = item['evidence']
    obj['stable_id'] = item['id']
    obj['placement_surface'] = bool(item.get('placement_surface'))
    if item.get('cutaway_wall') in walls:
        walls[item['cutaway_wall']].append(obj)
    if item.get('collision'):
        proxy = bpy.data.objects.new('COL_'+obj.name, obj.data.copy())
        proxies.objects.link(proxy)
        proxy.location = obj.location.copy()
        proxy.hide_render = True
        proxy.display_type = 'WIRE'
        proxy['source_object'] = obj.name
        obj['collision_proxy'] = proxy.name
proxies.hide_render = True
scene.view_layers[0].layer_collection.children[proxies.name].exclude = True
cam = bpy.data.objects.new('Walk start', bpy.data.cameras.new('Walk start'))
views.objects.link(cam)
cam.location = spec['spawn']['eye']
cam.rotation_euler = (Vector(spec['spawn']['look_at'])-cam.location).to_track_quat('-Z', 'Y').to_euler()
cam.data.lens = 21
cam.data.clip_start = 0.03
scene.camera = cam
w, d, h = (spec['room'][key] for key in ('width', 'depth', 'height'))
world = bpy.data.worlds.new('Neutral review lighting')
world.use_nodes = True
world.node_tree.nodes['Background'].inputs[0].default_value = (0.3, 0.33, 0.4, 1)
world.node_tree.nodes['Background'].inputs[1].default_value = 0.4
scene.world = world
for i, (x, y) in enumerate(((w*.25,d*.25), (w*.75,d*.25), (w*.25,d*.75), (w*.75,d*.75))):
    data = bpy.data.lights.new('Review light '+str(i), 'AREA')
    data.energy, data.size = 140, max(w, d)/3
    light = bpy.data.objects.new(data.name, data)
    views.objects.link(light)
    light.location = (x, y, h-.08)
configure(scene, a.width, a.samples, a.cpu)
make_review_scenes(scene, (w,d,h), views, ceiling, walls)
manifest = json.loads((root/'references/manifest.json').read_text())
for ref in manifest['references']:
    im = bpy.data.images.load(str(root/'references'/ref['file']))
    im.pack()
    im.use_fake_user = True
for path in (root/'room_spec.json', root/'references/manifest.json'):
    text = bpy.data.texts.new(path.name)
    text.write(path.read_text())
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == 'VIEW_3D':
            area.spaces.active.region_3d.view_perspective = 'CAMERA'
            area.spaces.active.shading.type = 'MATERIAL'
layout = {'room_id': spec['id'], 'units': 'meters', 'up_axis': 'Z', 'spawn': spec['spawn'],
          'scale_status': spec['scale_status'], 'assets': [],
          'placement_surfaces': [o['id'] for o in spec['objects'] if o.get('placement_surface')]}
(out/'placement.json').write_text(json.dumps(layout, indent=2)+'\n')
bpy.ops.wm.save_as_mainfile(filepath=str(out/a.blend_name), compress=True)
if not a.no_render:
    render_all(root, out/a.blend_name)
