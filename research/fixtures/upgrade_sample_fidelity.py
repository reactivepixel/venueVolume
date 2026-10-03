#!/usr/bin/env python3
"""Rebuild and revise the five fixture-specific sample models."""
import argparse, hashlib, json, subprocess, sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
LIB=ROOT/"docs/08 Fixture Library/skill/create-venue-fixture/scripts/library.py"
CHECK=ROOT/"docs/08 Fixture Library/skill/create-venue-fixture/scripts/check_usdz.py"
TODAY="2026-09-30"
FIXTURES={
    "adj/focus-spot-4z":"Rounded base/control panel, U-yoke, capsule head, tilt hubs, optical barrel, bezel and cooling vents.",
    "chauvet-professional/colorado-solo-batten":"Ribbed extrusion, continuous twelve-segment optic, electronics pod and mounting feet.",
    "claypaky/sharpy":"Tapered compact moving-head silhouette, console base, heavy yoke, cylindrical optical body and deep lens bezel.",
    "elation-professional/kl-fresnel-8":"Cylindrical lamp body, rear electronics enclosure, Fresnel rings, full yoke and four barn-door leaves.",
    "robe-lighting/forte":"Vented rounded base, display, angled heavy yoke, long optical barrel, metal bezel and cooling detail.",
}

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def artifact(folder,role,path):return {"role":role,"file":path,"sha256":sha(folder/path)}

parser=argparse.ArgumentParser()
parser.add_argument("--only",action="append",choices=sorted(FIXTURES))
args=parser.parse_args()
selected=args.only or list(FIXTURES)

for fixture_id in selected:
    detail=FIXTURES[fixture_id]
    folder=ROOT/"assets/fixtures"/fixture_id
    record_path=folder/"fixture.json"
    record=json.loads(record_path.read_text())
    if record['model'].get('detail_level')=='high':
        raise SystemExit('Detailed assets preserved; use build_detailed_catalog.py: '+fixture_id)
    subprocess.run(["blender","--background","--python-exit-code","1","--python",str(folder/"models/build_fixture.py")],check=True)
    subprocess.run(["blender","--background","--python-exit-code","1","--python",str(CHECK),"--",str(record_path)],check=True)
    report=json.loads((folder/"validation/usdz.json").read_text())
    if not report.get("passed"):raise RuntimeError(f"USDZ validation failed: {fixture_id}")
    record["revision"]+=1
    record["updated_at"]=TODAY
    record["model"]["bounds_m"]=report["bounds_m"]
    record["model"]["assumptions"]=[
        "Fixture-specific procedural approximation informed by the stored official product image; not manufacturer CAD.",
        detail,
        "Small fasteners, exact surface curvature, labels, internal mechanics, connector geometry and photometry remain simplified.",
        "Moving components remain separately addressable, but runtime articulation joints are not authored.",
    ]
    record["revision_notes"].append("Revision 2 replaces the generic proxy with fixture-specific silhouette, optics, housing and mounting details while preserving sourced outer dimensions.")
    artifacts=[
        artifact(folder,"authoring","models/fixture.blend"),
        artifact(folder,"runtime","models/fixture.usdz"),
        artifact(folder,"generator","models/build_fixture.py"),
    ]
    for path in sorted((folder/"previews").glob("*.png")):
        artifacts.append(artifact(folder,"preview",path.relative_to(folder).as_posix()))
    artifacts.append(artifact(folder,"validation","validation/usdz.json"))
    record["model"]["artifacts"]=artifacts
    record_path.write_text(json.dumps(record,indent=2,ensure_ascii=False)+"\n")
    note=ROOT/"docs/08 Fixture Library/entries"/Path(fixture_id+".md")
    text=note.read_text()
    text=text.replace("- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.",f"- Model: fixture-specific editable Blender approximation, meter-scale USDZ, Y-up and -Z forward. {detail}")
    text=text.replace("## Assumptions and follow-up",f"## Fidelity revision\n\n- Revision 2 replaces the generic proxy with fixture-specific geometry derived from the stored official product image.\n- Exact labels, small fasteners, connector geometry, internal mechanisms and photometry remain simplified.\n\n## Assumptions and follow-up")
    note.write_text(text)
    subprocess.run([sys.executable,str(LIB),"validate",str(record_path),"--root",str(ROOT)],check=True)

subprocess.run([sys.executable,str(LIB),"index","--root",str(ROOT)],check=True)
print(f"Upgraded {len(selected)} fixture models")
