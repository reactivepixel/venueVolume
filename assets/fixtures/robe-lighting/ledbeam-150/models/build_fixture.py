#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'robe-lighting/ledbeam-150', 'width_m': 0.244, 'height_m': 0.337, 'depth_m': 0.149, 'profile': {'family': 'moving_wash', 'lens_count': 7, 'body_style': 'compact multisource wash/beam head', 'notes': 'Seven discrete RGBW source/lens channels arranged in compact head.'}, 'source_urls': ['https://www.robe.cz/ledbeam-150', 'https://cdn.aws.robe.cz/v1/image/resize/371252fca4e93281166480433c3fbbc5635c6c8e']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
