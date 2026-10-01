#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'elation-professional/dartz-360', 'width_m': 0.19597, 'height_m': 0.4547, 'depth_m': 0.28415, 'profile': {'family': 'moving_spot', 'shell': 'round', 'lens_ratio': 0.78, 'head_depth': 0.73}, 'source_urls': ['https://www.elationlighting.com/products/dartz-360', 'https://www.elationlighting.com/cdn/shop/files/9a52b514f22cc4267d1a3efdd11897414280eec0_DAR880__IMG__001__cd987eea5c81.jpg?v=1776815066&width=850']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
