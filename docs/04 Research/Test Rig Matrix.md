---
type: research
status: draft
owner: engineering
updated: 2026-09-19
---

# Test Rig Matrix

Use this as the inventory and coverage map for repeatable device testing.

## Interfaces

| Device | Transport | Protocol/driver | OS | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| _TBD_ | USB or Ethernet | _TBD_ | _TBD_ | Planned | |

## Fixtures

Choose devices that exercise different data shapes and safety concerns.

| Fixture class | Capabilities to cover | Device | Mode | Status |
| --- | --- | --- | --- | --- |
| Dimmer | Single 8-bit intensity | _TBD_ | _TBD_ | Planned |
| LED wash | RGB/RGBW, dimmer, strobe | _TBD_ | _TBD_ | Planned |
| Moving head | 16-bit pan/tilt, color, gobo, reset ranges | _TBD_ | _TBD_ | Planned |
| Multi-cell fixture | Repeated cells and large footprint | _TBD_ | _TBD_ | Planned |

## Measurements

- Output frame interval and jitter
- Input-to-output latency distribution
- CPU and memory usage during stress
- Disconnect detection and recovery time
- Behavior across sleep/wake and network changes
- Long-running stability and dropped/error frames

