#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'martin-professional-harman/mac-aura', 'width_m': 0.302, 'height_m': 0.36, 'depth_m': 0.302, 'profile': {'family': 'moving_wash', 'lens_count': 19, 'body_style': '19-lens RGBW moving wash with secondary Aura backlight', 'notes': 'Official Martin optics table specifies 19 x 10 W RGBW; secondary Aura illumination is not counted as lenses.', 'aura': True}, 'source_urls': ['https://www.martin.com/en-US/products/mac-aura', 'https://www.martin.com/en-US/site_elements/mac-aura-dimensions-2d-pdf', 'https://adn.harmanpro.com/product_attachments/product_attachments/4827_1728124249/macaura_x_large.webp']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
