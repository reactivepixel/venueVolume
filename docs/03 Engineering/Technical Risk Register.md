---
type: risk-register
status: active
owner: engineering
updated: 2026-09-19
---

# Technical Risk Register

| Risk | Why it matters | Early test | Status |
| --- | --- | --- | --- |
| Output jitter under UI/CPU load | Visible stutter is unacceptable during live operation | Stress-test frame scheduling while rendering and saving | Open |
| USB interface fragmentation | Drivers and protocols vary by vendor and OS | Compatibility spike across candidate interfaces | Open |
| Incomplete fixture data | Bad channel metadata creates unsafe or confusing output | Model a diverse fixture test set | Open |
| Conflicting control sources | Playback, manual controls, and effects may fight | Prototype explicit value ownership/merge rules | Open |
| Crash or power loss corrupts a show | Users may lose irreplaceable programming | Fault-injection tests around persistence | Open |
| Network discovery and loss behavior | Venues may have unreliable or shared networks | Test loss, duplication, reordering, and reconnects | Open |
| OS scheduling and sleep behavior | General-purpose computers are not real-time systems | Measure on all candidate platforms | Open |
| Unsafe defaults | Some DMX values trigger movement, strobes, resets, or lamps | Define capability-aware defaults and warnings | Open |

Review this table when an experiment closes or a design decision changes exposure.

