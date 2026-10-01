"""Apply reviewed source-identity corrections; keep original bytes in Git history."""
import csv,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
CSV=ROOT/'assets/fixtures/research/major-manufacturer-fixtures.csv'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,r):p.write_text(json.dumps(r,indent=2,ensure_ascii=False)+'\n')
new={
 'etc/desire-d60':'https://www.etcconnect.com/uploadedImages/Main_Site/Images/Products/Lighting_Fixtures/Selador/D60_Lustr_clip.jpg',
 'etc/fos-4-fresnel':'https://www.etcconnect.com/uploadedImages/Main_Site/Images/Products/Entertainment_Fixtures/fos4_Fresnel_Group_960x350.jpg',
 'vari-lite/vl5led-wash':'https://www.vari-lite.com/b-dam/vari-lite/products/vl5led-wash/VL5LED-WASH_thumbnail.jpg'
}
for ident,url in new.items():
 folder=ROOT/'assets/fixtures'/ident;p=folder/'fixture.json';r=json.loads(p.read_text());image=folder/'sources/official-product-image.jpg'
 if not any(s['id']=='reviewed-image' for s in r['sources']):
  r['sources'].append({'id':'reviewed-image','url':url,'title':r['identity']['model']+' reviewed manufacturer reference','kind':'manufacturer_asset','accessed_at':'2026-09-30','document_revision':None,'locator':'Official product image; fos/4 family image depicts multiple aperture sizes','reuse_status':'reference_only','file':'sources/official-product-image.jpg','sha256':sha(image)})
 r['unresolved']=[x for x in r['unresolved'] if 'No official product image' not in x]
 if ident.endswith('vl5led-wash'):r['sources'][0]['url']='https://www.vari-lite.com/global/products/v5led-wash'
 dump(p,r)
# The two manufacturer CDN images were assigned to the opposite fixtures.
ids=['robe-lighting/pointe','robe-lighting/spiider'];recs=[json.loads((ROOT/'assets/fixtures'/i/'fixture.json').read_text()) for i in ids]
if not all(r.get('source_identity_corrected') for r in recs):
 sources=[next(s for s in r['sources'] if s['id']=='official-image') for r in recs]
 bytes_=[(ROOT/'assets/fixtures'/i/s['file']).read_bytes() for i,s in zip(ids,sources)]
 urls=[s['url'] for s in sources]
 for n,(ident,r) in enumerate(zip(ids,recs)):
  s=next(s for s in r['sources'] if s['id']=='official-image');path=ROOT/'assets/fixtures'/ident/s['file'];path.write_bytes(bytes_[1-n]);s['url']=urls[1-n];s['sha256']=sha(path)
  r['source_identity_corrected']=True;r['revision_notes'].append('Corrected swapped Pointe/Spiider manufacturer reference image assignment after visual inspection.');dump(ROOT/'assets/fixtures'/ident/'fixture.json',r);new[ident]=s['url']
# V and V MAX share housing parts, but the old image must be labeled as a family reference.
p=ROOT/'assets/fixtures/etc/colorsource-fresnel-v/fixture.json';r=json.loads(p.read_text())
for s in r['sources']:
 if s['id']=='official-image':s['title']='ColorSource Fresnel V MAX family reference; shared outer housing';s['locator']='Family silhouette only; image labels V MAX, not the catalogued V engine'
if not any(s['id']=='shared-housing-evidence' for s in r['sources']):r['sources'].append({'id':'shared-housing-evidence','url':'https://support.etcconnect.com/ETC/Repair_and_Service_Center/LED_Fixtures/ColorSource_Fresnel_V_and_MAX_Service_Guides/ColorSource_Fresnel_V_and_MAX_Exploded_Diagrams','title':'ColorSource Fresnel V and V MAX shared outer body parts','kind':'manufacturer_manual','accessed_at':'2026-09-30','document_revision':None,'locator':'Yoke and outer body; Top casing','reuse_status':'reference_only'})
r['model']['assumptions'].append('V MAX image used only for shared outer housing, supported by ETC shared-parts documentation; V engine specifications remain separate.');r['model']['assumptions']=list(dict.fromkeys(r['model']['assumptions']));dump(p,r)
rows=list(csv.DictReader(CSV.open()))
for row in rows:
 ident=row['asset_root'].removeprefix('assets/fixtures/')
 if ident in new:row['images']=json.dumps([new[ident]])
 if ident=='vari-lite/vl5led-wash':row['url']='https://www.vari-lite.com/global/products/v5led-wash'
with CSV.open('w',newline='') as f:w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)
print('Corrected sources and CSV references')
