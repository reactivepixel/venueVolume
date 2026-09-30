# room2blender

A CLI pipeline for **movie references → reviewed room specification → Blender review bundle**.
It automates extraction, geometry generation, rendering, validation and reporting. It does
**not** infer a measured room or automatically identify furniture from a movie.

The checked-in classroom example is manually interpreted from the 6:37 `IMG_3153.MOV`.
Its provisional dimensions are **7.2 × 7.8 × 2.75 m**. It is a blockout for interaction
and occlusion testing, not a surveyed reconstruction.

- [Blender model](output/classroom.blend)
- [All four isometric cutaways](output/cutaways.jpg)
- [Reference contact sheet](references/contact-sheet.jpg)
- [Scene specification](room_spec.json)
- [Validation results](output/validation.json)

## Run the CLI

Requirements: Linux/macOS (or WSL), `uv`, FFmpeg/FFprobe and Blender 4.5+.
The launcher uses `uv.lock` to install the pinned Python dependencies into the app's
local `.venv`. It supports Python 3.12–3.13. The movie is never modified or uploaded.
Blender is only required for the build stage. All processing is local.

For the original classroom movie and its existing reviewed specification:

```bash
./apps/room2blender/room2blender run /path/to/IMG_3153.MOV \
  --out /path/to/classroom-review \
  --spec apps/room2blender/room_spec.json \
  --blender /path/to/blender
```

The `--spec` is bound to the source movie's SHA-256. An unrelated movie, even with
the same filename, cannot use this specification unchanged. The classroom recipe
uses its 16 curated sampling times, so its evidence links remain meaningful.

For a **new movie**:

```bash
./apps/room2blender/room2blender run /path/to/room.mov --out /path/to/new-room
```

This creates a reference contact sheet, individual frames, capture provenance, and
`room_spec.<source-hash>.draft.json`, then reports **review_required** (exit code 3).
No fabricated room model is generated. Review the images, fill in geometry and
assumptions, and record `review.status: "reviewed"`, `reviewer`, and `basis`.

```bash
./apps/room2blender/room2blender build /path/to/new-room \
  --spec /path/to/reviewed-room.json --blender /path/to/blender
```

The `build` command uses the saved capture and does not need the original movie.
The final console line links to the run's **index.html**, which can be opened locally
without a server. `status.json` points to the current bundle.

Useful options:

| Option | Meaning |
|---|---|
| `--count 16` | Uniform time bins for a new capture; 1–128 bins |
| `--times 3,12,24` | Explicit sampling times; overrides specification sampling times |
| `--width 1440` | Render width; height is 3/4 of width |
| `--samples 32` | Fixed Cycles sample count; use 8 for quick reviews |
| `--device cpu` | Default; avoids unpredictable competition for GPU memory |
| `--device cuda` | Explicit CUDA rendering; fails visibly if unavailable or out of memory |
| `--blender PATH` | Blender executable; otherwise `BLENDER_BIN`, then PATH |

If the specification includes `reference_times`, they take precedence over `--count`.
Use its original times when evidence names refer to specific extracted frames.
Exit codes: **0** complete, **3** reference review needed, **1** processing failure,
**2** invalid command syntax/options. Logs from failed attempts are retained in
`failures/`; a failed stage never publishes a complete bundle.

## Expected output contract

```text
PROJECT/
  status.json
  room_spec.<hash>.draft.json       # new captures without a specification
  captures/<capture-fingerprint>/
    references/                    # images, manifest, contact sheet
    provenance.json
    artifacts.json                 # checksums of published reference artifacts
  runs/<run-fingerprint>/
    index.html                     # local review gallery and assumptions
    room_spec.json                 # exact reviewed input
    provenance.json                # versions, settings, source and script hashes
    artifacts.json                 # checksums; detect edited/missing outputs
    references/                    # self-contained reference copy
    logs/                          # build, render and validation logs
    output/
      room.blend                   # six scenes, packed references, editable meshes
      interior.png
      floor-plan.png
      cutaway-front-left.png
      cutaway-front-right.png
      cutaway-rear-right.png
      cutaway-rear-left.png
      cutaways.jpg                 # labeled 2×2 review sheet
      cutaway.png                  # compatibility alias of rear-left view
      placement.json
      geometry.json                # canonical geometry digest and object records
      validation.json
      occlusion*.png               # additional tests in classroom-v1 recipe
```

Each isometric camera has equal X/Y/Z displacement from the room center
(35.264° elevation), identical framing, and a named corner. Its nearest two walls,
including assigned wall-mounted trim, and the ceiling are excluded from that scene.
The full interior scene retains all geometry. These are six views of **shared editable
objects**, not six independent copies of the room.

Repeat the same command to reuse a checksum-verified bundle. Changing source bytes,
sampling, specification, generator scripts, render settings or recorded tool versions
selects a new fingerprint. Existing runs are retained. One process can write a project
at a time. No `--force` silently discards manual changes: if you edit a published model,
save it separately or choose a new output project before regenerating.

