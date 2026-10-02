#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'showven/sparkular-max', 'width_m': 0.42, 'height_m': 0.33, 'depth_m': 0.46, 'profile': {'family': 'spark', 'lens_count': 0, 'body_style': 'large rectangular cold-spark machine', 'notes': 'One visible effect outlet; no optical lens or spotlight emission.', 'generator': 'effects', 'enclosure': 'spark_box', 'output_kind': 'spark'}, 'source_urls': ['https://www.showven.cn/product/sparkular-max/', 'https://www.showven.cn/wp-content/uploads/2026/04/21-500x500.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
