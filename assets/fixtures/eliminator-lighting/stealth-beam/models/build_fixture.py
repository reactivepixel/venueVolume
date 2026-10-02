#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'eliminator-lighting/stealth-beam', 'width_m': 0.239, 'height_m': 0.285, 'depth_m': 0.158, 'profile': {'family': 'moving_spot', 'lens_count': 1, 'body_style': 'compact RGBW beam head with single ACL lens and yoke', 'notes': 'Continuous pan is listed; no assumed finite pan limit. Product page contains core control and geometry specs; manual not transcribed.'}, 'source_urls': ['https://www.eliminatorlighting.com/products/stealth-beam', 'https://www.eliminatorlighting.com/cdn/shop/files/91dafeb75bae3b7b779e484c06ea673d6786cbc9_STEALTH_BEAM__IMG__001__432d0839d573.jpg?v=1777055739&width=2048']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
