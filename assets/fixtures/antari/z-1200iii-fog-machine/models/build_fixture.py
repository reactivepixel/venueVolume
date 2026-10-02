#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'antari/z-1200iii-fog-machine', 'width_m': 0.32, 'height_m': 0.326, 'depth_m': 0.458, 'profile': {'family': 'fogger', 'body_style': 'compact convex metal fogger with top reservoir, carry handle and front nozzle', 'notes': 'Current embossed III-series shell; do not reuse Z-1000III dimensions or geometry blindly.', 'generator': 'effects', 'enclosure': 'silver_machine', 'hanging_bracket': True, 'manual_equipment_tilt': True, 'output_kind': 'fog'}, 'source_urls': ['https://antari.com/products/z-1200iii/', 'https://www.antari.com/usermanual/Z/Z-1200III/Z-1200III.pdf', 'https://antari.com/wp-content/uploads/2024-Antari-Product-Guide.pdf', 'https://antari.com/wp-content/uploads/Z-1200III_01.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
