#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'look-solutions/tiny-s', 'width_m': 0.051, 'height_m': 0.035, 'depth_m': 0.103, 'profile': {'family': 'fogger', 'body_style': 'small cylindrical handheld fogger with screw-on battery and transparent fluid reservoir', 'notes': 'Miniature scale; battery and reservoir contribute to modeled body. Exact current product still URL was located and captured locally.', 'generator': 'effects', 'enclosure': 'tiny_fogger', 'output_kind': 'fog'}, 'source_urls': ['https://www.looksolutions.com/products/tiny_s/8.html', 'https://www.looksolutions.com/uploads/pdf/en_fr/bed_tinys_1e.pdf', 'https://www.looksolutions.com/uploads/produkte/191110-TinyS-007.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
