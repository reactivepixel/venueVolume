#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-dj/hurricane-haze-2d', 'width_m': 0.285, 'height_m': 0.35, 'depth_m': 0.267, 'profile': {'family': 'hazer', 'generator': 'equipment', 'output_kind': 'haze', 'lens_count': 0, 'body_style': 'rectangular haze machine with top handle, fluid window and adjustable nozzle', 'notes': 'No light source; distinct from a fog machine used for dense plume effects.'}, 'source_urls': ['https://www.chauvetdj.com/wp-content/uploads/pdf/en/hurricane-haze-2d.pdf', 'https://www.chauvetdj.com/wp-content/uploads/2015/12/hurricane-haze-2d-cat.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
