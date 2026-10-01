#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'elation-professional/sixbar-1000', 'width_m': 0.9, 'height_m': 0.155, 'depth_m': 0.2064, 'profile': {'family': 'batten', 'lens_count': 12}, 'source_urls': ['https://www.elationlighting.com/products/sixbar-1000', 'https://www.elationlighting.com/cdn/shop/files/e9bbd10c55a2546928e84a0f850337a4b52835bf_SIX086__IMG__001__4d03a9ebf964.jpg?v=1776815102&width=850']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
