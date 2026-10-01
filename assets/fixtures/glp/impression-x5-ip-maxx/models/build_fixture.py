#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'glp/impression-x5-ip-maxx', 'width_m': 0.483, 'height_m': 0.64, 'depth_m': 0.358, 'profile': {'family': 'moving_wash', 'lens_count': 37, 'body_style': 'large IP65 moving wash head with 37 circular RGBL lenses', 'notes': '37 x 40 W RGBL pixel array; avoid using the similar non-IP impression X5 body.', 'baseless': True}, 'source_urls': ['https://glp.de/en/products/entertainment-lighting/moving-lights/impression-x5-ip-maxx-en', 'https://www2.glp.de/files/products/impression-x5-ip-maxx-product-data/GLP_impression_X5_IP_Maxx_Safety_Manual_EN_Rev20241007-1.pdf', 'https://www2.glp.de/files/products/impression-x5-ip-maxx-product-data/impression-X5-IP-Maxx_Datasheet_Rev20250430.pdf', 'https://glp.de/templates/yootheme/cache/c3/impressionX5IP_Header-c337f84c.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
