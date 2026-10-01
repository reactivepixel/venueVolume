#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'mdg/atmosphere-aps-haze-generator', 'width_m': 0.18, 'height_m': 0.3, 'depth_m': 0.685, 'profile': {'family': 'hazer', 'notes': 'Oil-based atomizing fluid plus separate externally supplied compressed CO2; no onboard compressor is claimed and this is not a CO2 plume jet.', 'body_style': 'long low rectangular violet metal machine with raised fluid reservoir at one end and carry handle', 'generator': 'equipment', 'output_kind': 'haze'}, 'source_urls': ['https://www.mdgfog.com/en/atmosphereaps', 'https://www.mdgfog.com/en/2-channel-dmx-interface', 'https://mdgfog.s3.amazonaws.com/uploads/img-tiny/atmosphere-a-bb3c9a.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
