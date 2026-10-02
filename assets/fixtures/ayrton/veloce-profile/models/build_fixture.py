#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'ayrton/veloce-profile', 'width_m': 0.404, 'height_m': 0.757, 'depth_m': 0.366, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'large IP65 profile moving head', 'notes': '13-element zoom optics and four-blade framing; continuous pan and tilt rotation require unlimited-axis support.'}, 'source_urls': ['https://www.ayrton.eu/produit/veloce-profile/', 'https://www.ayrton.eu/wp-content/uploads/2024/09/VeloceProfileS-Specification-Sheet-V9.pdf', 'https://www.ayrton.eu/wp-content/uploads/2024/08/VeloceP-3.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