## The interpretation boundary

| Step | What is repeatable | What still needs judgment or measurement |
|---|---|---|
| Decode and sample | Fixed time bins, three nearby candidates, stable ordering, fixed resize/tone map | Damaged recordings may skip frames; timestamps are requested seek positions |
| Pick a reference | Clean-decode preference, then Laplacian sharpness | Sharpness does not guarantee useful coverage or absence of people/reflections |
| Describe the room | Versioned JSON, explicit evidence and assumptions, source hash | Shape, room dimensions, hidden surfaces, openings, furniture count and positions |
| Build meshes | The same reviewed JSON and generator produce the same geometry | A deterministic model can still be the wrong interpretation of the room |
| Render | Seed 0, fixed cameras, sample count, color management, recorded backend | Blender/driver/CPU differences and denoising can alter pixels; `.blend` bytes are not guaranteed identical |
| Validate | Scene, geometry, placement, occlusion and artifact checks | Internal consistency is not proof of physical accuracy |

An AI interpretation stage could later propose the same JSON schema, but that stage
would remain probabilistic. Save the proposed JSON, model/prompt version and evidence,
review it once, and freeze the reviewed specification for all subsequent builds.
This release makes that boundary explicit; it does not invoke an external AI API.

**Strongest next accuracy improvement:** measure room width, depth, ceiling height
and one table dimension. More photos are useful if a wall or doorway is missing from
the footage, but additional photos do not by themselves establish metric scale.

## Specifications and recipes

`classroom-v1` preserves the original classroom model, including simplified desks,
chairs, cabinet, projector, windows and doors. Its parameters are editable, but the
recipe also contains classroom-specific details. Do not use it as a generic room detector.
Its Y inputs are distances from the front teaching wall; Blender output converts these
to `depth-Y`. Dimensions remain unmeasured assumptions.

`boxes-v1` supports other rooms as explicitly described boxes. Start from
[examples/box-room.template.json](examples/box-room.template.json). **Its dimensions are
invented examples**: replace the source hash, geometry and evidence, then review it.
The automatically generated draft uses null dimensions to avoid suggesting a fake fit.

Each box has a stable `id`, `position`, positive `size`, `material`, `evidence`, and optional
`collision`, `placement_surface`, and `cutaway_wall`. Coordinates are **meters, Z-up**,
with front=+Y, rear=-Y, left=-X, right=+X. Assign outer wall segments and attached trim
to the matching side. Use several boxes around door/window openings; a single unbroken
wall box will block the opening. Furniture normally has no `cutaway_wall`. A `floor`
with top at Z=0 and a collision proxy, plus all four wall groups and a ceiling, are required.

The JSON specification is the reproducible modeling source. Manual Blender edits persist
in a saved `.blend`, but are not automatically converted back into the specification.
Likewise, `placement.json` records generated initial positions, not later viewport edits.

## Inspect in Blender

Open `room.blend` (or the checked-in `output/classroom.blend`) in Blender 4.5+.
The scene selector contains the full room, four corner cutaways and a floor plan.
Use **Numpad 0** or **View → Cameras → Active Camera** for the active scene camera.
Use **View → Navigation → Walk Navigation** (Shift + grave accent), WASD and mouse
look to navigate. Gravity-disabled Q/E changes height. Left-click/Enter confirms;
Esc cancels. The original classroom includes a separate movable test fixture on the
desk and a cyan occlusion probe behind the wall projection.

Collision proxies are excluded and hidden by default; they are preparation for an
application's physics setup, not configured Blender physics. The output remains a
Blender prototype. No Vision Pro runtime or automatic USDZ export is added here.

## Development and verification

```bash
uv run --locked --project apps/room2blender python -m unittest discover \
  -s apps/room2blender/tests -v

# Include real FFmpeg and Blender runs, cache checks and independent repeatability:
BLENDER_BIN=/path/to/blender uv run --locked --project apps/room2blender \
  python -m unittest discover -s apps/room2blender/tests -v
```

The integration test uses a short generated movie and a clearly synthetic reviewed
room. It checks the review boundary, build and four cutaways, cache reuse, settings
invalidation, independently reproduced reference bytes/geometry digest, and refusal
to overwrite modified artifacts. The classroom validator additionally tests desk contact,
wall occlusion and its rendered before/after comparison. Source/movie accuracy is not
established by these tests.

To regenerate only the checked-in classroom example from its saved references:

```bash
cd apps/room2blender
blender -b --python-exit-code 1 --python scripts/build_room.py -- --cpu
blender -b output/classroom.blend --python-exit-code 1 --python scripts/validate_room.py
```

The CLI is the preferred workflow for new captures; it supplies version records,
separate output directories, caching and the HTML review gallery.
