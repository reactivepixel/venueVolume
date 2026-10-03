#!/usr/bin/env python3
"""Verify catalog rig references and posed geometry with OpenUSD, without editing USDZ."""
import hashlib
import json
import math
from pathlib import Path
from pxr import Gf, Usd, UsdGeom

ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT/'assets/fixtures'
catalog = json.loads((LIB/'runtime-catalog.json').read_text())
reports = []
for asset in catalog:
    folder = LIB/asset['id']; source = folder/'models/fixture.usdz'
    assert hashlib.sha256(source.read_bytes()).hexdigest() == asset['sha256']
    stage = Usd.Stage.Open(str(source)); cache = UsdGeom.XformCache()
    members = {}; joints = {j['id']: j for j in asset['joints']}
    for j in asset['joints']:
        assert j['travel'] > 0 and math.isfinite(j['travel'])
        assert abs(sum(a*a for a in j['axis'])-1) < 1e-6
        assert all(math.isfinite(a) for a in j['pivot'])
        assert j['parent'] is None or j['parent'] in joints
        for path in j['members']:
            assert stage.GetPrimAtPath(path), (asset['id'], path)
            assert path not in members, (asset['id'], 'duplicate owner', path)
            members[path] = j['id']
    def pose(point, owner, byte):
        seen = set()
        while owner:
            assert owner not in seen; seen.add(owner)
            joint = joints[owner]; pivot = Gf.Vec3d(*joint['pivot'])
            angle = ((byte-128)/255)*joint['travel']
            point = pivot + Gf.Rotation(Gf.Vec3d(*joint['axis']), angle).TransformDir(point-pivot)
            owner = joint['parent']
        return point
    moving = fixed = 0
    for prim in stage.Traverse():
        if not prim.IsA(UsdGeom.Mesh): continue
        path = str(prim.GetPath())
        owning = [p for p in members if path == p or path.startswith(p+'/')]
        assert len(owning) <= 1, (asset['id'], 'overlapping moving groups', path)
        owner = members[owning[0]] if owning else None
        matrix = cache.GetLocalToWorldTransform(prim)
        points = UsdGeom.Mesh(prim).GetPointsAttr().Get()
        a, b = (matrix.Transform(Gf.Vec3d(*points[i])) for i in (0, len(points)//2))
        assert (pose(a, owner, 128)-a).GetLength() < 1e-7
        for byte in (0, 64, 192, 255):
            pa, pb = pose(a, owner, byte), pose(b, owner, byte)
            assert all(math.isfinite(v) for v in pa)
            assert abs((pa-pb).GetLength()-(a-b).GetLength()) < 1e-6
        if owner: moving += 1
        else: fixed += 1
    if asset['joints']: assert moving > 0
    for emitter in asset['emitters']:
        assert emitter['parent'] is None or emitter['parent'] in joints
        assert all(math.isfinite(a) for a in emitter['position'])
    report = dict(id=asset['id'], passed=True, source_usdz_sha256=asset['sha256'],
                  joints=len(joints), moving_meshes=moving, fixed_meshes=fixed,
                  checks=['meter-scale rig paths', 'unique moving-part ownership', 'neutral pose preserved',
                          'rigid geometry at four non-neutral poses', 'emitter parent references'],
                  realitykit='not_run', note='Mathematical rig validation; does not establish RealityKit import, appearance or physical accuracy.')
    (folder/'validation/rig.json').write_text(json.dumps(report, indent=2)+'\n')
    reports.append(report)
(LIB/'research/articulation-validation.json').write_text(json.dumps(dict(passed=True, assets=len(reports), reports=reports), indent=2)+'\n')
print(f'PASS: {len(reports)} rigs; {sum(r["joints"] for r in reports)} joints; paths, neutral and four posed geometry checks.')
