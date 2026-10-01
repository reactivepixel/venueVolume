#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'antari/b-100-bubble-machine', 'width_m': 0.265, 'height_m': 0.29, 'depth_m': 0.341, 'profile': {'family': 'bubble', 'notes': 'Selected B-100 rather than B-200 to avoid a substantial same-model manual/product-page envelope conflict. Current product page and Rev. 05 manual agree on the B-100 envelope and mass.', 'body_style': 'compact enclosed metal bubble machine with broad wheel/output opening, feet and rear control panel', 'generator': 'equipment', 'output_kind': 'bubbles'}, 'source_urls': ['https://antari.com/products/b-100/', 'https://www.antari.com/usermanual/B/B-100/B-100.pdf', 'https://antari.com/wp-content/uploads/B-100-01.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
