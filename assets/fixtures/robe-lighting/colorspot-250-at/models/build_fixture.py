#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/colorspot-250-at', 'width_m': 0.419, 'height_m': 0.494, 'depth_m': 0.438, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'discharge spot moving head', 'notes': 'Robe marks this exact model discontinued; use only official fixture still, not event photographs.', 'shell': 'faceted', 'base_height': 0.22}, 'source_urls': ['https://www.robe.cz/colorspot-250-at', 'https://www.robe.cz/res/downloads/catalogues/ColorSpot_250_AT_leaflet.pdf', 'https://www.robe.cz/res/downloads/user_manuals/User_manual_Colorspot_250_AT.pdf', 'https://cdn.aws.robe.cz/v1/image/resize/6d0d71f3c0dce0301a58534772e45d078535abd6?fit=contain&height=800&width=800&withoutEnlargement=false']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
