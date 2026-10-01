#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'glp/jdc1', 'width_m': 0.39, 'height_m': 0.251, 'depth_m': 0.15, 'profile': {'family': 'strobe', 'tilting': True, 'cells': 24}, 'source_urls': ['https://glp.de/en/products/entertainment-lighting/strobes/jdc1-en?ic=1', 'https://glp.de/files/products/jdc1-product-data/GLP_JDC1_User_Manual_EN_Rev20240830-01.pdf', 'https://glp.de/templates/yootheme/cache/83/JDC1_1-83eb9208.jpeg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
