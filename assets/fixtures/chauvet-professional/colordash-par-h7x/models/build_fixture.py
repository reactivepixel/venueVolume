#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-professional/colordash-par-h7x', 'width_m': 0.258, 'height_m': 0.24, 'depth_m': 0.116, 'profile': {'family': 'par', 'lens_count': 7, 'body_style': 'round-front compact PAR can with 7-cell hex-color engine and double yoke', 'notes': 'Seven RGBAW+UV LED modules documented.', 'floor_yoke': False}, 'source_urls': ['https://chauvetprofessional.com/product/colordash-par-h7x/', 'https://www.bhphotovideo.com/images/fb/chauvet_professional_colordashparh7x_colordash_par_hex_7x_with_1742177.jpg', 'https://chauvetprofessional.com/wp-content/uploads/2025/10/COLORDASH-PAR-H7X-FRONT-FEAT.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
