#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-viper-performance', 'width_m': 0.472, 'height_m': 0.731, 'depth_m': 0.566, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'discharge moving head with framing module, yoke', 'notes': 'Estimate uses documented head-straight-up height, maximum width, and head length. Do not read as the bounding box from one manufacturer-dimensioned pose.'}, 'source_urls': ['https://www.martin.com/en-US/products/mac-viper-performance', 'https://adn.harmanpro.com/product_attachments/product_attachments/4794_1728940667/macviperperformance_x_large.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
