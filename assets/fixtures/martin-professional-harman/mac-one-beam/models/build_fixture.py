#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-one-beam', 'width_m': 0.254, 'height_m': 0.35, 'depth_m': 0.233, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'compact beam head with rear lens light-guide array', 'notes': 'Light guides are individually addressable; nonstandard optic details need dedicated model research.', 'generator': 'catalog', 'shell': 'round', 'head_depth': 0.55, 'light_guide_rings': True, 'lens_ratio': 0.45}, 'source_urls': ['https://www.martin.com/en-US/products/mac-one-beam', 'https://adn.harmanpro.com/productattachment/13642/product_attachment/x_large-e7dbe56ff717256b1331ad23914f76ad.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
