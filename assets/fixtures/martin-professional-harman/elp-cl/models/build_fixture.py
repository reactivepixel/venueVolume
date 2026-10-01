#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/elp-cl', 'width_m': 0.259, 'height_m': 0.427, 'depth_m': 0.648, 'profile': {'family': 'profile', 'barrel_ratio': 0.43}, 'source_urls': ['https://www.martin.com/en-US/products/elp-cl', 'https://adn.harmanpro.com/productattachment/7028/product_attachment/x_large-7585204fdcb485b9e58a0edf39e1a50a.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
