#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'high-end-systems/solaframe-3000', 'width_m': 0.491, 'height_m': 0.821, 'depth_m': 0.368, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.59, 'head_depth': 0.88}, 'source_urls': ['https://www.etcconnect.com/Products/Legacy/Live-Events-High-End-Systems/Lighting-Fixtures/SolaFrame/3000/Features.aspx', 'https://www.highend.com/documentation/SolaFrame%203000/SolaFrame3000-protocol.pdf', 'https://www.etcconnect.com/support/Lighting_Fixtures/LED/FAQ/Fixture_Weights_and_Dimensions', 'https://www.etcconnect.com/workarea/DownloadAsset.aspx?id=10737506946', 'https://www.etcconnect.com/uploadedImages/Main_Site/Images/High_End_Systems_Images/Lighting_Fixtures/SolaFrame/SolaFrame3000_prod_right_wht.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
