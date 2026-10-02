#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-dj/intimidator-spot-375zx', 'width_m': 0.322, 'height_m': 0.466, 'depth_m': 0.22, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'compact moving spot head with yoke', 'notes': 'Source states 7 + open colors, 7 + open rotating gobos and two prisms.', 'shell': 'faceted', 'head_depth': 0.87}, 'source_urls': ['https://www.chauvetdj.com/products/intimidator-spot-375zx/', 'https://www.chauvetdj.com/wp-content/uploads/2022/10/INTIMIDATOR-375ZX-FRONT-OFF.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
