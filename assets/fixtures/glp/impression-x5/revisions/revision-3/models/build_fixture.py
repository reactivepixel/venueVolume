#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'glp/impression-x5', 'width_m': 0.415, 'height_m': 0.434, 'depth_m': 0.29, 'profile': {'family': 'moving_wash', 'lens_count': 19, 'baseless': True}, 'source_urls': ['https://glp.de/en/products/entertainment-lighting/moving-lights/impression-x5-en', 'https://glp.de/templates/yootheme/cache/a9/impression-X5_Header-a92366da.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
