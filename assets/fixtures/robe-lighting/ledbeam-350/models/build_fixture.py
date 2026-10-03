#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/ledbeam-350', 'width_m': 0.32, 'height_m': 0.426, 'depth_m': 0.22, 'profile': {'family': 'moving_wash', 'lens_count': 12}, 'source_urls': ['https://www.robe.cz/ledbeam-350', 'https://www.robe.cz/res/downloads/catalogues/ROBE_LEDBeam_350_leaflet_online_version.pdf', 'https://www.robe.cz/res/downloads/exterior_dimensions/RobinLEDBeam350-dimensions.pdf', 'https://cdn.aws.robe.cz/v1/image/resize/7c16e7d0f45129d3a4fc9e6be99a5f1a32e0e115?fit=cover&height=452&width=452&withoutEnlargement=false']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
