#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'etc/source-four-led-series-3-lustr-x8', 'width_m': 0.34, 'height_m': 0.34, 'depth_m': 0.721, 'profile': {'family': 'profile', 'barrel_ratio': 0.5}, 'source_urls': ['https://www.etcconnect.com/Products/Entertainment-Fixtures/Source-Four-LED-Series-3/Documentation.aspx', 'https://www.etcconnect.com/Products/Lighting-Fixtures/', 'https://www.etcconnect.com/webdocs/Fixtures/SourceFourLED_Series3/Content/S4S3/ConnectPowerAndData.htm', 'https://www.etcconnect.com/workarea/DownloadAsset.aspx?id=10737507137', 'https://www.etcconnect.com/uploadedImages/Main_Site/Images/Products/Entertainment_Fixtures/Series3_Fresnel_Adapter_right_Red.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
