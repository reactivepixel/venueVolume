#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-aura-xip', 'width_m': 0.338, 'height_m': 0.421, 'depth_m': 0.226, 'profile': {'family': 'moving_wash', 'lens_count': 7, 'aura': True}, 'source_urls': ['https://www.martin.com/en-US/products/mac-aura-xip', 'https://www.martin.com/en-US/site_elements/mac-aura-xip-spec-sheet', 'https://adn.harmanpro.com/productattachment/11621/product_attachment/x_large-b71745e5ebf2bb2d999d386e8a146768.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
