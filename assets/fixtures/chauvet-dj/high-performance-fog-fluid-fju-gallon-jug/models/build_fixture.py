#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-dj/high-performance-fog-fluid-fju-gallon-jug', 'width_m': 0.155, 'height_m': 0.3, 'depth_m': 0.155, 'profile': {'family': 'fluid_container', 'notes': 'Exact sealed FJU gallon jug product/package; record is the container geometry, not a fluid mixture or recipe. CHAUVET identifies the formula as designed for water-based machines.', 'body_style': 'white handled rectangular plastic gallon jug with screw cap and printed product label', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.chauvetdj.com/products/fog-juice-gallon/', 'https://www.chauvetdj.com/wp-content/uploads/2015/12/fju-front-feat.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
