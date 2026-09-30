#!/usr/bin/env python3
"""Generate one source-backed fixture package for every catalog CSV row."""
import argparse, csv, hashlib, json, re, subprocess, sys
from datetime import date
from pathlib import Path
from urllib.request import Request, urlopen

ROOT=Path(__file__).resolve().parents[2]
CSV=ROOT/"assets/fixtures/research/major-manufacturer-fixtures.csv"
MAP=ROOT/"research/fixtures/fixture_dimension_map.json"
LIB=ROOT/"docs/08 Fixture Library/skill/create-venue-fixture/scripts/library.py"
CHECK=ROOT/"docs/08 Fixture Library/skill/create-venue-fixture/scripts/check_usdz.py"
TODAY="2026-09-30"

def slug(s):
    s=re.sub(r"[^a-z0-9]+","-",s.lower()).strip("-")
    return s
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def fact(value,source_ids,status="documented",unit=None,note=None):
    x={"value":value,"status":status,"source_ids":source_ids}
    if unit is not None:x["unit"]=unit
    if note:x["note"]=note
    return x
def artifact(folder,role,path):
    p=folder/path
    return {"role":role,"file":path,"sha256":sha(p)}
def shape(row):
    text=(row["type"]+" "+row["subtype"]).lower()
    if "moving head" in text:return "moving_head"
    if any(x in text for x in ("batten","bar","line")):return "batten"
    return "static"
def source_urls(row,data):
    urls=[row["url"]]
    for key in ("source_urls","sources"):
        val=data.get(key,[])
        if isinstance(val,str):val=[val]
        for item in val:
            u=item.get("url") if isinstance(item,dict) else item
            if isinstance(u,str) and u.startswith("http") and u not in urls:urls.append(u)
    return urls
def download(url,path):
    try:
        req=Request(url,headers={"User-Agent":"Mozilla/5.0 VenueVolume fixture research"})
        with urlopen(req,timeout=25) as r:path.write_bytes(r.read())
        return True
    except Exception as e:
        print(f"source download skipped: {url}: {e}",file=sys.stderr);return False
