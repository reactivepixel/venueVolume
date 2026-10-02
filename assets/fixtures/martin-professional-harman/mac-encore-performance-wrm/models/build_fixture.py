#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-encore-performance-wrm', 'width_m': 0.48, 'height_m': 0.74, 'depth_m': 0.452, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'LED profile moving head', 'notes': 'WRM warm-white variant; keep distinct from CLD and Encore Two.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.25, 'yoke_compression': 0.22}, 'source_urls': ['https://www.martin.com/en-US/products/mac-encore-performance-wrm.html', 'https://adn.harmanpro.com/productattachment/5009/product_attachment/x_large-f067900483bdc666afaa9a55a7f38df3.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
