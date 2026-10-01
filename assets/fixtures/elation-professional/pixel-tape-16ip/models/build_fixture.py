#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'elation-professional/pixel-tape-16ip', 'width_m': 2.72, 'height_m': 0.003, 'depth_m': 0.012, 'profile': {'family': 'pixel_strip', 'body_style': 'flexible conformal-coated strip with 170 RGB pixel packages', 'notes': 'External driver dependency explicit; 2.72 m module geometry.', 'generator': 'equipment', 'output_kind': 'light'}, 'source_urls': ['https://www.elationlighting.com/products/pixel-tape-16ip', 'https://www.elationlighting.com/cdn/shop/files/e25056689bf3c664c3ecf2633beaa478799b3ad2_PIX618__IMG__001__9fcf5d2d87a2.jpg?v=1776815651&width=2048']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
