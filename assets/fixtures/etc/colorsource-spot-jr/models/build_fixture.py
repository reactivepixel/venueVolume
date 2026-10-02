#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'etc/colorsource-spot-jr', 'width_m': 0.258, 'height_m': 0.331, 'depth_m': 0.46, 'profile': {'family': 'profile', 'barrel_ratio': 0.36, 'body_style': 'compact LED ellipsoidal with integral zoom optics and yoke', 'notes': 'ETC junior-format profile; dimensional drawing is authoritative for outer envelope.', 'generator': 'catalog', 'round_front': True}, 'source_urls': ['https://www.etcconnect.com/products/entertainment-fixtures/colorsource-spot-jr/documentation.aspx', 'https://www.etcconnect.com/WorkArea/DownloadAsset.aspx?id=10737502586', 'https://www.etcconnect.com/WorkArea/DownloadAsset.aspx?id=10737502608', 'https://www.etcconnect.com/uploadedImages/Main_Site/Images/Products/Lighting_Fixtures/ColorSource/ColorSource_Spot_jr_Right.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
