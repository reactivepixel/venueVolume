#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'mean-well/lrs-350-24', 'width_m': 0.215, 'height_m': 0.03, 'depth_m': 0.115, 'profile': {'family': 'power_supply', 'body_style': 'low-profile vented metal enclosure with exposed terminal block and cooling fan', 'notes': 'Chassis only. Internal components, terminal details and mounting slots can be simplified; electrical installation and safety clearances are outside the visual envelope.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.meanwell.com/Upload/PDF/LRS-350/LRS-350-SPEC.PDF', 'https://www.meanwell.com/Upload/PDF/LRS-350/LRS-350-SPEC.PDF']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
