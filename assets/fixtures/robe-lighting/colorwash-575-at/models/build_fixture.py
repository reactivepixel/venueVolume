#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/colorwash-575-at', 'width_m': 0.47, 'height_m': 0.588, 'depth_m': 0.446, 'profile': {'family': 'moving_wash', 'lens_count': 1, 'body_style': '575 W discharge wash moving head', 'notes': 'Keep optional wide-angle lens modules separate from standard body envelope.', 'fresnel': True, 'head_depth': 0.72, 'base_height': 0.22}, 'source_urls': ['https://www.robe.cz/colorwash-575-at-tm', 'https://cdn.aws.robe.cz/v1/image/resize/9066aa8c0abcd3415b1f41a321d6bafd6bc0ddda?fit=contain&height=800&width=800&withoutEnlargement=false']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
