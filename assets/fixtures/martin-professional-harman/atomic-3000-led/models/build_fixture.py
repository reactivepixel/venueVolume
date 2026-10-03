#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/atomic-3000-led', 'width_m': 0.425, 'height_m': 0.245, 'depth_m': 0.24, 'profile': {'family': 'strobe', 'cells': 24}, 'source_urls': ['https://www.martin.com/en-US/products/atomic-3000-led/', 'https://www.martin.com/en-US/products/atomic-3000-led', 'https://adn.harmanpro.com/product_attachments/product_attachments/4860_1728940592/Atomic3000_0013_vert_medium.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
