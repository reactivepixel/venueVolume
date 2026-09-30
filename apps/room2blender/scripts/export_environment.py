"""Export evaluated Blender geometry and interaction metadata to a portable USDZ bundle.

Run against a saved review .blend. This never saves or modifies that authoring file.
Only the full room is exported; review visibility and cameras are not runtime inputs.
"""
import argparse
from collections import defaultdict
import hashlib
import json
import math
from pathlib import Path
import tempfile
import sys

import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree
from pxr import Gf, Sdf, Usd, UsdGeom, UsdShade, UsdUtils

CONVERSION = Matrix(((1, 0, 0, 0), (0, 0, 1, 0), (0, -1, 0, 0), (0, 0, 0, 1)))
EXPORT_VERSION = '1.0.0'


def numbers(values):
    return [round(float(v), 6) for v in values]


def write(path, data):
    path.write_text(json.dumps(data, indent=2, sort_keys=True, allow_nan=False)+'\n')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def bounds(obj):
    points = [obj.matrix_world @ Vector(p) for p in obj.bound_box]
    return Vector([min(p[i] for p in points) for i in range(3)]), Vector([max(p[i] for p in points) for i in range(3)])


def material_values(mat):
    node = mat.node_tree.nodes.get('Principled BSDF') if mat and mat.use_nodes else None
    if node is None:
        raise ValueError(f'Expected a Principled material: {mat}')
    fallback = []
    linked = [i.name for i in node.inputs if i.is_linked]
    if linked:
        # Deliberate portable fallback for the reviewed classroom, never an implicit bake.
        if mat.name != 'Carpet / procedural gray weave' or linked != ['Base Color']:
            raise ValueError(f'Bake or replace unsupported material nodes before export: {mat.name}: {linked}')
        fallback.append('Carpet procedural weave replaced with constant gray PBR; source .blend retains weave')
    return {'color': numbers(node.inputs['Base Color'].default_value[:3]),
            'roughness': float(node.inputs['Roughness'].default_value),
            'metallic': float(node.inputs['Metallic'].default_value)}, fallback


