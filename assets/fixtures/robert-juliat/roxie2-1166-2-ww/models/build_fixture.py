#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robert-juliat/roxie2-1166-2-ww', 'width_m': 0.321, 'height_m': 0.387, 'depth_m': 1.045, 'profile': {'family': 'followspot', 'body_style': 'manual followspot with lens barrel, handles, color boomerang and yoke', 'notes': 'Do not treat dimmer/strobe DMX as motorized pan/tilt.', 'generator': 'equipment', 'output_kind': 'light'}, 'source_urls': ['https://www.robertjuliat.com/followspots/roxie.html', 'https://www.robertjuliat.com/Product_Specifications/Fiches_EN/Standard/DSEN298_1166-2_WW.pdf', 'https://www.robertjuliat.com/images/PhotosHD_Products/PhotoWebHD_ROXIE_1166.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
