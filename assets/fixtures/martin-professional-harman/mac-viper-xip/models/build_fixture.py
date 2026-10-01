#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-viper-xip', 'width_m': 0.479, 'height_m': 0.776, 'depth_m': 0.595, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.73, 'head_depth': 0.86}, 'source_urls': ['https://www.martin.com/en-US/products/mac-viper-xip', 'https://adn.harmanpro.com/productattachment/12248/product_attachment/x_large-5847804c23b1f2f05fd8d8e5c6c9e674.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
