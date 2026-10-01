#!/usr/bin/env python3
from pathlib import Path
import importlib.util, os, sys
HERE=Path(__file__).resolve().parent
module_path=(HERE/'../../../_shared/procedural_fixture.py').resolve()
s=importlib.util.spec_from_file_location("venue_fixture_builder",module_path)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
SPEC={'id': 'chauvet-professional/rogue-r1x-spot', 'width_m': 0.36, 'height_m': 0.447, 'depth_m': 0.282, 'shape': 'moving_head'}
m.build(SPEC,HERE.parent)
sys.stdout.flush(); sys.stderr.flush(); os._exit(0)
