#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'ayrton/rawbeam-350', 'width_m': 0.339, 'height_m': 0.592, 'depth_m': 0.297, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'compact laser-phosphor beam moving head', 'notes': 'Continuous pan and tilt rotation requires unlimited-axis support; retain as a source-backed motion capability.', 'generator': 'catalog', 'shell': 'faceted', 'head_depth': 1.15, 'yoke_compression': 0.18}, 'source_urls': ['https://www.ayrton.eu/produit/rawbeam-350/', 'https://www.ayrton.eu/wp-content/uploads/2026/06/RAWBEAM-Specification-Sheet-V1.pdf', 'https://www.ayrton.eu/wp-content/uploads/2026/06/RawBeam350-2.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
