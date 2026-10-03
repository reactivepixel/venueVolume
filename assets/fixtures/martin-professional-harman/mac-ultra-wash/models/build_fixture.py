#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-ultra-wash', 'width_m': 0.52, 'height_m': 0.867, 'depth_m': 0.642, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.89, 'head_depth': 0.88, 'fresnel': True}, 'source_urls': ['https://www.martin.com/en-US/products/mac-ultra-wash', 'https://adn.harmanpro.com/productattachment/10090/product_attachment/x_large-8dcc99537c848fc1e113c0b4a0ac2458.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
