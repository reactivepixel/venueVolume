#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'antari/z-1000iii-fog-machine', 'width_m': 0.281, 'height_m': 0.266, 'depth_m': 0.433, 'profile': {'family': 'fogger', 'notes': 'Conventional heated water-based fog machine; chosen instead of Z-1200III because the official Z-1000III source has a consistent dimensional identity. Distinct from compressor hazer and cold CO2 jet.', 'body_style': 'rectangular metal fogger with carry handle, fluid tank, front outlet and pivoting hanging bracket', 'generator': 'equipment', 'output_kind': 'fog'}, 'source_urls': ['https://antari.com/products/z-1000iii/', 'https://antari.com/wp-content/uploads/Z-1000III_01.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
