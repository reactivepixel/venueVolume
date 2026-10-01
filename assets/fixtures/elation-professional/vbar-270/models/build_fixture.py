#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'elation-professional/vbar-270', 'width_m': 0.25, 'height_m': 0.212, 'depth_m': 0.093, 'profile': {'family': 'batten', 'lens_count': 270, 'body_style': 'legacy short linear RGB bar with dense 5 mm LED array and mounting bracket', 'notes': '270 LEDs (90 each red, green, blue) documented. Manufacturer calls product discontinued.', 'pixel_grid': True, 'overhead_yoke': True}, 'source_urls': ['https://www.elationlighting.com/products/vbar-270', 'https://www.elationlighting.com/cdn/shop/files/ce8c991f5538b2029d5b0af1fd01d1cc6e288ebc_VBAR_270__IMG__001__bc8a52e62396.jpg?v=1776815895&width=500']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
