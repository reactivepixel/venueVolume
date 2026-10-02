#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'le-maitre/gforce-3', 'width_m': 0.27, 'height_m': 0.43, 'depth_m': 0.55, 'profile': {'family': 'fogger', 'lens_count': 0, 'body_style': 'rectangular fogger with rear bottle carrier', 'notes': 'Do not add optical emission. Carrier-equipped overall envelope used.', 'generator': 'equipment', 'output_kind': 'fog'}, 'source_urls': ['https://lemaitreltd.com/products/smoke-fog-haze/smoke-fog-haze-machines/gforce-3/le-maitre-smoke-machine-comparison-breakdown/', 'https://lemaitreltd.com/sites/lemaitreltd/cache/file/AD75D031-C865-4286-9E7926ADFF25C3DB.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
