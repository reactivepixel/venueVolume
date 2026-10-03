#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'etc/colorsource-par-jr', 'width_m': 0.213, 'height_m': 0.282, 'depth_m': 0.251, 'profile': {'family': 'par', 'shell': 'round', 'lens_count': 4, 'notes': 'Compact convection-cooled LED PAR with four visible optical cups; manufacturer specifies 16 LED emitters distributed among the four optics.', 'generator': 'catalog', 'reflector_cups': 4}, 'source_urls': ['https://www.etcconnect.com/products/entertainment-fixtures/colorsource-par-jr/documentation.aspx', 'https://www.etcconnect.com/WorkArea/DownloadAsset.aspx?id=10737516212', 'https://www.etcconnect.com/uploadedImages/Main_Site/Images/Products/ColorSource/ColorSource_PAR_jr_Right_Black.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
