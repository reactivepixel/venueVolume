#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'mdg/atmosphere-aps', 'width_m': 0.18, 'height_m': 0.3, 'depth_m': 0.685, 'profile': {'family': 'hazer', 'body_style': 'long purple rectangular industrial haze generator with full-length side panel, top handle and brass cap; broad fan and outlet assembly at one end', 'notes': 'The exact ATMOSPHERE APS full-body side view is available in official gallery image 2. CO2 and MDG Neutral fluid are separate operating supplies and are not enclosure geometry; optional DMX module is external. Do not use the separate fan-detail image as the only body reference.', 'generator': 'equipment', 'output_kind': 'haze'}, 'source_urls': ['https://www.mdgfog.com/en/atmosphereaps', 'https://mdgfog.s3.amazonaws.com/uploads/img-tiny/atmosphere-a-bb3c9a.png', 'https://www.mdgfog.com/en/atmosphereaps-support', 'https://mdgfog.s3.amazonaws.com/uploads/img-tiny/atmosphere-a-bb3c9a.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
