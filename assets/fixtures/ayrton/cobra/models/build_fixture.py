#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'ayrton/cobra', 'width_m': 0.36, 'height_m': 0.674, 'depth_m': 0.319, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'IP65 laser-phosphor beam moving head', 'notes': 'Single front aperture; 13 internal optical elements. Continuous pan/tilt mechanism requires unlimited-axis support.'}, 'source_urls': ['https://www.ayrton.eu/produit/cobra2/', 'https://www.ayrton.eu/wp-content/uploads/2024/01/COBRA2-Specification-Sheet-V9.pdf', 'https://www.ayrton.eu/wp-content/uploads/2024/01/Cobra2-3.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
