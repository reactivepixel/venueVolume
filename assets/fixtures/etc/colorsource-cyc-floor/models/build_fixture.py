#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'etc/colorsource-cyc-floor', 'width_m': 0.266, 'height_m': 0.199, 'depth_m': 0.221, 'profile': {'family': 'cyc', 'body_style': 'low asymmetric cyc wash housing with LED aperture', 'notes': 'Dedicated cyclorama product.', 'generator': 'equipment', 'output_kind': 'light'}, 'source_urls': ['https://www.etcconnect.com/products/entertainment-fixtures/colorsource-cyc/tech-specs.aspx', 'https://www.etcconnect.com/uploadedImages/Main_Site/Images/Products/Lighting_Fixtures/ColorSource/en-CS-CYC-Leaderlines-960x300.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
