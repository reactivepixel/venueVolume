#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'showven/sparkular-cyclone-ii', 'width_m': 0.348, 'height_m': 0.29, 'depth_m': 0.316, 'profile': {'family': 'spark', 'lens_count': 0, 'body_style': 'rotating cold-spark effect housing', 'notes': 'No optical lens; rotating effect outlet direction is a physical feature. Do not approximate outlet count or positions from effect diagrams.', 'generator': 'effects', 'enclosure': 'spark_box', 'output_kind': 'spark'}, 'source_urls': ['https://www.showven.cn/product/sparkular-cyclone-ii/', 'https://www.showven.cn/wp-content/uploads/2025/02/%E9%A3%93%E9%A3%8E2-8-500x500.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
