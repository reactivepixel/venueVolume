#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-dj/scorpion-dual-rgb', 'width_m': 0.216, 'height_m': 0.1795, 'depth_m': 0.161, 'profile': {'family': 'laser', 'lens_count': 2, 'body_style': 'compact rectangular dual-output laser projector', 'notes': 'Two mirror output apertures are explicitly identified by the manufacturer. Model as laser apparatus; do not add ordinary spotlight emission.', 'generator': 'effects', 'enclosure': 'laser_box', 'dual_mirror_window': True, 'manual_equipment_tilt': True, 'output_kind': 'laser_aperture'}, 'source_urls': ['https://www.chauvetdj.com/products/scorpion-dual-rgb/', 'https://www.chauvetdj.com/wp-content/uploads/2019/01/Scorpion_Dual_RGB_UM_Rev5_ML3.pdf', 'https://www.chauvetdj.com/wp-content/uploads/2018/12/cat-Scorpion-Dual.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
