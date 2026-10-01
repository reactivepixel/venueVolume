#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-professional/colordash-par-h12x-ip', 'width_m': 0.3054, 'height_m': 0.2479, 'depth_m': 0.232, 'profile': {'family': 'par', 'lens_count': 12, 'body_style': 'round-front sealed die-cast PAR housing with double-bracket yoke', 'notes': 'Twelve hex-color modules documented; body orientation should be checked against official CAD.'}, 'source_urls': ['https://chauvetprofessional.com/product/colordash-par-h12x-ip/', 'https://moogaudio.com/cdn/shop/files/ChauvetProfessionalCOLORdashPARH12XIPLEDWash_1_800x.jpg?v=1774026071', 'https://chauvetprofessional.com/wp-content/uploads/2025/10/COLORDASH-PAR-H12X-IP-FRONT-FEAT.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
