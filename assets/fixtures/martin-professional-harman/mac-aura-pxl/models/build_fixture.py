#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-aura-pxl', 'width_m': 0.41, 'height_m': 0.544, 'depth_m': 0.232, 'profile': {'family': 'moving_wash', 'lens_count': 19, 'body_style': 'medium pixel wash head with secondary Aura ring', 'notes': '19 beam lenses and 141 individually controlled Aura pixels; retain beam and Aura zones separately.', 'generator': 'catalog', 'aura_pixels': 141, 'yoke_compression': 0.2}, 'source_urls': ['https://www.martin.com/en-US/products/mac-aura-pxl', 'https://www.martin.com/en-US/site_elements/martin-mac-aura-pxl-user-safety-and-installation-manual', 'https://adn.harmanpro.com/productattachment/11973/product_attachment/x_large-405d2e500f88a8f703df7ab87a842f65.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
