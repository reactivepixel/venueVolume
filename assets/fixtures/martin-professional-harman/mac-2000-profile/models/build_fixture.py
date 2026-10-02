#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-2000-profile', 'width_m': 0.49, 'height_m': 0.743, 'depth_m': 0.408, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'large discharge profile moving head', 'notes': 'Keep original Profile distinct from Profile II; ballast variants affect mass, not documented outer dimensions.'}, 'source_urls': ['https://www.martin.com/en-US/products/mac-2000-profile', 'https://adn.harmanpro.com/product_attachments/product_attachments/6130_1728121020/mac-2000-profile_x_large.webp', 'https://adn.harmanpro.com/product_attachments/product_attachments/6130_1728121020/mac-2000-profile_x_large.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
