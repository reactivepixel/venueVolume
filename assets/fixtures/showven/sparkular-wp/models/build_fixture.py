#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'showven/sparkular-wp', 'width_m': 0.317, 'height_m': 0.295, 'depth_m': 0.287, 'profile': {'family': 'spark', 'lens_count': 0, 'body_style': 'weather-rated metal cold-spark unit', 'notes': 'One visible effect outlet; no optical lenses or spotlight emitter. Retain weather-rated enclosure as a visual distinction.', 'generator': 'effects', 'enclosure': 'spark_box', 'output_kind': 'spark'}, 'source_urls': ['https://www.showven.cn/product/sparkular-wp/', 'https://www.showven.cn/wp-content/uploads/2025/02/%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20260427154257_1569_1952-500x500.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
