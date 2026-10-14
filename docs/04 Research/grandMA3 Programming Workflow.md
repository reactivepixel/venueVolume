# grandMA3 programming workflow

Research date: 13 October 2026. This note supplements the earlier palette research with the current recipe and macro workflow. It informs Venue Volume; it does not specify grandMA3 command compatibility or claim hardware testing.

## Recommended operator sequence

Use **Select → Palette → Phaser → Apply**, then offer **Save as macro** for a repeatable combination. Keep the fixture target visible throughout. This is a Venue Volume adaptation of MA's selection, preset-reference, recipe, and macro concepts, not a reproduction of the console programmer.

1. **Select fixtures or a named group.** MA groups preserve fixture selection and order. Group selection is therefore part of programming, not merely a label on a collection. See [Quick Start: Groups](https://help.malighting.com/grandMA3/2.5/HTML/qsg_group.html).
2. **Choose the attribute pool and a named static palette.** Ordinary MA preset pools filter by feature group; referenced preset changes can update dependent cues. Useful defaults include open white and home position. Preserve independent Color, Dimmer, Position, and Beam ownership in Venue Volume. See [Quick Start: Presets](https://help.malighting.com/grandMA3/2.5/HTML/qsg_presets.html).
3. **Add motion through numbered steps.** MA's current Edit Recipe flow selects groups, recalls a preset, advances to the next step, and recalls another preset of the same attribute. Incompatible presets are disabled. The resulting recipe can be stored into a cue or preset. See [Edit Recipe Mode](https://help.malighting.com/grandMA3/2.5/HTML/edit-recipe-mode.html).
4. **Adjust form, timing, and fixture distribution separately.** The sinus tutorial creates two dimmer preset steps, adjusts their form, then distributes fixtures across the phase. It recommends using presets as building blocks. See [Create a Sinus Dimmer Phaser](https://help.malighting.com/grandMA3/2.5/HTML/phaser_create_dimmer.html).
5. **Inspect output, store, and apply.** MA distinguishes selected step values from actual dynamic output and stores a phaser as a named reusable preset. Show both step values and animated fixture output in Venue Volume. See [Quick Start: Phasers](https://help.malighting.com/grandMA3/2.5/HTML/qsg_phasers.html).
6. **Automate established actions.** A console macro is an ordered list of commands, with line-level enable and wait behavior. It accelerates a known workflow; it should not obscure its target or actions. See [Macros](https://help.malighting.com/grandMA3/2.5/HTML/macros.html).

## What to carry into the editor

| Console concept | Evidence | Venue Volume recommendation |
| --- | --- | --- |
| A preset is a reusable reference | [Presets](https://help.malighting.com/grandMA3/2.5/HTML/presets.html) distinguishes referenced content, extracted values, embedded presets, and fixture-resolution modes. | Use persistent IDs for palette and step-source references. A renamed source must remain linked. Show its name and pool; do not silently flatten it. |
| Static preset values can become phaser steps | [Integrate](https://help.malighting.com/grandMA3/2.5/HTML/keyword_integrate.html) brings step 1 of a source preset into another programmer step. | A selected step offers a compatible static palette source or explicit custom values. Do not offer arbitrary nested dynamic sources until dependency rules are supported. |
| Recipes separate target, values, and distribution | [Quick Start: Recipes](https://help.malighting.com/grandMA3/2.5/HTML/qsg_recipes.html) explains selection plus value plus application rules, and re-cooking after source changes. | Make target, palette source, and distribution independently editable. Use recipe-like composition internally without claiming a complete MA recipe engine. |
| Preset-reference and recipe-reference behavior differ | [Recipe Presets](https://help.malighting.com/grandMA3/2.5/HTML/presets_recipes.html) distinguishes presets with/without a stored selection and recipe templates loaded into the programmer. | Label a reusable current-selection action differently from one bound to a group. Do not bake the current fixture count into a reusable group macro. |
| Overall shape differs from step curve | [Recipe Editor](https://help.malighting.com/grandMA3/2.5/HTML/recipe-sheet.html) gives the whole phaser a shape and each step a curve/value source. | Wave, Breathe, and Pulse belong in overall pattern choices. Hold, fade, intensity, source, and recently used step settings belong beside the selected step. |
| Relative movement can layer on an absolute position | [Circle around a position preset](https://help.malighting.com/grandMA3/2.5/HTML/phaser_create_circle_preset.html) demonstrates this combination. | Do not label an absolute circle template as relative movement. Expose additive/relative controls only when the engine actually supports them. |

The 2.5 release further improves the group → template workflow and phaser recipes in Edit Recipe mode. It requires a single group and a template without its own stored selection for automatic group/template combination. See [Features 2.5](https://help.malighting.com/grandMA3/2.5/HTML/rn_features-2-5.html). A first Venue Volume implementation should keep that scope explicit instead of inferring targets from whatever was last selected.

## Timing semantics to preserve or deliberately change

The [Phasers manual](https://help.malighting.com/grandMA3/2.5/HTML/phaser.html) defines:

| Control | MA meaning |
| --- | --- |
| Speed | Overall beat rate, displayed in BPM, Hz, or seconds per beat. |
| Width | Step duration as a percentage of one beat. |
| Transition | Fraction of step width used to reach the new value, followed by a hold at that value. |
| Accel / Decel | Shape of the departure and arrival portions of a transition. |
| Phase | Per-fixture/attribute timing offset in degrees. |
| Measure | Optional number of beats in the complete repeating loop. Four beats at 120 BPM is two seconds. |

The earlier Venue Volume research records normalized step-width ratios and a hold-then-interpolate transition. Those are different timing semantics. Do not silently relabel that engine as console-equivalent. Either retain precise app wording, or migrate the sampler and its tests together. A practical app model can explicitly define **BPM + beats per cycle + relative step duration**, with the resulting cycle seconds visible.

The tap-tempo ring should modify BPM only. Changing step count must not unexpectedly change the selected loop duration. Bar shortcuts should state the time signature (for example, 1 bar at 4/4 = 4 beats). These are app interaction decisions, not separate MA parameter names. A full-circle fixture spread should avoid duplicating 0° at 360°; the [Quick Start phaser tutorial](https://help.malighting.com/grandMA3/2.5/HTML/qsg_phasers.html) explains that endpoint adjustment.

## A useful first macro workflow

MA's [macro tutorial](https://help.malighting.com/grandMA3/2.5/HTML/qsg_macros.html) demonstrates one-command and multi-line macros, maintaining/restoring a selection, waiting between dependent operations, and a nonexecuting command-line mode. [Create Macros](https://help.malighting.com/grandMA3/2.5/HTML/macro_create.html) provides separate tests for one line and the whole macro. Venue Volume should adopt inspectable, named operations rather than accept arbitrary strings that look like working MA commands.

Recommended app contract:

- A macro has a name, explicit target (**Current selection** or **Named group**), and ordered action rows.
- Initially support actions the existing model can execute honestly: apply a saved palette, set intensity, set supported phaser timing/distribution, or clear a supported attribute assignment. Rows can be enabled/disabled and reordered. Unsupported action types should not appear.
- Resolve a named group when running, then snapshot its target IDs for the entire run. Current-selection macros require a nonempty current selection. Missing groups, palettes, or incompatible references fail before any mutation; never substitute all fixtures.
- Validate all enabled rows first, execute deterministically, and group the result into one Undo operation. Show the resolved fixture count and a readable action summary before Run. These transaction guarantees are Venue Volume design decisions, not properties asserted about MA macros.
- Favor explicit **set** values over toggles in starter macros, so repeated runs produce the same programmed state. Avoid macros that append duplicate palettes/groups or mutate temporary numbered objects.
- Store references by stable object ID. Renaming a palette/group should not break a macro. Deletion must identify dependent macros or leave a visible missing-reference error.
- Do not claim Wait/Go, console CLI, variables, nested macro calls, DMX output, or show-file import unless implemented. MA supports these more advanced patterns; its [macro examples](https://help.malighting.com/grandMA3/2.5/HTML/macro_examples.html) also show why nested invocation has distinct lifecycle behavior.

Suggested starter combinations: **Full warm wash** (Dimmer Full + warm Color), **Cool breathing wash** (Breathe dimmer phaser + cool Color), and **Selected fixtures out** (explicit intensity 0). Names should describe the result and scope. These are app templates, not MA factory macro names.

## Boundaries and checks

MA's ordinary preset input filters do **not** describe recipe storage: Edit Recipe mode stores all recipe rows of the selected programmer part even when the destination is a feature-group pool. Venue Volume's strict per-pool channel ownership is a deliberate simplification. See [Edit Recipe Mode](https://help.malighting.com/grandMA3/2.5/HTML/edit-recipe-mode.html).

Verify the implemented workflow against these app requirements: a source edit reaches linked steps; Color application leaves intensity alone; applying affects only the resolved target; group order is deterministic; empty/missing references block without partial changes; disabled macro rows do nothing; running twice does not append objects; one Undo restores the full pre-run state. Do not expose selective/global/universal preset modes or MAtricks grids unless supported by the data model.

## Tutorial access and version notes

All technical claims above follow first-party MA manuals and written tutorials. The official [MA University video catalogue](https://www.malighting.com/ma-university/video-tutorials/) links to the [grandMA3 MA Tips playlist](https://www.youtube.com/watch?list=PL4Z9H4cy8XwxpV9wMLUWeuhKWY2TI_ipT&v=EuIxM58dsbM). YouTube retrieval was throttled, so this note does not claim to have watched that playlist. The inspected manual tutorials also embed demonstrations for [sinus dimmer programming](https://player.vimeo.com/video/941921800) and [Edit Recipe mode](https://player.vimeo.com/video/1211365945); the written instructions provide the verified workflow used here.

The inspected URLs use the 2.5 manual. Some unchanged articles, including Phasers and Recipe Editor, display a 2.4 topic version within that current manual. This distinction is intentional; these findings are not inferred from older third-party grandMA2 tutorials.
