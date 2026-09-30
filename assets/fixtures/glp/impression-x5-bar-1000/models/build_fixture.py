#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/'../../../_shared/procedural_fixture.py').resolve()
s=importlib.util.spec_from_file_location("venue_fixture_builder",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'glp/impression-x5-bar-1000', 'width_m': 1.0, 'height_m': 0.296, 'depth_m': 0.11, 'shape': 'batten'}
m.build(SPEC,HERE.parent)
sys.stdout.flush(); sys.stderr.flush(); os._exit(0)
