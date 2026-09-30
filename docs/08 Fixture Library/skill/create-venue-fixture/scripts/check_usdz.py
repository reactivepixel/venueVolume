"""Run with Blender --background --python-exit-code 1 --python SCRIPT -- fixture.json."""
import hashlib
import json
import math
from pathlib import Path
import sys
from pxr import Usd, UsdGeom, UsdUtils

entry = Path(sys.argv[sys.argv.index('--')+1]).resolve()
record = json.loads(entry.read_text())
asset = entry.parent/'models/fixture.usdz'
expected = [record['dimensions'][axis]['value'] for axis in ('width','height','depth')]
tolerance = record['model']['dimension_tolerance_m']
if not all(isinstance(v,(float,int)) and not isinstance(v,bool) and math.isfinite(v) and v > 0 for v in expected+[tolerance]):
    raise ValueError('Fill in positive meter dimensions and an explicit tolerance before validating scale')
stage = Usd.Stage.Open(str(asset))
if stage is None or not stage.GetDefaultPrim():
    raise ValueError('USDZ needs a default fixture root')
cache = UsdGeom.BBoxCache(Usd.TimeCode.Default(), [UsdGeom.Tokens.default_,UsdGeom.Tokens.render])
bounds = cache.ComputeWorldBound(stage.GetDefaultPrim()).ComputeAlignedRange()
lo, hi = list(bounds.GetMin()), list(bounds.GetMax())
actual = [b-a for a,b in zip(lo,hi)]
compliance = UsdUtils.ComplianceChecker(arkit=True)
compliance.CheckCompliance(str(asset))
meshes = [p for p in stage.Traverse() if p.IsA(UsdGeom.Mesh)]
checks = {
    'meter_y_up': UsdGeom.GetStageMetersPerUnit(stage) == 1 and UsdGeom.GetStageUpAxis(stage) == 'Y',
    'finite_nonempty_mesh_bounds': bool(meshes) and all(math.isfinite(v) for v in lo+hi) and all(v > 0 for v in actual),
    'dimensions_match_reference_pose': all(abs(a-b) <= tolerance for a,b in zip(actual,expected)),
    'usd_arkit_compatibility': not compliance.GetErrors() and not compliance.GetFailedChecks(),
    'declared_parts_exist': all(bool(stage.GetPrimAtPath(p['prim_path'])) for p in record['model']['parts']),
    'declared_emitters_exist': all(bool(stage.GetPrimAtPath(p['prim_path'])) for p in record['model']['emitters'])
}
report = {'passed': all(checks.values()), 'checks': checks, 'asset_sha256': hashlib.sha256(asset.read_bytes()).hexdigest(),
          'bounds_m': {'min':lo,'max':hi}, 'actual_dimensions_m':actual,
          'expected_dimensions_m':expected, 'tolerance_m':tolerance, 'mesh_count':len(meshes),
          'errors':compliance.GetErrors(), 'failed_checks':compliance.GetFailedChecks(), 'warnings':compliance.GetWarnings(),
          'realitykit': 'not tested by this script', 'hardware': 'not tested by this script'}
out = entry.parent/'validation/usdz.json'
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(report,indent=2,allow_nan=False)+'\n')
print(json.dumps(report,indent=2))
if not report['passed']:
    raise ValueError('Fixture export validation failed')
