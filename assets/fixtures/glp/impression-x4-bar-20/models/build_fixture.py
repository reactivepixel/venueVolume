#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'glp/impression-x4-bar-20', 'width_m': 1.0, 'height_m': 0.24, 'depth_m': 0.1, 'profile': {'family': 'batten', 'lens_count': 20, 'tilting': True}, 'source_urls': ['https://glp.de/en/products/discontinued/impression-x4-bar-20-en', 'https://glp.de/templates/yootheme/cache/86/impression-X4-Bar-20_Header-869049ce.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
