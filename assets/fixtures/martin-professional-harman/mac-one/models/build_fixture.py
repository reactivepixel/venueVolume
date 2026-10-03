#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-one', 'width_m': 0.254, 'height_m': 0.349, 'depth_m': 0.22, 'profile': {'family': 'moving_wash', 'lens_count': 1, 'aura': True}, 'source_urls': ['https://www.martin.com/en-US/products/mac-one', 'https://adn.harmanpro.com/productattachment/12285/product_attachment/x_large-d19708df6ba03b2c31e7e4119c02b81b.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
