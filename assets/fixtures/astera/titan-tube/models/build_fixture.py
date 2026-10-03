#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'astera/titan-tube', 'width_m': 1.035, 'height_m': 0.043, 'depth_m': 0.043, 'profile': {'family': 'tube', 'body_style': 'sealed cylindrical RGB pixel tube with end caps and battery/control end', 'notes': '16 individually addressable light pixels distributed along the linear tube; mounting holders are accessories and excluded from envelope.', 'generator': 'equipment', 'output_kind': 'light'}, 'source_urls': ['https://astera-led.com/wp-content/uploads/Astera_Titan_Tube_whiteblack_V1.svg', 'https://astera-led.com/wp-content/uploads/FP1_Titan-Tube_Datasheet_V3.pdf', 'https://astera-led.com/wp-content/uploads/FP1-BTB_TitanTubeBTB_Manual.pdf', 'https://astera-led.com/wp-content/uploads/Astera_Titan_Tube_whiteblack_V1.svg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
