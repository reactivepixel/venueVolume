#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'showven/sparkular-jet-ii', 'width_m': 0.348, 'height_m': 0.29, 'depth_m': 0.348, 'profile': {'family': 'spark', 'lens_count': 0, 'body_style': 'stainless steel spark jet with integrated compressor', 'notes': "One visible effect outlet; no optical lens. Physical geometry only. Manufacturer's dedicated pyro-signal input is not DMX.", 'generator': 'effects', 'enclosure': 'spark_box', 'output_kind': 'spark'}, 'source_urls': ['https://www.showven.cn/product/sparkular-jet-ii/', 'https://www.showven.cn/wp-content/uploads/2025/02/JET-II-500x500.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
