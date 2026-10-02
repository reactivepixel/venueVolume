#!/usr/bin/env python3
"""Run under Blender: independently reopen saved authoring and packaged runtime assets."""
import bpy, hashlib, json, math, re, sys, os
from pathlib import Path
from pxr import Usd, UsdGeom, UsdShade, Gf
ROOT=Path(__file__).resolve().parents[2]

def audit(path):
    record=json.loads(path.read_text());folder=path.parent
    bpy.ops.wm.open_mainfile(filepath=str(folder/'models/fixture.blend'))
    bpy.context.view_layer.update()
    meshes={re.sub('[^A-Za-z0-9_]','_',o.name):o for o in bpy.data.objects if o.type=='MESH'}
    stage=Usd.Stage.Open(str(folder/'models/fixture.usdz'));cache=UsdGeom.XformCache()
    errors=[];max_error=0.;count=0;triangles=0;matched=set()
    for prim in stage.Traverse():
        if not prim.IsA(UsdGeom.Mesh):continue
        mesh=UsdGeom.Mesh(prim);key=prim.GetName().rsplit('_',1)[0];obj=meshes.get(key)
        if obj is None:errors.append('Missing Blender mesh '+key);continue
        matched.add(key);count+=1;obj.data.calc_loop_triangles()
        signed_volume=sum(obj.data.vertices[t.vertices[0]].co.dot(obj.data.vertices[t.vertices[1]].co.cross(obj.data.vertices[t.vertices[2]].co)) for t in obj.data.loop_triangles)/6
        if signed_volume < -1e-10:errors.append('Inward-facing closed mesh: '+key)
        up=mesh.GetPointsAttr().Get();bp=obj.data.vertices
        if len(up)!=len(bp):errors.append('Vertex count differs: '+key);continue
        mat=cache.GetLocalToWorldTransform(prim)
        for b,u in zip(bp,up):
            p=obj.matrix_world@b.co;q=mat.Transform(Gf.Vec3d(*u))
            max_error=max(max_error,math.dist((p.x,p.z,-p.y),q))
        ui=list(mesh.GetFaceVertexIndicesAttr().Get());bi=[i for t in obj.data.loop_triangles for i in t.vertices]
        if ui!=bi:errors.append('Triangle topology differs: '+key)
        triangles+=len(ui)//3
        material=UsdShade.MaterialBindingAPI(prim).ComputeBoundMaterial()[0]
        if not material:errors.append('Unbound material: '+key)
        else:
            shader=UsdShade.Shader(stage.GetPrimAtPath(str(material.GetPath())+'/Surface'))
            color=shader.GetInput('diffuseColor').Get();actual=obj.data.materials[0].diffuse_color
            if max(abs(float(color[i])-actual[i]) for i in range(3))>1e-6:errors.append('Material color differs: '+key)
    if matched!=set(meshes):errors.append('Saved Blender contains extra physical meshes')
    if max_error>1e-6:errors.append('World-space vertex deviation exceeds one micrometre')
    if any(not math.isfinite(float(v)) for o in meshes.values() for vert in o.data.vertices for v in vert.co):errors.append('Nonfinite authoring coordinates')
    report={'fixture_id':record['id'],'passed':not errors,'mesh_count':count,'triangle_count':triangles,'max_vertex_deviation_m':max_error,'tolerance_m':1e-6,'tests':['Saved Blender and USDZ reopened independently','World-space positions after unit/axis conversion','Exact ordered triangle topology','Material bindings and diffuse color','No missing or extra physical meshes','Finite coordinates','Outward closed-solid winding'],'errors':errors,'realitykit_device_test':'not_run'}
    dest=folder/'validation/parity.json';dest.write_text(json.dumps(report,indent=2)+'\n')
    arts=record['model']['artifacts'];arts[:]=[a for a in arts if a['file']!='validation/parity.json']
    arts.append({'role':'validation','file':'validation/parity.json','sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
    path.write_text(json.dumps(record,indent=2,ensure_ascii=False)+'\n')
    print(record['id'],report['passed'],max_error,flush=True)
    return report

reports=[]
for path in sorted((ROOT/'assets/fixtures').glob('*/*/fixture.json')):
    record=json.loads(path.read_text())
    if record['model']['status'] != 'validated': continue
    cached=path.parent/'validation/parity.json'
    # Cache only reports whose tracked hash and both independently tested inputs match.
    artifacts={a['file']:a['sha256'] for a in record['model']['artifacts']}
    reusable=cached.exists() and all(
        (path.parent/name).exists() and hashlib.sha256((path.parent/name).read_bytes()).hexdigest()==artifacts.get(name)
        for name in ('models/fixture.blend','models/fixture.usdz','validation/parity.json'))
    if '--new-only' in sys.argv and reusable:
        reports.append(json.loads(cached.read_text()));continue
    try: reports.append(audit(path))
    except Exception as error:
        reports.append(dict(fixture_id=record['id'],passed=False,mesh_count=0,triangle_count=0,
                            max_vertex_deviation_m=0,errors=[str(error)]))
summary={'fixture_count':len(reports),'passed':all(r['passed'] for r in reports),'mesh_count':sum(r['mesh_count'] for r in reports),'triangle_count':sum(r['triangle_count'] for r in reports),'max_vertex_deviation_m':max((r['max_vertex_deviation_m'] for r in reports),default=0),'fixtures':reports}
(ROOT/'assets/fixtures/research/geometry-audit.json').write_text(json.dumps(summary,indent=2)+'\n')
sys.stdout.flush();os._exit(0 if summary['passed'] else 1)
