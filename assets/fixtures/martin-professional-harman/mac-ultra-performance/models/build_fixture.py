#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-ultra-performance', 'width_m': 0.52, 'height_m': 0.876, 'depth_m': 0.66, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.84, 'head_depth': 0.9}, 'source_urls': ['https://www.martin.com/en-US/products/mac-ultra-performance', 'https://www.martin.com/en-US/site_elements/martin-specifications-mac-ultra-performance-spec-sheet', 'https://adn.harmanpro.com/productattachment/10081/product_attachment/x_large-e6a233739fa59758d3debd9dd6ca02fb.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
