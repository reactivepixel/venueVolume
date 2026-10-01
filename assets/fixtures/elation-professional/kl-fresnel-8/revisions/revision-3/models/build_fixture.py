#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'elation-professional/kl-fresnel-8', 'width_m': 0.3275, 'height_m': 0.456, 'depth_m': 0.6084, 'profile': {'family': 'fresnel', 'barn_doors': True}, 'source_urls': ['https://www.elationlighting.com/products/kl-fresnel-8', 'https://www.elationlighting.com/cdn/shop/files/9182ac94ce3e7191a943e08811665c65e4c51157_KLF023__IMG__001__42d4bf9b406c.jpg?v=1776815436&width=850']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
