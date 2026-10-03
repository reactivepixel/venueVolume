#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'acme/lightning', 'width_m': 0.483, 'height_m': 0.224, 'depth_m': 0.212, 'profile': {'family': 'strobe', 'strip': True, 'cells': 30, 'body_style': 'IP66 pixel strobe/wash panel with side and top camlock joinery', 'notes': 'One cool-white beam emitter centered in each of 30 RGBW sections; housing has integrated yoke and matrix-joining hardware.', 'generator': 'catalog', 'matrix_cells': True, 'overhead_yoke': True, 'manual_tilt': True}, 'source_urls': ['https://en.acmelighting.com/item/LIGHTNING', 'https://en.acmelighting.com/upload/image/20250113/2dca5f7c2c24d4cefba4178a862171ec.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
