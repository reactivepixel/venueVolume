#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'astera/helios-tube', 'width_m': 0.55, 'height_m': 0.043, 'depth_m': 0.043, 'profile': {'family': 'tube', 'body_style': 'sealed cylindrical pixel tube with end caps and integrated battery/control end', 'notes': 'Eight addressable pixels; 550 mm body length.', 'generator': 'equipment', 'output_kind': 'light'}, 'source_urls': ['https://astera-led.com/fr/products/helios-tube/specs/', 'https://astera-led.com/wp-content/uploads/Datasheet_Helios_Tube_V4-1.pdf', 'https://astera-led.com/wp-content/uploads/FP2-BTB_HeliosTube_BTB_Manual_EN_DE_IT_ES_FR_PT.pdf', 'https://media.astera-led.com/wp-content/uploads/Helios-Tube_V2.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
