#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/spiider', 'width_m': 0.39, 'height_m': 0.477, 'depth_m': 0.286, 'profile': {'family': 'moving_wash', 'lens_count': 19}, 'source_urls': ['https://www.robe.cz/spiider', 'https://www.robe.cz/res/downloads/exterior_dimensions/Robin_Spiider_dimensions.pdf', 'https://www.robe.cz/res/downloads/catalogues/ROBE_Spiider_leaflet_online_version.pdf', 'https://cdn.aws.robe.cz/v1/image/resize/bacf4d213ec3c79f0b0fbc9128588eea91297efa?fit=cover&height=452&width=452&withoutEnlargement=false']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
