#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'etc/colorsource-fresnel-v', 'width_m': 0.321, 'height_m': 0.339, 'depth_m': 0.311, 'profile': {'family': 'fresnel', 'barn_doors': True}, 'source_urls': ['https://www.etcconnect.com/Products/Entertainment-Fixtures/ColorSource-Fresnel-V/Documentation.aspx', 'https://www.etcconnect.com/Products/Entertainment-Fixtures/ColorSource-Fresnel-V/Features.aspx', 'https://www.etcconnect.com/workarea/DownloadAsset.aspx?id=10737519250', 'https://www.etcconnect.com/uploadedImages/Main_Site/Images/Products/Entertainment_Fixtures/ColorSource_V/FresnelVMax.547x400.png', 'https://support.etcconnect.com/ETC/Repair_and_Service_Center/LED_Fixtures/ColorSource_Fresnel_V_and_MAX_Service_Guides/ColorSource_Fresnel_V_and_MAX_Exploded_Diagrams']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
