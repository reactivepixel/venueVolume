#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/encore-lp12z-ip', 'width_m': 0.316, 'height_m': 0.346, 'depth_m': 0.371, 'profile': {'family': 'par', 'lens_count': 12, 'body_style': 'compact circular-front LED PAR with projecting lens, finned housing, and double-arm scissor yoke', 'notes': 'Twelve RGBL LED modules documented. No inferred individual lens counts beyond those modules.', 'floor_yoke': True}, 'source_urls': ['https://www.adj.com/products/encore-lp12z-ip', 'https://www.adj.com/cdn/shop/files/265349badd4c3136ad3a8df6fb6ab848cffbaaea_ENC395__IMG__002__851305f4fc1f.jpg?v=1775714586&width=800']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
