"""Correct the ADJ PAR's folded-pose dimensions using the official floor-pose drawing."""
import csv,hashlib,json,shutil
from build_detailed_catalog import ROOT,CSV,dump,fid,sync_csv
import generate_fixture_assets as base
ident='adj/7p-hex-ip';folder=ROOT/'assets/fixtures'/ident;path=folder/'fixture.json';r=json.loads(path.read_text())
dest=folder/'sources/7p-hex-ip-manual.pdf'
if not dest.exists():shutil.copy2('/tmp/7p-hex-manual.pdf',dest)
url='https://www.adj.eu/mwdownloads/download/link/id/1178'
source={'id':'floor-pose-drawing','url':url,'title':'ADJ 7P HEX IP manual','kind':'manufacturer_drawing','accessed_at':'2026-09-30','document_revision':None,'locator':'Printed p.23, PDF p.24: floor-pose side and rear drawings; folded pose shown separately below','reuse_status':'reference_only','file':dest.relative_to(folder).as_posix(),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()}
r['sources']=[s for s in r['sources'] if s['id']!=source['id']]+[source]
note='Floor-standing split-yoke drawing: W256 mm across knobs, H234.8 mm side-view maximum, D170.4 mm floor feet. Product-page 256 x 161.7 x 232.5 mm combines a different folded bracket pose.'
pose='Floor-standing split-yoke pose, optical axis horizontal'
for k,v in [('width',.256),('height',.2348),('depth',.1704)]:r['dimensions'][k].update(value=v,status='documented',source_ids=[source['id']],note=note)
r['dimensions']['reference_pose']=pose;r['model']['reference_pose']=pose
r['model']['assumptions']=[a for a in r['model']['assumptions'] if 'runtime X/Y/Z uses W/H/L' not in a]+[note]
r['revision_notes']=list(dict.fromkeys(r['revision_notes']+['Official drawing review corrected the 7P HEX IP floor-pose width, height and depth.']))
dump(path,r)
dims=json.loads(base.MAP.read_text());dims['ADJ|7P HEX IP']={'width_m':.256,'height_m':.2348,'depth_m':.1704,'axis_status':'documented','axis_note':note,'reference_pose':pose};dump(base.MAP,dims)
rows=list(csv.DictReader(CSV.open()))
for row in rows:
    if fid(row)==ident:
        data=json.loads(row['data']);data['model_dimensions']=dims['ADJ|7P HEX IP'];data['dimension_drawing_url']=url;row['data']=json.dumps(data,ensure_ascii=False)
sync_csv(rows)
