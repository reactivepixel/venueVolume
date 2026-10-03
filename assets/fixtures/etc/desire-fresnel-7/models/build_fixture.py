#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'etc/desire-fresnel-7', 'width_m': 0.304, 'height_m': 0.455, 'depth_m': 0.356, 'profile': {'family': 'fresnel', 'barn_doors': True, 'lens_count': 1, 'body_style': 'round Fresnel head on yoke', 'notes': 'DFL7 is a fixed 7-inch aperture variant; allow lens travel in depth.'}, 'source_urls': ['https://www.etcconnect.com/Products/Entertainment-Fixtures/Desire-Fresnel/Features/', 'https://www.etcconnect.com/Products/Entertainment-Fixtures/Desire-Fresnel/Documentation.aspx', 'https://www.etcconnect.com/WorkArea/DownloadAsset.aspx?id=10737506619', 'https://www.etcconnect.com/WorkArea/DownloadAsset.aspx?id=10737506792', 'https://www.ecm-sa.ch/media/desire_fresnel_datasheet_revf.pdf', 'https://www.etcconnect.com/uploadedImages/Main_Site/Images/Products/Lighting_Fixtures/Desire_Fresnel/Desire_Fresnel_Glam_960x300.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
