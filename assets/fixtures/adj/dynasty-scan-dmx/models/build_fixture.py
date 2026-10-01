#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/dynasty-scan-dmx', 'width_m': 0.185, 'height_m': 0.195, 'depth_m': 0.46, 'profile': {'family': 'scanner', 'body_style': 'compact rectangular lamp housing with front lens and oscillating mirror', 'notes': 'Discontinued; scanner mirror rather than moving-head yoke.', 'generator': 'equipment', 'output_kind': 'light'}, 'source_urls': ['https://www.adj.com/products/dynasty-scan-dmx', 'https://www.adj.com/cdn/shop/files/8e8fdf896b7c324fb4ba06faa15832d3cfda9d95_DYNASTY_SCAN__IMG__001__4532095281c8.jpg?v=1776714362&width=2048']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
