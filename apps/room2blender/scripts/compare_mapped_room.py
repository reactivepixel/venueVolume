"""Run in Blender. USDZ structural A/B checks and optional offline Cycles light sweep.
These timings are NOT RealityKit frame times or Vision Pro capacity measurements.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import statistics
import sys
import time
import zipfile
import bpy
from mathutils import Vector
from pxr import Usd, UsdGeom, UsdShade, UsdLux

APP = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('--render',action='store_true')
a = p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
out = APP/'mappedRoom/review'
out.mkdir(exist_ok=True)
rooms = {'baseline': APP/'output', 'mappedRoom': APP/'mappedRoom/output'}
checks = []
def check(name, success):
    checks.append({'check': name, 'passed': bool(success)})
    if not success: raise ValueError(name)

def meshes(stage):
    return {str(prim.GetPath()): UsdGeom.Mesh(prim) for prim in stage.Traverse() if prim.IsA(UsdGeom.Mesh)}

stages = {key: Usd.Stage.Open(str(folder/'environment.usdz')) for key,folder in rooms.items()}
base, mapped = (meshes(stages[key]) for key in rooms)
check('same mesh paths', base.keys() == mapped.keys())
for path in base:
    for attribute in ['points', 'faceVertexIndices', 'faceVertexCounts', 'normals', 'extent']:
        check(path+'/'+attribute, base[path].GetPrim().GetAttribute(attribute).Get() == mapped[path].GetPrim().GetAttribute(attribute).Get())
texture_count = 0
for prim in stages['mappedRoom'].Traverse():
    if not prim.IsA(UsdShade.Shader): continue
    shader = UsdShade.Shader(prim)
    if shader.GetIdAttr().Get() == 'UsdUVTexture':
        texture_count += 1
        check('embedded texture resolves '+str(prim.GetPath()), bool(shader.GetInput('file').Get().resolvedPath))
    if shader.GetIdAttr().Get() == 'UsdPreviewSurface':
        check('opaque '+str(prim.GetPath()), shader.GetInput('opacity').Get() in (None,1))
        check('nonemissive '+str(prim.GetPath()), shader.GetInput('emissiveColor').Get() in (None,(0,0,0)))
check('six shared photo textures',texture_count==6)
for key in ['colliders','surfaces','bounds','spawn','geometry']:
    values = [json.loads((folder/'environment.json').read_text())[key] for folder in rooms.values()]
    check('identical manifest '+key,values[0]==values[1])
report = dict(passed=True,checks=checks,assets={},offlineCycles=[])
for key,folder in rooms.items():
    package=folder/'environment.usdz'
    with zipfile.ZipFile(package) as archive:
        textures = [entry for entry in archive.infolist() if entry.filename.endswith('.png')]
    report['assets'][key] = dict(bytes=package.stat().st_size,sha256=hashlib.sha256(package.read_bytes()).hexdigest(),
                                textures=len(textures),texturePNGBytes=sum(e.file_size for e in textures),
                                geometry=json.loads((folder/'environment.json').read_text())['geometry'])
report['textureBudget'] = json.loads((APP/'mappedRoom/texture-provenance.json').read_text())['estimatedRGBA8WithMipBytes']
report['nativePerformance'] = {'status':'pending device run', 'displayedFPS':None,'gpuFrameTimeMS':None,'maximumSmoothShadowLights':None}

if a.render:
    prefs=bpy.context.preferences.addons['cycles'].preferences
    prefs.compute_device_type='CUDA'; prefs.get_devices()
    for device in prefs.devices: device.use=device.type=='CUDA'
    gpu=any(d.use and d.type=='CUDA' for d in prefs.devices)
    report['offlineMethod'] = dict(renderer='Blender '+bpy.app.version_string+' / Cycles', devices=[d.name for d in prefs.devices if d.use],
        resolution=[640,400],samples=16,repeats=3,lightCounts=[0,1,2,4,8,16,32,64],
        scope='Offline room-only synthetic spotlights; no fixture rigs. Includes render submission/denoising. Not native GPU frame timing or displayed FPS.')
    for key,folder in rooms.items():
        bpy.ops.wm.read_factory_settings(use_empty=True)
        scene=bpy.context.scene
        scene.render.engine='CYCLES';scene.cycles.device='GPU' if gpu else 'CPU'
        scene.cycles.samples=16;scene.cycles.seed=0;scene.cycles.use_adaptive_sampling=False;scene.cycles.use_denoising=True
        scene.render.resolution_x=640;scene.render.resolution_y=400;scene.render.resolution_percentage=100
        scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX'
        bpy.ops.wm.usd_import(filepath=str(folder/'environment.usdz'))
        world=bpy.data.worlds.new('Controlled world');world.use_nodes=True;world.node_tree.nodes['Background'].inputs['Strength'].default_value=.12;scene.world=world
        cam=bpy.data.objects.new('Comparison camera',bpy.data.cameras.new('Comparison camera'));scene.collection.objects.link(cam)
        cam.location=(3.6,1.2,1.65);cam.rotation_euler=(Vector((3.6,6.3,1.2))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=20;scene.camera=cam
        lights=[]
        for i in range(64):
            data=bpy.data.lights.new('RGB '+str(i),'SPOT');data.energy=130;data.color=[(1,.05,.03),(.04,1,.05),(.05,.15,1)][i%3]
            data.spot_size=math.radians(60);data.spot_blend=.3;data.shadow_soft_size=.025
            obj=bpy.data.objects.new(data.name,data);scene.collection.objects.link(obj)
            obj.location=(.7+(i%8)*.82,.7+(i//8)*.9,.45)
            target=Vector((.8+(i%3)*2.8,7.7,1.5))
            obj.rotation_euler=(target-obj.location).to_track_quat('-Z','Y').to_euler();lights.append(obj)
        for count in report['offlineMethod']['lightCounts']:
            for i,obj in enumerate(lights): obj.hide_render=i>=count
            bpy.ops.render.render() # warm compilation/cache; excluded
            durations=[]
            for _ in range(3):
                start=time.perf_counter();bpy.ops.render.render();durations.append(time.perf_counter()-start)
            report['offlineCycles'].append(dict(room=key,shadowLights=count,seconds=durations,medianSeconds=statistics.median(durations)))
            if count in (0,8):
                bpy.data.images['Render Result'].save_render(str(out/f'{key}-{count}-lights.png'),scene=scene)
            (out/'comparison.json').write_text(json.dumps(report,indent=2)+'\n')
(out/'comparison.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({key:value for key,value in report.items() if key!='checks'},indent=2))
