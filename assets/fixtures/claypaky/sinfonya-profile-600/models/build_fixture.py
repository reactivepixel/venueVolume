#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'claypaky/sinfonya-profile-600', 'width_m': 0.425, 'height_m': 0.796, 'depth_m': 0.417, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'theatre moving profile with yoke and large circular lens', 'notes': 'Sinfonya Profile 600 standard model; RGBAL source. Manufacturer lists 14 optical lenses and 165 mm front lens.'}, 'source_urls': ['https://www.claypaky.it/products/sinfonya-profile-600/', 'https://www.claypaky.it/wp-content/uploads/2023/04/Claypaky_SinfonyaProfile600.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
