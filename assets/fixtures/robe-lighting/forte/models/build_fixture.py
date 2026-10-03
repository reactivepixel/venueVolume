#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/forte', 'width_m': 0.4835, 'height_m': 0.6355, 'depth_m': 0.6245, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.73, 'head_depth': 0.89}, 'source_urls': ['https://www.robe.cz/forte', 'https://www.robe.cz/res/downloads/user_manuals/User_manual_Robin_Forte.pdf', 'https://cdn.aws.robe.cz/v1/image/resize/401bff822913a8182209a6ef40c594071b9596c2?fit=cover&height=452&width=452&withoutEnlargement=false']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
