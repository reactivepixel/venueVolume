#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-professional/colordash-par-quad-18', 'width_m': 0.323, 'height_m': 0.298, 'depth_m': 0.106, 'profile': {'family': 'par', 'lens_count': 18, 'body_style': 'round metal PAR with 18-cell front array and split yoke', 'notes': 'Legacy product, marked as such on manufacturer page. Product manual Rev. 6 diagrams show front, side, and rear views.'}, 'source_urls': ['https://chauvetprofessional.com/product/colordash-par-quad-18/', 'https://www.chauvetprofessional.com/wp-content/uploads/2018/01/COLORdash_Par-Quad_18_UM_Rev6.pdf', 'https://www.fullcompass.com/common/products/lgr/471924.jpg', 'https://chauvetprofessional.com/wp-content/uploads/2025/10/COLORDASH-PAR-QUAD-18-FRONT-FEAT.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
