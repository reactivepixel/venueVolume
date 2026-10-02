#!/usr/bin/env python3
"""Reproduce the reviewed JB-Lighting / Chroma-Q source acquisition batch."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
items=[]

def add(name,sku,maker,url,images,size,power,weight,protocols,profile,note,axis='documented'):
    items.append(dict(name=name,model_number=sku,manufacturer=maker,type='moving light' if profile['family'].startswith('moving_') else 'LED wash',
        subtype='pixel wash' if profile['family']=='moving_wash' else ('framing profile' if profile['family']=='moving_spot' else 'cyc / wash batten'),
        url=url,images=images,data=dict(protocols=protocols,dmx_channels=[],power=power,weight=weight,notable=note,source_urls=[url]),
        dimensions=dict(width_m=size[0],height_m=size[1],depth_m=size[2],axis_status=axis,
            axis_note='Manufacturer mechanical specifications; optical-forward neutral pose and detail proportions are image-informed estimates.',
            reference_pose='Base level, optical axis forward; listed assembled envelope normalized to visualization neutral pose, not a swept movement envelope.'),
        modeling=profile,evidence=[dict(url=url,title=maker+' '+name+' specifications',locator='Mechanical / electrical specifications and control; exact-model product gallery',
            accessed_at='2026-10-02',source_kind='manufacturer_product')]))

jb='https://www.jb-lighting.de'
for name,route,size,weight,power,lenses,images in [
 ('Sparx 12','Sparx12',(.404,.491,.265),'15.5 kg','750 VA max',19,['Sparx12_seitlich_min_Zoom.png','Sparx12_nach_oben_geschwenkt.png','Sparx12_Anschlusspanel.png']),
 ('Sparx 18','Sparx18',(.481,.580,.308),'22 kg','1300 VA max',37,['Sparx18_seitlich.png','Sparx18_Kopf_oben.png','Sparx18_von_hinten.png']),
 ('Sparx 30','Sparx30',(.530,.628,.308),'28.4 kg','2200 VA max',61,['Sparx30_seitlich.png','Sparx30_nach_oben.png','Sparx30_Backside.png'])]:
    add(name,name,'JB-Lighting',jb+'/en/'+route,[jb+'/images/products/'+route+'/'+x for x in images],size,power+'; 100–240 V 50/60 Hz',weight,
        ['DMX512','RDM','Art-Net','sACN','Kling-Net','CRMX'],dict(family='moving_wash',shell='round',lens_count=lenses,lens_ratio=.9,head_depth=.55),
        f'{lenses} RGBW 40 W LEDs; independently controlled inner/outer TwinZoom optics. Internal zoom mechanism and beam-shape accessory are not modeled.')
add('P18 Profile MK2 HP','P18 Profile MK2 HP','JB-Lighting',jb+'/en/P18Profile',
    [jb+'/images/products/P18/'+s for s in ('P18_seitlich_MK2.png','P18_backside_MK2.png','P18_frontal_MK2.png')],
    (.475,.755,.307),'1500 VA max; 100–240 V 50/60 Hz','32 kg',['DMX512','RDM','Art-Net','sACN','CRMX'],
    dict(family='moving_spot',shell='faceted',lens_ratio=.65,head_depth=.88),
    'HP variant: 1100 W white LED module, 6800 K, CRI >=70, 40000 lm output; framing system. HC source variant is not conflated with HP.')

for length,size,weight,power,image,lenses in [
 (12,(.335,.218,.190),'5 kg','133 W','72/d9/2051c3ed2e2fb2fd36db9cf034a1.jpeg',4),
 (48,(1.181,.191,.165),'18 kg','533 W','12/cd/6788b53503465a4bbdbf64bb60ab.jpeg',16),
 (72,(1.759,.191,.165),'24 kg','800 W','3c/3b/783a4f1fc7d01481a9a4fd10c7b6.jpeg',24)]:
    add(f'Color Force II {length}',f'CHCF2{length}RGBA','Chroma-Q',f'https://chroma-q.com/products/color-force-ii-{length}',
        ['https://chroma-q.com/media/cache/app_top_hero/'+image],size,power+' at 120/240 V; 100–240 V input',weight,['DMX512-A'],
        dict(family='batten',lens_count=lenses,diffuser=True,manual_tilt=True),
        'Legacy black wired-DMX RGBA variant; IP20; separately controllable 76 mm color cells. Manual bracket focus only; optional diffusion and wireless variants not included.',axis='estimated')
add('Color Force 3 72','CQ1530-7200','Chroma-Q','https://chroma-q.com/products/color-force-3-72',
    ['https://chroma-q.com/media/cache/app_top_hero/1b/63/541e6aee1d2fc564aed8e47ae239.jpeg'],
    (1.785,.215,.180),'1100 W; 100–240 V 50/60 Hz','35 kg',['DMX512-A','Art-Net','sACN','RDM'],
    dict(family='batten',generator='catalog',lens_count=24,diffuser=True,sparkle_pixels=48,manual_tilt=True),
    'Black wired variant; 24 RGBA cells plus 48 SparQle LEDs; IP65; manual ±120° focus. Rectangular cells and two accent-pixel banks have separate geometry; detail proportions and pivot are estimated.',axis='estimated')
sgm='https://www.sgmlighting.com'
add('G-4 Wash','G-4 Wash','SGM',sgm+'/products/g%C2%B74-wash',
    [sgm+'/files/images/perfion/G4%20Wash_STD-Discontinued%20Products.png'],
    (.255,.465,.219),'250 W max; 100–240 V 50/60 Hz','10 kg',['DMX512-A','RDM','CRMX','W-DMX'],
    dict(family='moving_wash',shell='round',lens_count=1,fresnel=True,head_depth=.6),
    'Legacy IP65 RGBAM Fresnel wash; 220° tilt and endless pan; physical 219 L × 465 H × 255 W mm. Preview uses illustrative travel, not a manufacturer control personality.')
items[-1]['data']['dmx_channels']=[18]
add('G-7 Spot','G-7 Spot','SGM',sgm+'/products/architecture/g%C2%B77-spot',
    [sgm+'/files/images/perfion/G7Spot_STD_Discontinued%20Products.png'],
    (.370,.622,.433),'480 W max','27 kg',['DMX512-A','RDM','CRMX','W-DMX'],
    dict(family='moving_spot',shell='faceted',lens_count=1,lens_ratio=.65,head_depth=.86),
    'Legacy standard touring-base variant, not POI; manufacturer physical table 433 L × 622 H × 370 W mm. 22/29 channel modes; optics and output remain illustrative.')
items[-1]['data']['dmx_channels']=[22,29]
path=ROOT/'research/fixtures/expansion-v2/specialists.json'
path.write_text(json.dumps(items,ensure_ascii=False,indent=2)+'\n')
print(f'{len(items)} sourced specialist models')