def record_for(row,dims,folder,download_sources=True):
    data=json.loads(row["data"]); imgs=json.loads(row["images"])
    (folder/"sources").mkdir(parents=True,exist_ok=True)
    mid=slug(row["manufacturer"]); fid=f"{mid}/{slug(row['name'])}"
    sources=[]
    for i,u in enumerate(source_urls(row,data),1):
        sources.append({"id":f"official-{i}","url":u,"title":f"{row['manufacturer']} {row['name']} official source {i}","kind":"manufacturer_product" if i==1 else "manufacturer_manual","accessed_at":TODAY,"document_revision":None,"locator":"Product page/specification section","reuse_status":"reference_only"})
    if imgs:
        ext=Path(imgs[0].split("?")[0]).suffix.lower()
        if ext not in (".jpg",".jpeg",".png",".webp"):ext=".jpg"
        local=folder/"sources"/f"official-product-image{ext}"
        local.parent.mkdir(parents=True,exist_ok=True)
        if download_sources and download(imgs[0],local):
            sources.append({"id":"official-image","url":imgs[0],"title":f"{row['manufacturer']} {row['name']} official product image","kind":"manufacturer_asset","accessed_at":TODAY,"document_revision":None,"locator":"Manufacturer product image","reuse_status":"reference_only","file":local.relative_to(folder).as_posix(),"sha256":sha(local)})
    else:
        (folder/"sources/README.md").write_text("# Local source assets\n\nNo official product-image URL was available in the research CSV. Remote manufacturer sources are recorded in `../fixture.json`.\n")
    sids=["official-1"]
    ds=dims["axis_status"]
    note=dims["axis_note"] if ds=="estimated" else None
    protocols=data.get("protocols",[])
    features={"optical":{},"electrical":{},"mechanical":{},"control":{}}
    features["control"]["protocols"]=fact(protocols,sids)
    for key,group in (("power","electrical"),("weight","mechanical"),("zoom","optical"),("ip_rating","mechanical"),("output","optical")):
        if key in data:features[group][key]=fact(data[key],sids)
    if data.get("notable") or data.get("notable_specs"):
        features["optical"]["notable"]=fact(data.get("notable",data.get("notable_specs")),sids)
    raw_modes=data.get("dmx_channels",data.get("channels",[]))
    if isinstance(raw_modes,int):raw_modes=[raw_modes]
    modes=[]
    for footprint in dict.fromkeys(x for x in raw_modes if isinstance(x,int) and 1<=x<=512):
        modes.append({"name":f"{footprint}-channel mode","footprint":footprint,"source_ids":sids,"mapping_status":"not_transcribed","channels":[]})
    spec={"id":fid,"width_m":dims["width_m"],"height_m":dims["height_m"],"depth_m":dims["depth_m"],"shape":shape(row)}
    emitter="/Fixture/Head/Emitter" if spec["shape"]=="moving_head" else "/Fixture/Emitter"
    parts=[{"name":"base","prim_path":"/Fixture/Base"},{"name":"yoke","prim_path":"/Fixture/Yoke"},{"name":"head","prim_path":"/Fixture/Head"},{"name":"lens","prim_path":"/Fixture/Head/Lens"}] if spec["shape"]=="moving_head" else ([{"name":"body","prim_path":"/Fixture/Body"},{"name":"lens","prim_path":"/Fixture/Lens"}] if spec["shape"]=="batten" else [{"name":"body","prim_path":"/Fixture/Body"},{"name":"yoke","prim_path":"/Fixture/Yoke"},{"name":"lens","prim_path":"/Fixture/Lens"}])
    return spec,{"schema_version":1,"id":fid,"revision":1,"updated_at":TODAY,"status":"ready_for_visualization" if ds=="documented" else "researched","identity":{"manufacturer":row["manufacturer"],"model":row["name"],"variant":row["model_number"] or None,"aliases":[]},"sources":sources,"dimensions":{"width":fact(dims["width_m"],sids,ds,"m",note),"height":fact(dims["height_m"],sids,ds,"m",note),"depth":fact(dims["depth_m"],sids,ds,"m",note),"reference_pose":"shipping/upright reference pose; moving head centered"},"features":features,"dmx_modes":modes,"model":{"status":"validated","representation":"procedural_approximation","units":"meters","up_axis":"Y","forward_axis":"-Z","origin":"floor center; X horizontal, Y up, optical forward -Z","reference_pose":"shipping/upright reference pose; moving head centered","dimension_tolerance_m":0.001,"bounds_m":None,"parts":parts,"joints":[],"emitters":[{"name":"primary light output","prim_path":emitter}],"assumptions":["Procedural visualization proxy, not manufacturer CAD.",dims["axis_note"],"Moving components are separated but no runtime articulation joints are authored."],"artifacts":[]},"verification":{"realitykit":"not_tested","hardware":"not_tested","notes":["OpenUSD structural validation passed; RealityKit and physical hardware were not tested."]},"unresolved":(["Confirm dimension axis assignment from a manufacturer dimensional drawing before promotion."] if ds=="estimated" else [])+(["No official product image URL was present in the research CSV."] if not imgs else []),"revision_notes":["Initial source-backed procedural asset package generated from the major-manufacturer fixture research CSV."]}

def write_wrapper(folder,spec):
    rel=Path("../../../_shared/procedural_fixture.py")
    text=f'''#!/usr/bin/env python3\nfrom pathlib import Path\nimport importlib.util, os, sys\nHERE=Path(__file__).resolve().parent\nmodule_path=(HERE/{str(rel)!r}).resolve()\ns=importlib.util.spec_from_file_location("venue_fixture_builder",module_path)\nm=importlib.util.module_from_spec(s);s.loader.exec_module(m)\nSPEC={spec!r}\nm.build(SPEC,HERE.parent)\nsys.stdout.flush(); sys.stderr.flush(); os._exit(0)\n'''
    (folder/"models").mkdir(parents=True,exist_ok=True)
    (folder/"models/build_fixture.py").write_text(text)
