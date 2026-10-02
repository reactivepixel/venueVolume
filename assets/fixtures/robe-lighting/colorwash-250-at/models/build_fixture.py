#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/colorwash-250-at', 'width_m': 0.419, 'height_m': 0.513, 'depth_m': 0.438, 'profile': {'family': 'moving_wash', 'lens_count': 1, 'body_style': 'discharge wash moving head', 'notes': 'The official leaflet includes a still product photo and dimension views; dimensions exclude shipping packaging.', 'fresnel': True, 'head_depth': 0.72, 'base_height': 0.22}, 'source_urls': ['https://www.robe.cz/res/downloads/catalogues/ColorWash_250_AT_leaflet.pdf', 'https://cdn.aws.robe.cz/v1/image/resize/e6c804d7a25ab0d1bd33dbd3974a44d1ccbb1b0f?fit=contain&height=800&width=800&withoutEnlargement=false']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
