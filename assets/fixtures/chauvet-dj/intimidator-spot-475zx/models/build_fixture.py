#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-dj/intimidator-spot-475zx', 'width_m': 0.363, 'height_m': 0.531, 'depth_m': 0.25, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'mid-size LED spot mover with dual prism and moving yoke', 'notes': 'Manufacturer manual gives full dimensions, weight and mode footprint.', 'shell': 'faceted', 'head_depth': 0.87}, 'source_urls': ['https://www.chauvetdj.com/wp-content/uploads/pdf/en/intimidator-spot-475zx.pdf', 'https://www.chauvetdj.com/wp-content/uploads/2022/10/Intimidator-Spot-475ZX_UM_Rev1.pdf', 'https://www.chauvetdj.com/wp-content/uploads/2022/10/INTIMIDATOR-475ZX-FRONT-OFF.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
