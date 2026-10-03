#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-aura-raven-xip', 'width_m': 0.429, 'height_m': 0.603, 'depth_m': 0.285, 'profile': {'family': 'moving_wash', 'lens_count': 37, 'body_style': 'large outdoor Aura wash head with forward beam and Aura pixel arrays', 'notes': 'Model 37 main beam emitters across the forward face plus a separate 234-element RGB Aura backlight array; no rear video display is specified.', 'generator': 'catalog', 'aura_pixels': 234, 'yoke_compression': 0.18}, 'source_urls': ['https://www.martin.com/en-US/products/mac-aura-raven-xip', 'https://adn.harmanpro.com/productattachment/12797/product_attachment/x_large-c5fd37cb61ca8d844c5298005092457a.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
