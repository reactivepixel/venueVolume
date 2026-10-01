#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'etc/colorsource-spot-v', 'width_m': 0.339, 'height_m': 0.593, 'depth_m': 0.672, 'profile': {'family': 'profile', 'barrel_ratio': 0.44}, 'source_urls': ['https://www.etcconnect.com/Products/Entertainment-Fixtures/ColorSource-Spot-V/Documentation.aspx', 'https://www.etcconnect.com/Products/Entertainment-Fixtures/ColorSource-Spot-V/Features.aspx', 'https://www.etcconnect.com/uploadedImages/Main_Site/Images/Products/Entertainment_Fixtures/ColorSource_V/SpotV_adapters_Zoom_960x460.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
