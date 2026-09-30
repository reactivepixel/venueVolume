"""Validation at the explicit human/model interpretation boundary. No Blender dependency."""
import math
import re

SIDES = ('front', 'rear', 'left', 'right', 'ceiling')


def number(value, label, positive=False):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or (positive and value <= 0):
        raise ValueError(f'{label}: expected a finite {"positive " if positive else ""}number')
    return value


def vector(value, label, positive=False):
    if not isinstance(value, list) or len(value) != 3:
        raise ValueError(f'{label}: expected three numbers')
    for item in value:
        number(item, label, positive)


def validate(spec, source_hash):
    if spec.get('schema_version') != 1:
        raise ValueError('Scene specification requires schema_version: 1')
    if spec.get('source_sha256') != source_hash:
        raise ValueError('Scene specification belongs to a different movie (source_sha256 mismatch)')
    review = spec.get('review', {})
    if review.get('status') != 'reviewed' or not review.get('reviewer') or not review.get('basis'):
        raise ValueError('Specification needs review.status=reviewed, reviewer and basis; draft geometry cannot render')
    if spec.get('units') != 'meters' or not spec.get('scale_status') or not spec.get('assumptions'):
        raise ValueError('Specify units=meters, scale_status and a nonempty assumptions list')
    if not isinstance(spec.get('id'), str) or not spec['id']:
        raise ValueError('Specification needs a nonempty id')
    room = spec.get('room', {})
    for field in ('width', 'depth', 'height', 'wall_thickness'):
        number(room.get(field), 'room.'+field, True)
    for field in ('eye', 'look_at'):
        vector(spec.get('spawn', {}).get(field), 'spawn.'+field)
    if spec['spawn']['eye'] == spec['spawn']['look_at']:
        raise ValueError('Spawn eye and look_at must differ')
    recipe = spec.get('recipe')
    if recipe == 'classroom-v1':
        for field in ('windows', 'front_door', 'entrance', 'west_pier', 'rear_side_door', 'tables', 'whiteboard', 'instructor_desk'):
            if field not in spec:
                raise ValueError('classroom-v1 requires '+field)
        # This is a specific classroom recipe, not a general inference engine.
        # Validate all numeric leaves before invoking Blender.
        def numeric_tree(obj, path):
            if isinstance(obj, dict):
                for k, v in obj.items():
                    numeric_tree(v, path+'.'+k)
            elif isinstance(obj, list):
                for i, v in enumerate(obj):
                    numeric_tree(v, path+f'[{i}]')
            elif not isinstance(obj, str):
                number(obj, path)
        for field in ('windows', 'front_door', 'entrance', 'west_pier', 'rear_side_door', 'tables', 'whiteboard', 'instructor_desk'):
            numeric_tree(spec[field], field)
        if len(spec['tables']['x_centers']) < 2 or len(spec['tables']['y_centers']) < 2:
            raise ValueError('classroom-v1 validation requires at least two table rows and columns')
        previous = 0
        for win in spec['windows']:
            if not (0 <= previous <= win['y_start'] < win['y_start']+win['width'] <= room['depth'] and
                    0 < win['sill'] < win['sill']+win['height'] < room['height'] and
                    isinstance(win['panes'], int) and win['panes'] >= 1):
                raise ValueError('Invalid or overlapping classroom window bounds')
            previous = win['y_start']+win['width']
        return
    if recipe != 'boxes-v1':
        raise ValueError('Supported recipes: classroom-v1 and boxes-v1')
    materials = spec.get('materials', {})
    if not materials:
        raise ValueError('boxes-v1 requires materials')
    for key, rgb in materials.items():
        vector(rgb, 'materials.'+key)
        if any(c < 0 or c > 1 for c in rgb):
            raise ValueError('Material RGB values must be in [0,1]')
    objects = spec.get('objects', [])
    ids = set()
    sides = set()
    for obj in objects:
        ident = obj.get('id', '')
        if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_-]{0,79}', ident) or ident in ids or ident.startswith('COL_'):
            raise ValueError('Each object needs a unique safe id, excluding the COL_ prefix')
        ids.add(ident)
        vector(obj.get('position'), ident+'.position')
        vector(obj.get('size'), ident+'.size', True)
        if obj.get('material') not in materials:
            raise ValueError(ident+': unknown material')
        side = obj.get('cutaway_wall')
        if side is not None and side not in SIDES:
            raise ValueError(ident+': invalid cutaway_wall')
        sides.add(side)
        if not obj.get('evidence'):
            raise ValueError(ident+': document evidence or assumption')
    if 'floor' not in ids or not all(side in sides for side in SIDES):
        raise ValueError('boxes-v1 requires floor and geometry assigned to all four walls and ceiling')
    floor = next(o for o in objects if o['id'] == 'floor')
    if abs(floor['position'][2]+floor['size'][2]/2) > 1e-6 or not floor.get('collision'):
        raise ValueError('floor must have top at Z=0 and collision=true')


def draft(source_hash):
    return {'schema_version': 1, 'recipe': 'boxes-v1', 'id': 'new-room', 'source_sha256': source_hash,
            'review': {'status': 'draft', 'reviewer': '', 'basis': ''}, 'units': 'meters',
            'coordinates': 'Blender Z-up; origin at rear-left floor; front=+Y, rear=-Y, left=-X, right=+X',
            'scale_status': 'Unknown; supply measured or explicitly estimated dimensions',
            'room': {'width': None, 'depth': None, 'height': None, 'wall_thickness': None},
            'spawn': {'eye': [None, None, None], 'look_at': [None, None, None]},
            'materials': {'neutral': [0.5, 0.5, 0.5]}, 'objects': [],
            'assumptions': ['Populate from reference review; do not infer metric accuracy from video alone.']}
