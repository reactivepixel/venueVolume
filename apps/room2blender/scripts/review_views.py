"""Shared, fixed isometric review cameras and reproducible render settings."""
import math
from pathlib import Path
import shutil

import bpy
from mathutils import Vector

WALL_NAMES = {side: 'Review wall / ' + side for side in ('front', 'rear', 'left', 'right')}
CORNERS = [('front-left', -1, 1, ('front', 'left')),
           ('front-right', 1, 1, ('front', 'right')),
           ('rear-right', 1, -1, ('rear', 'right')),
           ('rear-left', -1, -1, ('rear', 'left'))]


def configure(scene, width=1440, samples=32, cpu=True):
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = samples
    scene.cycles.seed = 0
    scene.cycles.use_animated_seed = False
    scene.cycles.use_adaptive_sampling = False
    scene.cycles.use_denoising = True
    scene.cycles.device = 'CPU'
    if not cpu:
        prefs = bpy.context.preferences.addons['cycles'].preferences
        prefs.compute_device_type = 'CUDA'
        prefs.get_devices()
        if not any(d.type == 'CUDA' for d in prefs.devices):
            raise RuntimeError('CUDA requested but unavailable; use --device cpu')
        for device in prefs.devices:
            device.use = device.type == 'CUDA'
        scene.cycles.device = 'GPU'
    scene.render.resolution_x = width
    scene.render.resolution_y = width * 3 // 4
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.view_settings.view_transform = 'AgX'
    scene.render.film_transparent = False


def make_review_scenes(scene, dimensions, views, ceiling, wall_objects):
    """Sides use output coordinates: front=+Y, rear=-Y, left=-X, right=+X."""
    w, d, h = dimensions
    walls = {}
    for side, name in WALL_NAMES.items():
        col = bpy.data.collections.new(name)
        scene.collection.children.link(col)
        walls[side] = col
        for obj in wall_objects.get(side, []):
            for old in list(obj.users_collection):
                old.objects.unlink(obj)
            col.objects.link(obj)
    center = Vector((w / 2, d / 2, h / 2))
    corners = [Vector((x, y, z)) for x in (-0.25, w+0.25)
               for y in (-0.25, d+0.25) for z in (-0.2, h+0.15)]
    scale = 0
    variants = []
    for index, (key, sx, sy, removed) in enumerate(CORNERS, 2):
        data = bpy.data.cameras.new('Isometric / ' + key)
        cam = bpy.data.objects.new(data.name, data)
        views.objects.link(cam)
        # Equal XYZ displacement gives true isometry (35.264 degree elevation).
        cam.location = center + Vector((sx, sy, 1)) * max(w, d, h) * 2
        cam.rotation_euler = (center-cam.location).to_track_quat('-Z', 'Y').to_euler()
        data.type = 'ORTHO'
        data.clip_end = 500
        inverse = cam.rotation_euler.to_matrix().transposed()
        projected = [inverse @ (p-center) for p in corners]
        scale = max(scale, max(p.x for p in projected)-min(p.x for p in projected),
                    (max(p.y for p in projected)-min(p.y for p in projected))*4/3)
        new = scene.copy()
        new.name = f'{index:02d} | CUTAWAY - {key}'
        new.use_fake_user = True
        new.camera = cam
        new['review_key'] = 'cutaway-' + key
        new['removed_walls'] = ','.join(removed)
        for col in [ceiling, *(walls[side] for side in removed)]:
            new.view_layers[0].layer_collection.children[col.name].exclude = True
        variants.append(new)
    for variant in variants:
        variant.camera.data.ortho_scale = scale * 1.1
    data = bpy.data.cameras.new('Floor plan')
    cam = bpy.data.objects.new(data.name, data)
    views.objects.link(cam)
    cam.location = (w/2, d/2, h+20)
    cam.rotation_euler = (0, 0, 0)
    data.type = 'ORTHO'
    data.ortho_scale = max(w+0.5, (d+0.5)*4/3)*1.1
    data.clip_end = 500
    plan = scene.copy()
    plan.name = '06 | PLAN - estimated dimensions'
    plan.use_fake_user = True
    plan.camera = cam
    plan['review_key'] = 'floor-plan'
    plan.view_layers[0].layer_collection.children[ceiling.name].exclude = True
    scene['review_key'] = 'interior'
    return variants + [plan]


def render_all(project, blend_path):
    out = Path(project) / 'output'
    main = bpy.data.scenes['01 | ROOM - walk and place assets']
    for scene in sorted(bpy.data.scenes, key=lambda s: s.name):
        key = scene.get('review_key')
        if key:
            bpy.context.window.scene = scene
            scene.render.filepath = str(out / (key + '.png'))
            bpy.ops.render.render(write_still=True)
    # Compatibility with the original prototype preview link.
    shutil.copyfile(out / 'cutaway-rear-left.png', out / 'cutaway.png')
    bpy.context.window.scene = main
    if 'Occlusion check / cube behind pier' in bpy.data.objects:
        original = main.camera
        blocker = bpy.data.objects['west-wall-projection']
        try:
            main.camera = bpy.data.objects['Occlusion check / cube behind pier']
            for hidden, filename in [(False, 'occlusion.png'), (True, 'occlusion-reveal.png')]:
                blocker.hide_render = hidden
                main.render.filepath = str(out / filename)
                bpy.ops.render.render(write_still=True)
        finally:
            blocker.hide_render = False
            main.camera = original
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path), compress=True)
