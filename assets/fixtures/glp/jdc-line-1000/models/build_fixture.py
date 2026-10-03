#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'glp/jdc-line-1000', 'width_m': 1.0, 'height_m': 0.074, 'depth_m': 0.2015, 'profile': {'family': 'batten', 'lens_count': 1, 'body_style': 'linear hybrid strobe and RGB pixel mapping fixture', 'notes': 'The 1000 mm lens tube shares RGB pixel and white strobe emission; a single continuous tube is a better shape representation than separate visible LEDs.', 'diffuser': True}, 'source_urls': ['https://www1.glp.de/en/products/entertainment-lighting/strobes/jdc-line-1000-en', 'https://glp.de/files/products/jdc-line-1000-product-data/JDC_Line_1000_User_Manual_EN_Rev_20240618-01.pdf', 'https://glp.de/files/products/jdc-line-1000-product-data/JDC_Line_1000_DMX_Channel_Index_Rev_20240618-01.pdf', 'https://www1.glp.de/templates/yootheme/cache/f0/JDC-Line-1000_Header-f04c3b7d.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
