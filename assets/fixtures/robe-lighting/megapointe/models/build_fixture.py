#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/megapointe', 'width_m': 0.396, 'height_m': 0.64, 'depth_m': 0.23, 'profile': {'family': 'moving_spot', 'shell': 'faceted', 'lens_ratio': 0.73, 'head_depth': 0.81}, 'source_urls': ['https://www.robe.cz/megapointe', 'https://www.robe.cz/res/downloads/catalogues/ROBE_Product_Guide_2021_online_version.pdf', 'https://cdn.aws.robe.cz/v1/image/resize/025ed591ad67ff06e9dd82b461e0c345ba595d4a?fit=cover&height=452&width=452&withoutEnlargement=false']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
