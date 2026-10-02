#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/"../../../_shared/detailed_fixture.py").resolve()
s=importlib.util.spec_from_file_location("detailed_fixture",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'adj/focus-flex-l7', 'width_m': 0.25, 'height_m': 0.349, 'depth_m': 0.179, 'profile': {'family': 'moving_wash', 'lens_count': 7, 'body_style': 'compact moving head with a linear seven-engine RGBL array and zoom optics', 'notes': 'Seven independent RGBL engines create pixel effects; model all optical apertures rather than a single emitter if supported.'}, 'source_urls': ['https://www.adj.com/products/focus-flex-l7', 'https://www.adj.com/cdn/shop/files/d33775b549cb16578938a380735e1b6d7f7f5094_FOC734__IMG__003__c7174f800104.jpg?v=1776712415&width=2048', 'https://www.adj.com/cdn/shop/files/d33775b549cb16578938a380735e1b6d7f7f5094_FOC734__IMG__003__c7174f800104.jpg?v=1776712415&width=2048']}
m.build(SPEC,Path(os.environ.get("VV_FIXTURE_OUTPUT",str(HERE.parent))))
sys.stdout.flush();sys.stderr.flush();os._exit(0)
