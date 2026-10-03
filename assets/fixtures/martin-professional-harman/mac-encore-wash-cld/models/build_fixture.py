#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-encore-wash-cld', 'width_m': 0.48, 'height_m': 0.755, 'depth_m': 0.452, 'profile': {'family': 'moving_wash', 'lens_count': 1, 'body_style': 'soft-edge moving head', 'notes': 'CLD variant; verify front optic assembly from exact-model imagery before modeling.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.2, 'fresnel': True, 'yoke_compression': 0.22}, 'source_urls': ['https://www.martin.com/en-US/products/mac-encore-wash-cld.html', 'https://adn.harmanpro.com/productattachment/5561/product_attachment/x_large-405323454e3e7cca83aef032adab4ef8.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