def write_note(folder,row,record):
    note=ROOT/"docs/08 Fixture Library/entries"/Path(record["id"]+".md");note.parent.mkdir(parents=True,exist_ok=True)
    d=record["dimensions"]; protocols=", ".join(record["features"]["control"]["protocols"]["value"])
    note.write_text(f'''# {row["manufacturer"]} {row["name"]}\n\n- Library state: `{record["status"]}`\n- Identity: model `{row["model_number"] or "not stated"}`; {row["type"]} / {row["subtype"]}\n- Official source: [{row["url"]}]({row["url"]}) (accessed {TODAY})\n- Reference envelope: {d["width"]["value"]:.4f} m W × {d["height"]["value"]:.4f} m H × {d["depth"]["value"]:.4f} m D\n- Control: {protocols}; exact personalities are retained as footprints only when the source supplied them. Channel functions are not invented.\n- Model: editable Blender procedural approximation, meter-scale USDZ, Y-up and -Z forward. Parts are separated; appearance and articulation are intentionally approximate.\n- Validation: OpenUSD structure, scale envelope, declared prims, and ARKit profile checked. RealityKit rendering and hardware remain untested.\n\n## Local assets\n\n- [Fixture record](../../../../assets/fixtures/{record["id"]}/fixture.json)\n- [Blender model](../../../../assets/fixtures/{record["id"]}/models/fixture.blend)\n- [USDZ model](../../../../assets/fixtures/{record["id"]}/models/fixture.usdz)\n- [USDZ validation](../../../../assets/fixtures/{record["id"]}/validation/usdz.json)\n\n## Assumptions and follow-up\n\n{''.join(f'- {x}\n' for x in record["model"]["assumptions"]+record["unresolved"])}''')
def finalize(folder,record):
    report=json.loads((folder/"validation/usdz.json").read_text());record["model"]["bounds_m"]=report["bounds_m"]
    arts=[]
    for role,path in [("authoring","models/fixture.blend"),("runtime","models/fixture.usdz"),("generator","models/build_fixture.py")]:arts.append(artifact(folder,role,path))
    for p in sorted((folder/"previews").glob("*.png")):arts.append(artifact(folder,"preview",p.relative_to(folder).as_posix()))
    arts.append(artifact(folder,"validation","validation/usdz.json"));record["model"]["artifacts"]=arts
    (folder/"fixture.json").write_text(json.dumps(record,indent=2,ensure_ascii=False)+"\n")
def main():
    ap=argparse.ArgumentParser();ap.add_argument("--only");ap.add_argument("--skip-downloads",action="store_true");a=ap.parse_args()
    dims=json.loads(MAP.read_text());rows=list(csv.DictReader(CSV.open()))
    seen=set(); updated=[]
    for row in rows:
        key=f"{row['manufacturer']}|{row['name']}";specdims=dims[key];mid=slug(row["manufacturer"]);fid=f"{mid}/{slug(row['name'])}"
        if a.only and a.only!=fid:updated.append(row);continue
        folder=ROOT/"assets/fixtures"/fid;folder.mkdir(parents=True,exist_ok=True)
        spec,record=record_for(row,specdims,folder,not a.skip_downloads);write_wrapper(folder,spec)
        (folder/"fixture.json").write_text(json.dumps(record,indent=2,ensure_ascii=False)+"\n")
        subprocess.run(["blender","--background","--python-exit-code","1","--python",str(folder/"models/build_fixture.py")],check=True)
        subprocess.run(["blender","--background","--python-exit-code","1","--python",str(CHECK),"--",str(folder/"fixture.json")],check=True)
        finalize(folder,record);write_note(folder,row,record)
        subprocess.run([sys.executable,str(LIB),"validate",str(folder/"fixture.json"),"--root",str(ROOT)],check=True)
        row.update({"asset_state":record["status"],"asset_root":folder.relative_to(ROOT).as_posix(),"fixture_record":(folder/"fixture.json").relative_to(ROOT).as_posix(),"fixture_note":(ROOT/"docs/08 Fixture Library/entries"/Path(fid+".md")).relative_to(ROOT).as_posix(),"blend_asset":(folder/"models/fixture.blend").relative_to(ROOT).as_posix(),"usdz_asset":(folder/"models/fixture.usdz").relative_to(ROOT).as_posix(),"validation_report":(folder/"validation/usdz.json").relative_to(ROOT).as_posix()})
        updated.append(row);seen.add(fid)
    if not a.only:
        fields=list(rows[0])+[x for x in ("asset_state","asset_root","fixture_record","fixture_note","blend_asset","usdz_asset","validation_report") if x not in rows[0]]
        with CSV.open("w",newline="") as f:w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(updated)
        subprocess.run([sys.executable,str(LIB),"index","--root",str(ROOT)],check=True)
    print(f"generated {len(seen)} fixture packages")
if __name__=="__main__":main()
