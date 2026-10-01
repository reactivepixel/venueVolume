#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/jolt-bar-fx2', 'width_m': 1.0, 'height_m': 0.101, 'depth_m': 0.1035, 'profile': {'family': 'strobe', 'lens_count': 560, 'body_style': 'linear rectangular bar with central white LED strip, RGB LED fields, and end brackets', 'notes': 'LED quantity sourced as 448 RGB plus 112 cool-white emitters; bracket/body detail should follow official product imagery and CAD.', 'strip': True, 'cells': 28}, 'source_urls': ['https://www.adj.com/products/jolt-bar-fx2', 'https://www.adj.com/cdn/shop/files/e1af7217437ab7f23dec17a84b9dae00a6dcec47_JOL286__IMG__004__067a4c0bb043.jpg?v=1776713904&width=800']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
