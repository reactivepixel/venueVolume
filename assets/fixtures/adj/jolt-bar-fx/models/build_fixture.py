#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/jolt-bar-fx', 'width_m': 1.0, 'height_m': 0.123, 'depth_m': 0.107, 'profile': {'family': 'strobe', 'strip': True, 'cells': 20}, 'source_urls': ['https://www.adj.com/products/jolt-bar-fx', 'https://www.adj.com/cdn/shop/files/4ba34d07f96ad74129a39daa60a889601126b3e3_JOL250__IMG__003__d947eb5428f7.jpg?v=1776713379&width=800']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
