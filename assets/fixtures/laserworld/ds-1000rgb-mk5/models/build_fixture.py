#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'laserworld/ds-1000rgb-mk5', 'width_m': 0.2, 'height_m': 0.125, 'depth_m': 0.185, 'profile': {'family': 'laser', 'body_style': 'rectangular enclosed projector chassis with front aperture and rigging frame', 'notes': 'No beam effect, aiming, safety behavior, interlock or firing semantics modeled.', 'generator': 'equipment', 'output_kind': 'laser_aperture'}, 'source_urls': ['https://www.laserworld.com/en/laserworld-ds/laserworld-ds-1000rgb-mk5', 'https://www.laserworld.com/pdf/generate.php?lang=en&productid=7640144997564', 'https://www.laserworld.com/images_product/7640144997564/200/Laserworld_DS-1000RGB_MK5_fr_s.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