def export(project):
    out = project/'output'
    spec = json.loads((project/'room_spec.json').read_text())
    layout = json.loads((out/'placement.json').read_text())
    scene = bpy.data.scenes['01 | ROOM - walk and place assets']
    bpy.context.window.scene = scene
    # Excluded collections have stale/identity matrix_world values after reopening a .blend.
    # Evaluate proxy transforms explicitly before serializing them; never save this visibility change.
    proxy_collection = bpy.data.collections['05 COLLISION proxies - hidden']
    scene.view_layers[0].layer_collection.children[proxy_collection.name].exclude = False
    for proxy in proxy_collection.objects:
        proxy.hide_set(False)
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    objects = sorted([o for o in scene.objects if o.type == 'MESH' and not o.name.startswith(('COL_', 'TEST'))
                      and not o.get('synthetic')], key=lambda o: o.name)
    if not objects:
        raise ValueError('No runtime geometry')
    batches = defaultdict(lambda: {'points': [], 'indices': [], 'normals': [], 'sources': []})
    materials, notes = {}, []
    # Material + 3m spatial cells reduce tiny entities without flattening the entire room.
    for obj in objects:
        evaluated = obj.evaluated_get(deps)
        mesh = evaluated.to_mesh()
        mesh.calc_loop_triangles()
        transform = CONVERSION @ obj.matrix_world
        if transform.to_3x3().determinant() <= 0:
            raise ValueError(f'Apply mirrored transforms before export: {obj.name}')
        normal_transform = transform.to_3x3().inverted().transposed()
        cell = tuple(math.floor(v/3) for v in transform.translation)
        for triangle in mesh.loop_triangles:
            mat = mesh.materials[triangle.material_index]
            if mat.name not in materials:
                materials[mat.name], warnings = material_values(mat)
                notes.extend(warnings)
            group = batches[(mat.name, cell)]
            if obj.name not in group['sources']:
                group['sources'].append(obj.name)
            for vi, li in zip(triangle.vertices, triangle.loops):
                group['indices'].append(len(group['points']))
                group['points'].append(numbers(transform @ mesh.vertices[vi].co))
                group['normals'].append(numbers((normal_transform @ mesh.corner_normals[li].vector).normalized()))
        evaluated.to_mesh_clear()
    proxies = []
    proxy_errors = []
    for obj in sorted(scene.objects, key=lambda o: o.name):
        if not obj.name.startswith('COL_'):
            continue
        source = bpy.data.objects.get(obj.get('source_object', ''))
        if source is None or any((a-b).length > .0001 for a,b in zip(bounds(obj), bounds(source))):
            proxy_errors.append(obj.name)
        transform = CONVERSION @ obj.matrix_world
        loc, rotation, scale = transform.decompose()
        local = [Vector(v) for v in obj.bound_box]
        lo = Vector([min(v[i] for v in local) for i in range(3)])
        hi = Vector([max(v[i] for v in local) for i in range(3)])
        center = transform @ ((lo+hi)/2)
        proxies.append({'id': obj.name, 'sourceID': obj['source_object'], 'shape': 'box',
                        'center': numbers(center), 'size': numbers([(hi-lo)[i]*abs(scale[i]) for i in range(3)]),
                        'rotation': numbers((rotation.x, rotation.y, rotation.z, rotation.w))})
    surface_ids = set(layout['placement_surfaces']) | {'floor'}
    if spec['recipe'] == 'classroom-v1':
        surface_ids.add('instructor-desk-top')
    surfaces = []
    for name in sorted(surface_ids):
        obj = bpy.data.objects.get(name)
        if obj is None or obj not in objects:
            raise ValueError(f'Placement surface missing from runtime geometry: {name}')
        # Recipes currently expose horizontal rectangular tops only. Fail on tilt rather than invent a plane.
        if (obj.matrix_world.to_3x3() @ Vector((0,0,1))).normalized().dot(Vector((0,0,1))) < .99999:
            raise ValueError(f'Only horizontal top placement is supported: {name}')
        horizontal = (obj.matrix_world.to_3x3() @ Vector((1,0,0))).normalized()
        if max(abs(horizontal.x), abs(horizontal.y)) < .99999:
            raise ValueError(f'Placement rectangles must align with room X/Y axes: {name}')
        lo, hi = bounds(obj)
        if name == 'floor':
            lo.x, lo.y = 0, 0
            hi.x, hi.y = spec['room']['width'], spec['room']['depth']
        if not any(p['sourceID'] == name for p in proxies):
            raise ValueError(f'Placement surface needs collision=true: {name}')
        surfaces.append({'id': name, 'role': 'floor' if name == 'floor' else 'tabletop',
                         'center': numbers(CONVERSION @ Vector(((lo.x+hi.x)/2, (lo.y+hi.y)/2, hi.z))),
                         'size': numbers((hi.x-lo.x, hi.y-lo.y)), 'normal': [0,1,0],
                         'allowedAssetCategories': ['fixture']})
    eye, target = (CONVERSION @ Vector(layout['spawn'][key]) for key in ('eye','look_at'))
    direction = target-eye
    w, d, h = (spec['room'][k] for k in ('width','depth','height'))
    manifest = {'schemaVersion': 1, 'exporterVersion': EXPORT_VERSION, 'id': spec['id'],
                'title': spec.get('title', spec['id']), 'units': 'meters', 'upAxis': 'Y',
                'forwardAxis': '-Z', 'scaleStatus': spec['scale_status'],
                'bounds': {'min': [0,0,-d], 'max': [w,h,0]},
                'spawn': {'position': numbers((eye.x,0,eye.z)), 'yaw': round(math.atan2(-direction.x,-direction.z),6)},
                'colliders': proxies, 'surfaces': surfaces,
                'sourceSHA256': spec['source_sha256'], 'materialNotes': notes}
    checks = []
    def check(name, ok, detail):
        checks.append({'check': name, 'passed': bool(ok), 'detail': detail})
    check('collision proxies match source object bounds', not proxy_errors, proxy_errors)
    with tempfile.TemporaryDirectory(dir=out, prefix='.usd-') as directory:
        stage_path = Path(directory)/'environment.usdc'
        stage = Usd.Stage.CreateNew(str(stage_path))
        root = UsdGeom.Xform.Define(stage, '/Environment')
        stage.SetDefaultPrim(root.GetPrim())
        UsdGeom.Xform.Define(stage, '/Environment/Geometry')
        UsdGeom.Scope.Define(stage, '/Environment/Materials')
        UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
        UsdGeom.SetStageMetersPerUnit(stage, 1)
        usd_materials = {}
        for i, (name, value) in enumerate(sorted(materials.items())):
            mat = UsdShade.Material.Define(stage, f'/Environment/Materials/m{i:03}')
            shader = UsdShade.Shader.Define(stage, str(mat.GetPath())+'/Shader')
            shader.CreateIdAttr('UsdPreviewSurface')
            shader.CreateInput('diffuseColor', Sdf.ValueTypeNames.Color3f).Set(Gf.Vec3f(*value['color']))
            shader.CreateInput('roughness', Sdf.ValueTypeNames.Float).Set(value['roughness'])
            shader.CreateInput('metallic', Sdf.ValueTypeNames.Float).Set(value['metallic'])
            shader.CreateOutput('surface', Sdf.ValueTypeNames.Token)
            mat.CreateSurfaceOutput().ConnectToSource(shader.ConnectableAPI(), 'surface')
            usd_materials[name] = mat
        all_points, all_faces, mappings = [], [], {}
        for i, ((material, cell), data) in enumerate(sorted(batches.items())):
            path = f'/Environment/Geometry/chunk_{i:03}'
            mesh = UsdGeom.Mesh.Define(stage, path)
            mesh.CreatePointsAttr(data['points'])
            mesh.CreateFaceVertexCountsAttr([3]*(len(data['indices'])//3))
            mesh.CreateFaceVertexIndicesAttr(data['indices'])
            mesh.CreateNormalsAttr(data['normals'])
            mesh.SetNormalsInterpolation(UsdGeom.Tokens.vertex)
            mesh.CreateSubdivisionSchemeAttr(UsdGeom.Tokens.none)
            mesh.CreateOrientationAttr(UsdGeom.Tokens.rightHanded)
            mesh.CreateDoubleSidedAttr(False)
            points = data['points']
            mesh.CreateExtentAttr([Gf.Vec3f(*[min(p[j] for p in points) for j in range(3)]),
                                   Gf.Vec3f(*[max(p[j] for p in points) for j in range(3)])])
            UsdShade.MaterialBindingAPI.Apply(mesh.GetPrim()).Bind(usd_materials[material])
            for name in data['sources']:
                mappings.setdefault(name, []).append(path)
            offset = len(all_points)
            all_points.extend(points)
            all_faces.extend(tuple(offset+j for j in data['indices'][k:k+3]) for k in range(0,len(data['indices']),3))
        for surface in surfaces:
            surface['primPaths'] = mappings[surface['id']]
        manifest['geometry'] = {'triangles': len(all_faces), 'meshes': len(batches), 'materials': len(materials),
                                'sourceObjects': len(objects)}
        semantic = {'manifest': manifest, 'materials': materials,
                    'batches': [(str(k),v) for k,v in sorted(batches.items())]}
        manifest['version'] = hashlib.sha256(json.dumps(semantic, sort_keys=True, allow_nan=False).encode()).hexdigest()
        stage.GetRootLayer().Save()
        package = out/'environment.usdz'
        # The USD library emits the required uncompressed, 64-byte-aligned USDZ archive.
        if not UsdUtils.CreateNewUsdzPackage(Sdf.AssetPath(str(stage_path)), str(package)):
            raise ValueError('USDZ packaging failed')
        compliance = UsdUtils.ComplianceChecker(arkit=True)
        compliance.CheckCompliance(str(package))
        check('OpenUSD ARKit compatibility rules', not compliance.GetErrors() and not compliance.GetFailedChecks(),
              {'errors': compliance.GetErrors(), 'failed': compliance.GetFailedChecks(), 'warnings': compliance.GetWarnings()})
        reopened = Usd.Stage.Open(str(package))
        check('USDZ opens with meter Y-up root', reopened is not None and
              UsdGeom.GetStageUpAxis(reopened) == 'Y' and UsdGeom.GetStageMetersPerUnit(reopened) == 1 and
              str(reopened.GetDefaultPrim().GetPath()) == '/Environment', 'Geometry converted once; root is identity')
        imported = [UsdGeom.Mesh(p) for p in reopened.Traverse() if p.IsA(UsdGeom.Mesh)]
        check('round-trip mesh and triangle counts', len(imported) == len(batches) and
              sum(len(m.GetFaceVertexCountsAttr().Get()) for m in imported) == len(all_faces), manifest['geometry'])
        check('normals and materials survive export', all(
            len(m.GetNormalsAttr().Get()) == len(m.GetPointsAttr().Get()) and
            bool(UsdShade.MaterialBindingAPI(m).ComputeBoundMaterial()[0]) for m in imported), len(imported))
        # Test the reopened mesh, not the Blender source or original in-memory geometry.
        points, faces = [], []
        for mesh in imported:
            offset = len(points)
            points.extend(tuple(p) for p in mesh.GetPointsAttr().Get())
            indices = list(mesh.GetFaceVertexIndicesAttr().Get())
            faces.extend(tuple(offset+j for j in indices[k:k+3]) for k in range(0,len(indices),3))
        bvh = BVHTree.FromPolygons(points, faces, all_triangles=True)
        point, _, _, _ = bvh.ray_cast(Vector(manifest['spawn']['position'])+Vector((0,1.6,0)), Vector((0,-1,0)), 3)
        check('exported spawn is over floor', point is not None and abs(point.y) < .002, list(point) if point else None)
        for surface in surfaces:
            if surface['role'] == 'floor':
                continue
            center = Vector(surface['center'])
            point, _, _, _ = bvh.ray_cast(center+Vector((0,.1,0)), Vector((0,-1,0)), .2)
            check('exported placement / '+surface['id'], point is not None and abs(point.y-center.y) < .002,
                  list(point) if point else None)
        if spec['recipe'] == 'classroom-v1':
            point, _, _, _ = bvh.ray_cast(Vector((3.6,1.7,-3.9)), Vector((1,0,0)), 10)
            check('exported wall occludes outward ray', point is not None and abs(point.x-w) < .2,
                  list(point) if point else None)
        check('no cameras lights or test props', not any(p.IsA(UsdGeom.Camera) or 'TEST' in str(p.GetPath()) for p in reopened.Traverse()),
              'Only explicit runtime mesh/material hierarchy exported')
        # A real DCC round trip also catches hierarchy/axis issues not rejected by usdchecker.
        imported_scene = bpy.data.scenes.new('Runtime export validation')
        bpy.context.window.scene = imported_scene
        bpy.ops.wm.usd_import(filepath=str(package.resolve()))
        bpy.context.view_layer.update()
        imported_objects = [o for o in imported_scene.objects if o.type == 'MESH']
        imported_points = [o.matrix_world @ v.co for o in imported_objects for v in o.data.vertices]
        expected_points = [CONVERSION.inverted() @ Vector(p) for p in all_points]
        def envelope(points):
            return [min(p[i] for p in points) for i in range(3)]+[max(p[i] for p in points) for i in range(3)]
        imported_bounds = envelope(imported_points) if imported_points else []
        expected_bounds = envelope(expected_points)
        check('Blender USDZ import preserves hierarchy and dimensions', len(imported_objects) == len(batches) and
              len(imported_bounds) == 6 and all(abs(a-b) < .0001 for a,b in zip(imported_bounds, expected_bounds)),
              {'expectedZUpBounds': expected_bounds, 'importedZUpBounds': imported_bounds})
        bpy.context.window.scene = scene
        manifest['asset'] = {'file': 'environment.usdz', 'sha256': sha(package), 'bytes': package.stat().st_size}
    write(out/'environment.json', manifest)
    report = {'passed': all(c['passed'] for c in checks), 'checks': checks,
              'version': manifest['version'], 'geometry': manifest['geometry'], 'materialNotes': notes,
              'authoringBlendSHA256': sha(Path(bpy.data.filepath)),
              'exportScriptSHA256': sha(Path(__file__)),
              'blenderVersion': bpy.app.version_string,
              'realityKitValidation': 'pending Mac simulator/device import; not available in Blender'}
    write(out/'environment-validation.json', report)
    if not report['passed']:
        raise ValueError('Runtime export validation failed; see environment-validation.json')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--project', type=Path, required=True)
    a = p.parse_args(sys.argv[sys.argv.index('--')+1:])
    export(a.project.resolve())
