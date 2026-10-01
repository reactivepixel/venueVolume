"""Create labeled contact sheets from source images or generated views."""
import argparse, csv, json, subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--sources',action='store_true');p.add_argument('--batch',type=int);p.add_argument('--view',default='three-quarter',choices=['front','side','rear','three-quarter']);a=p.parse_args()
selected={r['asset_root'] for r in csv.DictReader((ROOT/'assets/fixtures/research/major-manufacturer-fixtures.csv').open()) if not a.batch or str(r.get('expansion_batch'))==str(a.batch)}
out=ROOT/'assets/fixtures/research/review';out.mkdir(exist_ok=True)
groups={}
for path in sorted((ROOT/'assets/fixtures').glob('*/*/fixture.json')):
    r=json.loads(path.read_text());key=path.parent.parent.name
    if str(path.parent.relative_to(ROOT)) not in selected:continue
    if a.sources:
        paths=[path.parent/s['file'] for s in r['sources'] if s.get('file') and Path(s['file']).suffix.lower() in ['.png','.jpg','.jpeg','.webp']]
    else:paths=[path.parent/'previews'/f'{a.view}.png']
    if paths and paths[0].exists():groups.setdefault(key,[]).append((r['identity']['model'],paths[0]))
for key,rows in groups.items():
    cmd=['magick','montage','-font','/usr/share/fonts/noto/NotoSans-Regular.ttf','-pointsize','14','-background','#eeeeee','-fill','#111111']
    for name,path in rows:cmd+=['-label',name,str(path)]
    cmd+=['-thumbnail','240x240','-geometry','260x270+8+8','-tile','3x',str(out/(key+('-sources' if a.sources else '-models')+('' if a.view=='three-quarter' else '-'+a.view)+(f'-batch{a.batch}' if a.batch else '')+'.jpg'))]
    subprocess.run(cmd,check=True)
print('Sheets:',len(groups))
