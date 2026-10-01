#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-professional/strike-4', 'width_m': 0.362, 'height_m': 0.362, 'depth_m': 0.163, 'profile': {'family': 'blinder', 'body_style': 'four-cell warm-white blinder panel with yoke', 'notes': 'Four individually aimable cells; not a tungsten lamp fixture.', 'generator': 'equipment', 'output_kind': 'light'}, 'source_urls': ['https://chauvetprofessional.com/product/strike-4/', 'https://chauvetprofessional.com/wp-content/uploads/2025/10/STRIKE-4-FRONT-FEAT.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
