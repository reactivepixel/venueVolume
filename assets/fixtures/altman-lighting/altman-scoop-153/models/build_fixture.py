#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'altman-lighting/altman-scoop-153', 'width_m': 0.273, 'height_m': 0.359, 'depth_m': 0.203, 'profile': {'family': 'flood', 'body_style': 'elliptical scoop reflector with yoke and medium-screw lamp socket', 'notes': 'Discontinued; 400 W maximum and passive control, no onboard DMX.', 'generator': 'equipment', 'output_kind': 'light'}, 'source_urls': ['https://www.altmanlighting.com/wp-content/uploads/2018/10/Scoop153_Disc_Oct2018.pdf', 'https://www.altmanlighting.com/wp-content/uploads/2018/10/Scoop153_Disc_Oct2018.pdf']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
