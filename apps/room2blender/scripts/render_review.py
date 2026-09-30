"""Render a previously built review bundle, using saved scene settings."""
import argparse
from pathlib import Path
import sys
import bpy
sys.path.insert(0, str(Path(__file__).resolve().parent))
from review_views import render_all
p = argparse.ArgumentParser()
p.add_argument('--project', type=Path, required=True)
a = p.parse_args(sys.argv[sys.argv.index('--')+1:])
render_all(a.project.resolve(), Path(bpy.data.filepath))
