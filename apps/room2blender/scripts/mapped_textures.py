"""Reproducible photo-detail tiles; deliberately not a photogrammetric albedo solve."""
from pathlib import Path
import hashlib
import json
import cv2
import numpy as np
from PIL import Image

APP = Path(__file__).resolve().parents[1]
# Pixel crops reviewed against the original 1600x900 reference frames. No objects,
# trim, lights, perspective landmarks or recognisable shadows inside these crops.
RECIPES = [
    ('carpet', 'Carpet / procedural gray weave', 'reference_04_0070.0s.jpg', [600,440,1200,860], [0.18,0.17,0.16], 512, .09, .8),
    ('sage', 'Paint / sage green', 'reference_04_0070.0s.jpg', [520,30,950,225], [.43,.51,.36], 256, .008, 1.2),
    ('ivory', 'Paint / warm ivory', 'reference_02_0022.0s.jpg', [430,220,1000,550], [.66,.61,.46], 256, .008, 1.2),
    ('ceiling', 'Acoustic ceiling / off white', 'reference_08_0177.0s.jpg', [330,20,530,130], [.68,.68,.63], 512, .045, .61),
    ('maple', 'Desk / pale maple', 'reference_05_0100.0s.jpg', [480,837,880,892], [.60,.39,.17], 256, .025, .6),
    ('laminate', 'Table / light laminate', 'reference_02_0022.0s.jpg', [475,735,705,760], [.73,.71,.64], 256, .004, .6),
]


def main():
    folder = APP/'mappedRoom/textures'
    folder.mkdir(parents=True, exist_ok=True)
    records = []
    for name, material, frame, crop, color, size, strength, repeat in RECIPES:
        source = APP/'references'/frame
        pixels = np.asarray(Image.open(source).convert('RGB').crop(crop)).astype(np.float32)/255
        # Linear light: remove low-frequency illumination and hue casts. Match the
        # original reviewed material's mean reflectance for a useful A/B comparison.
        linear = np.where(pixels <= .04045, pixels/12.92, ((pixels+.055)/1.055)**2.4)
        luminance = linear @ np.array([.2126,.7152,.0722], dtype=np.float32)
        blurred = cv2.GaussianBlur(luminance, (0,0), sigmaX=max(3,min(luminance.shape)/10))
        detail = luminance/np.maximum(blurred,.005)-1
        detail = cv2.resize(detail, (size//2,size//2), interpolation=cv2.INTER_AREA)
        detail = np.concatenate([detail, detail[:,::-1]], axis=1)
        detail = np.concatenate([detail, detail[::-1]], axis=0)
        detail -= detail.mean()
        detail = np.clip(detail/max(float(detail.std()),.0001)*strength, -strength*3, strength*3)
        detail -= detail.mean()
        albedo = np.clip(np.array(color)*(1+detail[...,None]),0,1)
        srgb = np.where(albedo <= .0031308, albedo*12.92, 1.055*albedo**(1/2.4)-.055)
        target = folder/(name+'.png')
        Image.fromarray(np.rint(srgb*255).astype(np.uint8)).save(target, optimize=True)
        records.append(dict(material=material,file=target.name,source='references/'+frame,
                            sourceSHA256=hashlib.sha256(source.read_bytes()).hexdigest(),cropPixels=crop,
                            size=[size,size],repeatMeters=repeat,linearMean=color,detailStd=strength,
                            sha256=hashlib.sha256(target.read_bytes()).hexdigest()))
    report = dict(method='reviewed crop, linear luminance high-pass, restrained contrast, mirrored repeat, sRGB encoding',
                  limitations='Approximate photo-derived surface detail. Not camera projection, measured albedo, or de-lighting ground truth. Scale remains provisional.',
                  textures=records,estimatedRGBA8WithMipBytes=sum(r['size'][0]*r['size'][1]*4*4//3 for r in records))
    (folder.parent/'texture-provenance.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))

if __name__ == '__main__': main()
