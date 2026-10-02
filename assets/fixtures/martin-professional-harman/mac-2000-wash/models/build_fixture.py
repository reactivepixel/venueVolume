#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-2000-wash', 'width_m': 0.49, 'height_m': 0.75, 'depth_m': 0.408, 'profile': {'family': 'moving_wash', 'lens_count': 1, 'body_style': 'large discharge wash moving head', 'notes': 'Manufacturer lists PC, Fresnel and super-wide lens options as included; micro-Fresnel is optional.'}, 'source_urls': ['https://www.martin.com/en-US/products/mac-2000-wash', 'https://adn.harmanpro.com/product_attachments/product_attachments/6139_1728120883/mac-2000-wash_x_large.webp', 'https://adn.harmanpro.com/product_attachments/product_attachments/6139_1728120883/mac-2000-wash_x_large.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
