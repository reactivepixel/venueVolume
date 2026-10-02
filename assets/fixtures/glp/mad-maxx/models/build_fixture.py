#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'glp/mad-maxx', 'width_m': 1.043, 'height_m': 1.057, 'depth_m': 0.789, 'profile': {'family': 'moving_wash', 'lens_count': 19, 'body_style': 'oversized yoke-mounted multisource fat-beam fixture', 'notes': 'Nonstandard 19-beam array and extraordinary scale. Current moving_wash geometry is not an exact oversized fat-beam profile; preserve individual large front emitters, high yoke and alternate head-up envelope, and expect custom dimensions/modeling. Mass conflict between page and datasheet remains explicit.', 'generator': 'catalog', 'head_depth': 0.78, 'base_height': 0.12, 'large_head': True}, 'source_urls': ['https://glp.de/en/products/entertainment-lighting/moving-lights/mad-maxx-en', 'https://glp.de/en/component/content/article/mad-maxx-cw-product-data', 'https://glp.de/files/products/mad-maxx-cw-product-data/Mad-Maxx_Datasheet-Rev20251128.pdf', 'https://glp.de/images/products/MadMaxx/MadMaxx_Header.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
