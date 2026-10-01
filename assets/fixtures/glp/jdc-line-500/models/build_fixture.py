#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'glp/jdc-line-500', 'width_m': 0.507, 'height_m': 0.074, 'depth_m': 0.2015, 'profile': {'family': 'strobe', 'strip': True, 'cells': 24}, 'source_urls': ['https://glp.de/de/produkte/entertainment-lighting/strobes/jdc-line-500', 'https://glp.de/files/products/jdc-line-500-product-data/GLP_JDC-Line.pdf', 'https://glp.de/templates/yootheme/cache/a5/JDC-Line-500_Header-a55722e1.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
