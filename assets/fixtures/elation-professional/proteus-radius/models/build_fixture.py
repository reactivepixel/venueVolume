#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'elation-professional/proteus-radius', 'width_m': 0.395, 'height_m': 0.516, 'depth_m': 0.27, 'profile': {'family': 'moving_spot', 'shell': 'round', 'lens_ratio': 0.82, 'head_depth': 0.79}, 'source_urls': ['https://www.elationlighting.com/products/proteus-radius', 'https://www.elationlighting.com/cdn/shop/files/8a816888b19c597ff679c5fcb47dd7fcb4a0d392_PRD013__IMG__001__0d483618ed34.png?v=1776814959&width=1200']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
