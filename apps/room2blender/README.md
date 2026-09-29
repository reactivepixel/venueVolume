# room2blender — classroom reference blockout

Open **[output/classroom.blend](output/classroom.blend)** in Blender 4.5 or newer.
This is an editable, manually interpreted model of the unoccupied classroom in
`IMG_3153.MOV`. It is **not an automatically reconstructed scan or a measured plan**.
The room is provisionally **7.2 × 7.8 × 2.75 meters**. Every dimension needs verification.

## Inspect and walk through

The scene selector at the top of Blender provides:

- **01 | ROOM**: complete room, starting in the central aisle, with the test fixture selected.
- **02 | CUTAWAY**: ceiling and two walls hidden for layout review; shares the same objects.
- **03 | PLAN**: top view of the estimated layout.

Use **Numpad 0** for the scene camera. With the pointer over the 3D viewport, use
**Shift + `** (grave accent) or **View → Navigation → Walk Navigation**, then WASD
and mouse look. Q/E adjust height with gravity disabled; mouse wheel changes speed.
Left-click/Enter confirms; Esc cancels. This is Blender navigation, not a headset app.
If no numpad is available, use **View → Cameras → Active Camera**.

The amber-and-black **TEST_fixture_on_instructor_desk** is a separate movable mesh,
with its origin at its base. Its base rests on the instructor desk at Z=0.74 m.
Use G to move it and Shift+Tab / the snapping menu to enable **Face** snapping.
Save the `.blend` to persist edits. Rebuilding from the specification overwrites
the generated file, so save a copy before making manual edits.

The cyan **TEST_occlusion_cube** is behind the west wall projection. Compare
`output/occlusion.png` with `output/occlusion-reveal.png`: the same camera is used,
and only that projection is removed in the reveal. The normal saved scene retains it.
`output/placement.json` records the generated initial asset transforms. It is not
automatically updated by manual Blender edits; the `.blend` is the editable source.

## What the movie establishes

[references/contact-sheet.jpg](references/contact-sheet.jpg) contains 16 selected
views spanning approximately 6–371 seconds of the 397.38-second movie.
All selected images are also **packed inside the `.blend`** and available in an
Image Editor dropdown. The specification, extraction manifest, and this guide
are embedded in Blender's Text Editor.

Observed: sage front/window walls, ivory opposite walls, gray carpet, high windows
in two banks, front whiteboard and solid door, glazed west entrance, a west wall
projection, rear-side door, training tables and rolling chairs, wood AV cabinet,
instructor desk, speakers, ceiling grid, recessed lighting and ceiling projector.

Estimated: overall dimensions, exact wall setbacks, openings, furniture dimensions,
table/chair count and positions, ceiling grid spacing and equipment placement.
The nine-table arrangement is a test approximation, not an inventory. Glazing is
opaque for this blockout. The hallway, outside the windows, hidden recesses, wiring,
and unseen door interiors are not modeled. Small controls, cables, and clutter are
omitted. Two synthetic test assets are clearly named separately from observed objects.

`room_spec.json` contains editable dimensions, positions, reference-image mappings,
and explicit assumptions. Changing the envelope alone does not re-layout furniture:
update relevant object positions as well. A measured room width/depth/height and one
table dimension would be the most useful next inputs. No new photos are needed for
this first blockout; additional sharp photos would help resolve missing details.

## Model organization and downstream use

Geometry is split into named architecture, ceiling, furniture, equipment, test-asset,
and collision-proxy collections. Doors are closed separate objects; window openings
are built from wall segments. The rear-side door is a decorative closed placeholder
over the wall until its opening is measured. Collision proxies are simple separate
surface boxes, never one solid volume around the entire room. Their collection is
excluded by default and hidden in rendering; enable it and unhide its objects to inspect.
It is metadata/preparation for a future application, not configured Blender physics.

Output units: meters. Origin: rear-left floor corner; +X toward windows, +Y toward
the front teaching wall, +Z upward. The JSON specification uses Y distances from
the teaching wall for convenient layout; the generator converts them to `depth-Y`. For future Y-up RealityKit ingestion, map `(x,y,z)` to `(x,z,-y)`.
This milestone does **not** add a Vision Pro runtime, USDZ exporter, gesture controls,
or persistent room anchors. Blender provides inspection, editing, native depth
occlusion, and saved object placement for this test.

## Regenerate

Requirements: Blender 4.5+ for modeling. Python, FFmpeg/FFprobe, and the optional
packages below are needed only to re-extract movie references.

```bash
cd apps/room2blender
blender --background --python-exit-code 1 --python scripts/build_room.py
blender --background output/classroom.blend --python-exit-code 1 --python scripts/validate_room.py
```

Use `-- --no-render` on the build command to skip previews, or `-- --cpu` if the
GPU is busy or short of memory. Rendering uses Cycles
and selects CUDA when available, otherwise CPU. The checked-in model was built
with Blender **4.5.14 LTS**; the local downloaded runtime is excluded from Git.

```bash
uv venv .venv
uv pip install --python .venv/bin/python -r requirements.txt
.venv/bin/python scripts/extract_references.py /path/to/IMG_3153.MOV
```

The script examines three candidate frames near each selected time and prefers
clean decodes before choosing by sharpness. Review the resulting contact sheet:
sharpness alone does not prove a frame is suitable. The iPhone HLG/BT.2020 footage
is tone mapped to BT.709 SDR. Decoding warnings are retained locally in
`.cache/candidates`; selected-frame statistics, source SHA-256, and requested seek
positions are in `references/manifest.json`. Damaged regions can skip frames, so
those positions are approximate, not calibrated camera timestamps.

The source movie was found in the user's Trash and read without moving or modifying
it. Its location is deliberately not hardcoded in the scripts, and the video is not
included in Git. Saved reference images and the packed Blender file stand alone.

## Validation

`scripts/validate_room.py` reopens the saved file and checks packed images, room
units, object persistence, fixture contact, finite transforms, closed collision
proxy meshes, ray hits on the floor and desk, and pier occlusion of the test cube.
It writes `output/validation.json`. Rendered interior, cutaway, plan, and occlusion
comparison images are reviewed separately. These checks validate the artifact's
internal geometry; they do not establish real-world dimensional accuracy.
