#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'glp/impression-x5-bar-1000', 'width_m': 1.0, 'height_m': 0.296, 'depth_m': 0.11, 'profile': {'family': 'batten', 'lens_count': 18, 'tilting': True}, 'source_urls': ['https://glp.de/en/products/entertainment-lighting/moving-lights/impression-x5-bar-1000-en', 'https://glp.de/templates/yootheme/cache/96/impression-X5-Bar-1000_Header12-96c4ac35.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
