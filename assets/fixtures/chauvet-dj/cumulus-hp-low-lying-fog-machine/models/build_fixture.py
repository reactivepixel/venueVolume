#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-dj/cumulus-hp-low-lying-fog-machine', 'width_m': 0.304, 'height_m': 0.347, 'depth_m': 0.464, 'profile': {'family': 'low_fog', 'notes': 'Ultrasonic atomizer uses distilled water; separate fog fluid feeds the warmed carrier fog. No dry ice required.', 'body_style': 'rugged rectangular case-style enclosure with hose outlet and separate water/fog tanks', 'generator': 'equipment', 'output_kind': 'low_fog'}, 'source_urls': ['https://www.chauvetdj.com/products/cumulus-hp/', 'https://www.chauvetdj.com/wp-content/uploads/2023/12/Cumulus_HP_UM_Rev1.pdf', 'https://www.chauvetdj.com/wp-content/uploads/2023/12/Cumulus_HP_UM_Rev1.pdf']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
