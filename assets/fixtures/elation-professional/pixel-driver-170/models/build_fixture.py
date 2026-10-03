#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'elation-professional/pixel-driver-170', 'width_m': 0.101, 'height_m': 0.05, 'depth_m': 0.0262, 'profile': {'family': 'pixel_driver', 'body_style': 'rectangular DMX-to-pixel controller with display, terminal blocks and slotted mounting tabs', 'notes': 'Separate DC supply required; driver is not itself an emitter.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.elationlighting.com/products/pixel-driver-170', 'https://www.elationlighting.com/products/pixel-tape-16ip', 'https://www.elationlighting.com/cdn/shop/files/e09856f207a5349be7eb1cb57d0dab9e1b04f8c9_PIX170__IMG__001__35eed3f29864.jpg?v=1776815686&width=2048']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
