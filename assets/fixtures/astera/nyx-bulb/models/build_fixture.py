#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'astera/nyx-bulb', 'width_m': 0.07, 'height_m': 0.13, 'depth_m': 0.07, 'profile': {'family': 'practical', 'body_style': 'compact color-tunable bulb with E27 base and translucent diffuser', 'notes': 'Exact FP5-E27 variant; built-in wireless CRMX receiver, not passive mains-only bulb.', 'generator': 'equipment', 'output_kind': 'light'}, 'source_urls': ['https://nyx-for-filmmakers.astera-led.com/', 'https://www.koto-jp.com/en/lighting/stage-studio/authorized-manufacturers/astera/1912/', 'https://www.koto-jp.com/en/wp-content/uploads/2022/03/NYX_en.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
