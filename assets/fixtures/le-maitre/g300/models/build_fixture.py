#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'le-maitre/g300', 'width_m': 0.61, 'height_m': 0.26, 'depth_m': 0.29, 'profile': {'family': 'fogger', 'lens_count': 0, 'body_style': 'large rectangular smoke machine', 'notes': 'No optical emitter. Distinguish from G300-Smart due to built-in network/DMX differences.', 'generator': 'equipment', 'output_kind': 'fog'}, 'source_urls': ['https://lemaitreltd.com/products/smoke-fog-haze/smoke-fog-haze-machines/g300/', 'https://lemaitreltd.com/products/smoke-fog-haze/smoke-fog-haze-machines/g300/le-maitre-smoke-machine-comparison-breakdown1/', 'https://lemaitreltd.com/sites/lemaitreltd/cache/file/711CDFCB-1C44-456A-ABC242A5BC99DAC4.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
