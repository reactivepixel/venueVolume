#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'vari-lite/vl5led-wash', 'width_m': 0.367, 'height_m': 0.578, 'depth_m': 0.36, 'profile': {'family': 'moving_wash', 'lens_count': 1, 'radial_blades': True}, 'source_urls': ['https://www.vari-lite.com/global/products/v5led-wash', 'https://vari-lite.s3.eu-west-1.amazonaws.com/datasheets/Vari-Lite/VL5LED_WASH.pdf', 'https://www.vari-lite.com/b-dam/vari-lite/products/vl5led-wash/VL5LED-WASH_thumbnail.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
