#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/equipment_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'global-truss/sq-4110-f34-straight-segment-natural-aluminium', 'width_m': 1.0, 'height_m': 0.29, 'depth_m': 0.29, 'profile': {'family': 'truss', 'body_style': 'four-chord square truss module with diagonal bracing and end connector plates', 'notes': 'Use as a visual planning component only; do not infer load capacity from the 3D model. Consult product-specific load tables and a qualified rigger for actual system design.', 'generator': 'equipment', 'output_kind': 'none'}, 'source_urls': ['https://www.globaltruss.com/sq-4110', 'https://d295jznhem2tn9.cloudfront.net/ItemRelatedFiles/11147/F34-SQ-4110.pdf', 'https://www.globaltruss.com/media/catalog/product/cache/6517c62f5899ad6aa0ba23ceb3eeff97/1/0/1000x1000-20f34-20straight-41866.jpg']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
