#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/effects_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'mdg/mse1', 'width_m': 0.305, 'height_m': 0.356, 'depth_m': 0.229, 'profile': {'family': 'fogger', 'body_style': 'grey closed industrial cabinet with weather-resistant face panel and service vents; external fluid/gas connections', 'notes': 'The exact MSe1 product image shows a grey closed cabinet, not the purple ATMOSPHERE-series body. Model the enclosure only. Fluid container, gas supply and control wiring are external dependencies.', 'generator': 'effects', 'enclosure': 'sealed_cabinet', 'output_kind': 'fog'}, 'source_urls': ['https://www.mdgfog.com/en/mse1-mse2', 'https://mdgfog.s3.ca-central-1.amazonaws.com/uploads/img/MSe1_Face.png']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
