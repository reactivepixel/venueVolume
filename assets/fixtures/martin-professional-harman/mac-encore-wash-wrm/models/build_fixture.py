#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-encore-wash-wrm', 'width_m': 0.48, 'height_m': 0.755, 'depth_m': 0.452, 'profile': {'family': 'moving_wash', 'lens_count': 1, 'body_style': 'soft-edge moving head', 'notes': 'WRM variant; verify front optic assembly from exact-model imagery before modeling.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.2, 'fresnel': True, 'yoke_compression': 0.22}, 'source_urls': ['https://www.martin.com/en-US/products/mac-encore-wash-wrm.html', 'https://adn.harmanpro.com/productattachment/5552/product_attachment/x_large-502998efe863913cf2b4f66a46ab0fb9.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
