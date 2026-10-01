#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/tarrantula', 'width_m': 0.588, 'height_m': 0.605, 'depth_m': 0.523, 'profile': {'family': 'moving_wash', 'lens_count': 37, 'body_style': 'multi-source rounded head with RGBA pixel array', 'notes': '37 RGBA LED multichips; beam shaper is removable, but the shown standard assembly includes it.'}, 'source_urls': ['https://www.robe.cz/tarrantula', 'https://www.robe.cz/res/downloads/exterior_dimensions/Robin_Tarrantula_dimensions.pdf', 'https://www.robe.cz/res/downloads/user_manuals/User_manual_Robin_Tarrantula_RGBA.pdf', 'https://cdn.aws.robe.cz/v1/image/resize/6c9de341cb1ae82efd1cbaa4693d7540565e81c6?fit=cover&height=452&width=452&withoutEnlargement=false']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
