#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'high-end-systems/solaframe-2000', 'width_m': 0.475, 'height_m': 0.838, 'depth_m': 0.32, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'large LED framing head with yoke and circular lens', 'notes': '600 W light engine; overall input draw varies by line voltage. Multiple engine variants.'}, 'source_urls': ['https://www.etcconnect.com/Products/Legacy/Live-Events-High-End-Systems/Lighting-Fixtures/SolaFrame/2000/Features.aspx', 'https://www.etcconnect.com/WorkArea/DownloadAsset.aspx?id=10737503533', 'https://www.etcconnect.com/WorkArea/DownloadAsset.aspx?id=10737504840', 'https://www.etcconnect.com/uploadedImages/Main_Site/Images/High_End_Systems_Images/Lighting_Fixtures/SolaFrame/SolaFrame_2000_prod_right.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
