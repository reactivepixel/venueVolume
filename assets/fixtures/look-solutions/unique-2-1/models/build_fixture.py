#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'look-solutions/unique-2-1', 'width_m': 0.25, 'height_m': 0.25, 'depth_m': 0.47, 'profile': {'family': 'hazer', 'body_style': 'compact squared metal hazer with integrated fan, controls and removable fluid canister', 'notes': 'Use the official manufacturer side view for enclosure geometry; optional hanging set, diverter, and flight case are excluded.', 'generator': 'effects', 'enclosure': 'unique_hazer', 'output_kind': 'haze'}, 'source_urls': ['https://www.looksolutions.com/products/unique_2_1/8.html', 'https://www.looksolutions.com/uploads/pdf/en_fr/info_unique21_e.pdf', 'https://www.looksolutions.com/uploads/produkte/Unique2-1-Side.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
