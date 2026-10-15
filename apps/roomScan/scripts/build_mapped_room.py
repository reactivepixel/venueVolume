"""Run in Blender with the existing classroom.blend open; creates a separate room."""
from pathlib import Path
import json
import shutil
import sys
import bpy

APP = Path(__file__).resolve().parents[1]
PROJECT = APP/'mappedRoom'
OUT = PROJECT/'output'
OUT.mkdir(parents=True,exist_ok=True)
bpy.data.use_autopack = False
bpy.context.view_layer.update()
for image in list(bpy.data.images):
    reference = APP/'references'/Path(image.filepath).name
    if reference.is_file():
        # Packed references remember an obsolete source worktree. Replace their
        # datablocks with the tracked reference files without touching the source blend.
        name = image.name
        replacement = bpy.data.images.load(str(reference),check_existing=False)
        image.user_remap(replacement)
        bpy.data.images.remove(image)
        replacement.name = name
spec = json.loads((APP/'room_spec.json').read_text())
spec['id'] = 'mappedRoom'
spec['title'] = 'mappedRoom'
(PROJECT/'room_spec.json').write_text(json.dumps(spec,indent=2)+'\n')
shutil.copyfile(APP/'output/placement.json', OUT/'placement.json')
recipe = json.loads((PROJECT/'texture-provenance.json').read_text())
settings = {r['material']:r for r in recipe['textures']}
for name, recipe in settings.items():
    material = bpy.data.materials[name]
    tree = material.node_tree
    bsdf = tree.nodes.get('Principled BSDF')
    for link in list(bsdf.inputs['Base Color'].links): tree.links.remove(link)
    # A single opaque base-color sample. No baked illumination, AO, emission,
    # transparent layers, displacement or extra normal/roughness samples.
    bsdf.inputs['Emission Strength'].default_value = 0
    bsdf.inputs['Alpha'].default_value = 1
    image = bpy.data.images.load(str(PROJECT/'textures'/recipe['file']),check_existing=True)
    image.colorspace_settings.name = 'sRGB'
    tex = tree.nodes.new('ShaderNodeTexImage'); tex.image = image; tex.extension = 'REPEAT'
    uv = tree.nodes.new('ShaderNodeUVMap'); uv.uv_map = 'MappedUV'
    tree.links.new(uv.outputs['UV'],tex.inputs['Vector'])
    tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
# Explicit planar face UVs in room meters. Does not split/add/remove mesh faces.
for obj in bpy.data.objects:
    if obj.type != 'MESH' or obj.name.startswith(('COL_', 'TEST')): continue
    mesh = obj.data
    if not any(m and m.name in settings for m in mesh.materials): continue
    uv = mesh.uv_layers.get('MappedUV') or mesh.uv_layers.new(name='MappedUV')
    mesh.uv_layers.active = uv
    for polygon in mesh.polygons:
        mat = mesh.materials[polygon.material_index]
        period = settings.get(mat.name,{}).get('repeatMeters',1)
        normal = obj.matrix_world.to_3x3().inverted().transposed() @ polygon.normal
        axis = max(range(3),key=lambda i:abs(normal[i]))
        a,b = [(1,2),(0,2),(0,1)][axis]
        for loop in polygon.loop_indices:
            point = obj.matrix_world @ mesh.vertices[mesh.loops[loop].vertex_index].co
            uv.data[loop].uv = (point[a]/period, point[b]/period)
# All materials are non-emissive so fixtures/house light are the only runtime light.
for mat in bpy.data.materials:
    if mat.use_nodes and (node := mat.node_tree.nodes.get('Principled BSDF')):
        node.inputs['Emission Strength'].default_value = 0
bpy.context.window.scene = bpy.data.scenes['01 | ROOM - walk and place assets']
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'mappedRoom.blend'))
# Make source images portable beside the saved authoring file (do not pack duplicate pixels).
for image in bpy.data.images:
    if image.source == 'FILE' and Path(bpy.path.abspath(image.filepath)).is_file():
        image.filepath = bpy.path.relpath(image.filepath)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'mappedRoom.blend'))
sys.path.insert(0,str(APP/'scripts'))
if '--render' in sys.argv:
    from review_views import configure, render_all
    for scene in bpy.data.scenes:
        if scene.get('review_key'): configure(scene, width=960, samples=24, cpu=False)
    render_all(PROJECT, OUT/'mappedRoom.blend')
from export_environment import export
export(PROJECT)
