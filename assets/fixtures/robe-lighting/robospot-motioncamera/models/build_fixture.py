#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/robospot-motioncamera', 'width_m': 0.277, 'height_m': 0.386, 'depth_m': 0.147, 'profile': {'family': 'tracking_camera', 'body_style': 'compact moving-head camera with integrated zoom optics, yoke and base adaptor', 'notes': 'Camera-head visual reference only; no tracking algorithm, video-network or BaseStation geometry is represented. Treat as optional video/followspot-system expansion until broader scope is approved.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.robelighting.com/robospot-motioncamera', 'https://www.robelighting.com/res/downloads/catalogues/ROBE_Product_Guide_2021.pdf', 'https://cdn.aws.robe.cz/v1/image/resize/8a9cbc417b51763a20041409849a29deda12302d?width=904&height=904&fit=cover&withoutEnlargement=false']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
