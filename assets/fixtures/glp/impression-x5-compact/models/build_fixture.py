#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'glp/impression-x5-compact', 'width_m': 0.25, 'height_m': 0.337, 'depth_m': 0.183, 'profile': {'family': 'moving_wash', 'lens_count': 7, 'baseless': True}, 'source_urls': ['https://glp.de/de/produkte/entertainment-lighting/moving-lights/impression-x5-compact', 'https://glp.de/files/products/impression-x5-compact-product-data/GLP_impression-X5-Compact.pdf', 'https://glp.de/templates/yootheme/cache/dc/impression-X5-Compact_Header-dc0173b5.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
