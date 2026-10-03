#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-encore-two', 'width_m': 0.479, 'height_m': 0.776, 'depth_m': 0.596, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'LED profile moving head', 'notes': "Asymmetric across-yoke width/depth use Martin's listed fixture envelope axes; preserve official CAD silhouette.", 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.2, 'yoke_compression': 0.22}, 'source_urls': ['https://www.martin.com/en-US/products/mac-encore-two', 'https://adn.harmanpro.com/productattachment/13804/product_attachment/x_large-f4b421de0df9f555d4e46bcbff7105cd.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
