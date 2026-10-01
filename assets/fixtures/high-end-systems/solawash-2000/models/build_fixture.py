#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'high-end-systems/solawash-2000', 'width_m': 0.475, 'height_m': 0.886, 'depth_m': 0.32, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.79, 'head_depth': 0.89, 'fresnel': True}, 'source_urls': ['https://www.etcconnect.com/Products/Legacy/Live-Events-High-End-Systems/Lighting-Fixtures/SolaWash/2000/Features.aspx', 'https://www.etcconnect.com/Products/Legacy/Live-Events-High-End-Systems/Lighting-Fixtures/', 'https://www.highend.com/', 'https://www.etcconnect.com/Products/Legacy/Live-Events-High-End-Systems/Lighting-Fixtures/SolaWash/2000/Documentation.aspx', 'https://www.etcconnect.com/uploadedImages/Main_Site/Images/High_End_Systems_Images/Lighting_Fixtures/SolaWash/Solawash_2000_prod_left.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
