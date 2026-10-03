#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'ayrton/khamsin-tc', 'width_m': 0.494, 'height_m': 0.778, 'depth_m': 0.28, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'high-CRI profile moving head', 'notes': 'Single front aperture; 13-element zoom optic. Pan 540°, tilt 262°.'}, 'source_urls': ['https://www.ayrton.eu/produit/khamsin/', 'https://www.ayrton.eu/wp-content/uploads/2018/10/Product-slider-khamsin-03.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
