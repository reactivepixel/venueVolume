#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'ayrton/perseo-beam', 'width_m': 0.49, 'height_m': 0.71, 'depth_m': 0.33, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'IP65 profile/beam moving head', 'notes': 'Single front aperture with 13-element zoom optic; 540° pan and 263° tilt.'}, 'source_urls': ['https://www.ayrton.eu/produit/perseo-beam/', 'https://www.ayrton.eu/wp-content/uploads/2021/06/PerseoLT3.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
