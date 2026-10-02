#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'shehds/led-beam-spot-moving-head-150w', 'width_m': 0.27, 'height_m': 0.42, 'depth_m': 0.18, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'LED beam/spot moving head with large lens and yoke', 'notes': 'Exact SKU and official page gallery image verified. Product page includes manual-library link.'}, 'source_urls': ['https://shehds.com/products/new-arrival-led-beam-150w-good-moving-head-lighting', 'https://shehds.com/cdn/shop/files/f7d7c897f798fc44c391847188c3ac79.jpg?v=1752917692&width=416', 'https://shehds.com/cdn/shop/files/MG_4008_f7139f4f-c15c-4bf7-babd-4e14fb86c8e1.jpg?v=1752917692&width=416']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
