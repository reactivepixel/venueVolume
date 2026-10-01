#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'claypaky/tambora-flash', 'width_m': 0.497, 'height_m': 0.186, 'depth_m': 0.18, 'profile': {'family': 'strobe', 'lens_count': 4, 'body_style': 'IP66 rectangular modular fixture with four central reflector cells and two strobe strips', 'notes': 'Four RGBWW reflector optics plus two lines of segmented white strobe LEDs; handles excluded from dimensions.', 'reflector_cells': 4}, 'source_urls': ['https://www.claypaky.it/products/tambora-flash/', 'https://www.claypaky.it/products/tambora-flash/claypaky_tamboraflash_en/', 'https://www.claypaky.it/wp-content/uploads/2025/06/Claypaky_TamboraFlash.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
