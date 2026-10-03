#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'showven/sparkular', 'width_m': 0.218, 'height_m': 0.305, 'depth_m': 0.2, 'profile': {'family': 'spark', 'lens_count': 0, 'body_style': 'upright metal cold-spark fountain unit', 'notes': 'One visible effect outlet; no optical lenses or spotlight emitter.', 'generator': 'effects', 'enclosure': 'spark_box', 'output_kind': 'spark'}, 'source_urls': ['https://www.showven.cn/product/sparkular/', 'https://www.showven.cn/wp-content/uploads/2025/07/SPARKULAR-20250616.pdf', 'https://www.showven.cn/wp-content/uploads/2019/11/gsdT7v69Sa298ZXLkx6vww.png_640xa-500x500.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
