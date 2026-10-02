#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/catalog_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-dj/intimidator-spot-duo', 'width_m': 0.54, 'height_m': 0.365, 'depth_m': 0.187, 'profile': {'family': 'batten', 'lens_count': 2, 'body_style': 'two compact moving spot heads mounted to one crossbar', 'notes': 'Requires paired moving yokes and head subassemblies rather than a single conventional moving-head shell.', 'generator': 'catalog', 'dual_movers': True}, 'source_urls': ['https://www.chauvetdj.com/products/intimidator-spot-duo/', 'https://www.chauvetdj.com/wp-content/uploads/pdf/en/intimidator-spot-duo.pdf', 'https://www.chauvetdj.com/wp-content/uploads/2015/12/intimidator-spot-duo-cat.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
