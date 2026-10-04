# Upload and playback implementation

This is a proposed interface and runtime contract. No protocol service, compiler or firmware is implemented by the schematic packet. Hardware can operate offline only after this software is built and verified.

## App integration

Add an Export to Cue Player flow that pins show, template, venue, fixture-profile, patch and script revisions. Resolve real manufacturer channel maps and complete fixture states before compilation. Reject unresolved profiles, overlapping patches, footprints extending beyond slot 512, unsupported modes, unsafe actuator categories and duplicate output ownership.

Use a small native desktop companion for the first USB and LAN uploader. It receives an exported bundle from the SaaS app or local disk. A native Venue Volume client can later implement the same LAN transport. An ordinary hosted browser is not assumed to have raw UDP, serial access or unrestricted local HTTPS access; origin, certificate and local-network-permission handling must be designed for each supported host. The current visionOS preview channel arrays are not a device export format.

## Bundle proposal

Use a versioned `.vvshow` ZIP container with `manifest.json`, `states.bin`, `parameters.json` and `script.json`. Implement bounded streaming extraction, reject traversal and duplicate paths, cap uncompressed bytes and compression ratio, and allow only these payload entries. A prototype may use ZIP STORE only to bound decompressor complexity. Payload hashes are SHA-256 and are checked after receipt; hashes detect corruption but do not authenticate the sender.

| Manifest field | Meaning and constraint |
| --- | --- |
| formatVersion, minimumFirmware | Exact format compatibility; reject unsupported versions |
| showId, venueId, revision, displayName | Immutable identity and operator-readable selection |
| profileSetHash, patchHash | Bind playback to the reviewed fixture setup |
| universeCount | 1-8; all state records use the same universe order |
| universeOrder | Stable logical universe IDs, not implicit array labels |
| routes | Physical port A/B mapping plus Art-Net Port-Address and allowed destination configuration |
| frameRate | Revision A fixed at 40 Hz |
| baselineState, darkState | Valid complete-state record indexes |
| payloads | Exact byte lengths and SHA-256 of each allowed payload |
| scriptHash | Binds cue ordering, follows and fade policy |

`states.bin` holds complete 512-byte, 8-bit channel arrays in manifest universe order, one record per resolved target/baseline/dark state. Record stride is `512 * universeCount`; reject any length mismatch. DMX START code is not stored in these arrays. A fixture's 16-bit parameter occupies two ordered slots but interpolates as one 16-bit value, then splits into coarse/fine bytes.

`parameters.json` describes per-slot behavior: 8-bit continuous, paired 16-bit continuous, discrete switch-at-start/end, dimmer master participation and blackout policy. Do not interpolate color-wheel slots, reset macros or other discrete control channels as intensity. Unused slots have explicit fixture/profile-approved values. A universal all-zero frame is not a safe replacement for a compiled dark state: pan/tilt, shutter and control channels can behave differently.

`script.json` identifies entries independently from cue IDs, with target-state index, fade duration, hold/follow time and terminal behavior. An entry with no follow waits for GO. END holds the final state. Follow time is measured from completion of the preceding fade in this revision. Repeated references to the same cue remain different script entries. BACK/NEXT select a pending entry while held/disarmed; GO applies it. No implicit restart on select or reconnect.

Suggested initial limits: 1,000 cue entries, 8 universes, 16 MiB uncompressed bundle, 64 KiB manifest, 256 KiB script, and an explicitly bounded parameter table. At eight universes, 1,000 raw complete target states occupy 4,096,000 bytes before baseline/dark and metadata. Use one canonical state record per unique target where helpful. Admission must account for actual files, not this example alone.

## Transport and storage

LAN: the companion discovers `_venuevolume._tcp` by mDNS, with an IP entry fallback. Proposed control/upload endpoint is HTTPS on TCP 443 with a per-device certificate/public-key fingerprint provisioned at assembly and stored by the companion. Physical PAIR while disarmed opens a 60-second enrollment window; display a one-time code. Bind the enrolled controller key to the device. Prototype private-key storage is not tamper-resistant. Do not expose a port forward or require a cloud token refresh for an active show. Pinning and device-key enrollment must work with no accurate wall clock or internet certificate lookup.

Proposed operations: `GET /v1/status`, `POST /v1/uploads`, chunked `PUT /v1/uploads/{id}`, `POST /v1/uploads/{id}/verify`, `POST /v1/bundles/{hash}/activate`, and ordered control commands. Activation requires disarmed state. Status reports received, verified, selected and active separately. Fixed request/buffer limits and upload pacing prevent TLS/file work from blocking output tasks.

USB: self-powered USB CDC device, desktop companion only in the initial compatibility target. Define a framed binary stream with magic, version, message type, request ID, payload length, payload and CRC32. Bound payloads to 4 KiB, ACK by request ID, support retry/resume by committed byte offset, and verify final SHA-256. Select a real VID/PID through an authorized allocation before product distribution; do not invent one or assume module development identifiers authorize a new product. Physical USB access is trusted for prototype upload while disarmed; it does not automatically arm outputs.

Store two show slots and redundant selection records on microSD. Write and verify the inactive slot, flush storage, then commit a generation-numbered/CRC-protected selection record. Keep the previous verified bundle until the new one has survived reload. Do not assume FAT rename or an SD flush makes removal of power atomic. Test power interruption at every stage. A partially written bundle is never selected; if both selection records are invalid, boot to recovery-required with outputs disabled.

Revision A permits uploads only while disarmed. Playback reads ahead into fixed RAM buffers; it does not mount the SD card as USB mass storage. No two hosts may write the filesystem. During a show, avoid filesystem metadata writes and flash/EEPROM writes in the timing path. Maintain bounded logs in RAM and save them when disarmed.

## Runtime and output timing

Use MCU hardware timers, two independent UART transmit paths and DMA where supported. Network, SD and display activity run below frame deadlines; never bit-bang DMX from a general application loop. Preload current, target and dark states. Three eight-universe state banks require 12,288 bytes; allow more for interpolation starts, read-ahead, network buffers and TLS. One MiB module RAM is not wholly available to each memory/DMA class; validate the linker map, cache maintenance and actual worst-case allocation.

Physical output target is 250,000 bit/s, 8 data bits, no parity, 2 stop bits. Each frame contains a 120 us BREAK, 16 us mark-after-break, START code 0x00 and all 512 slots. A slot is 11 bits / 250,000 = 44 us. Total active time is `120 + 16 + 513 * 44 = 22,708 us`; at 40 Hz a 25,000 us period leaves 2,292 us of mark-before-break. Both universes can run in parallel. These are design targets; measure actual BREAK, MAB, baud error and jitter.

Art-Net uses UDP source and destination port 6454. Build ArtDmx with correct byte order, protocol version, a 512-byte channel payload and sequence 1-255 with wrap. Use 15-bit Port-Address mapping, `(Net << 8) | (SubNet << 4) | Universe`. Eight universes at 40 Hz carry 163,840 channel bytes/second before protocol/link overhead and destination fanout. Multiple unicast subscribers multiply traffic; cap the supported fanout and include it in the soak test.

Implement regular ArtPoll and subscriber tracking, then unicast ArtDmx to actual subscribers as required by the pinned Art-Net 4 specification. Do not label an ArtDmx broadcast implementation compliant with that specification. A manually configured destination for legacy non-discoverable equipment is an explicitly tested compatibility mode. ArtSync is optional and enabled only for destinations known to support it. Do not assume UDP delivery acknowledges a fixture's actual light state.

Current Art-Net revision 1.4dp deprecates Port-Address zero and specifies 1-32767. Default logical Universe 1 to wire 0:0:1 (address 1). The existing F08 example of 0:0:0 remains a selectable, warned legacy mapping; it must not silently shift an existing show. Display logical ID, Net/SubNet/Universe and numeric address together. sACN is a possible future firmware transport on the same Ethernet hardware, not a Revision A feature.

Use a locally configured static lighting-network address or DHCP with displayed fallback and conflict handling. Commission a direct link over USB first if no DHCP server exists. Persist the reviewed network profile. Document the Art-Net specification's default addressing convention when implementing factory settings; private-address venue networks and subnet masks are explicitly configured installations. Do not infer a venue subnet or send unbounded discovery outside it. Art-Net needs a LAN, not an internet gateway. Discovery packets are unauthenticated protocol traffic and must never be accepted as permission to arm or install a show.

## State and failure behavior

| Event/state | Required action |
| --- | --- |
| Boot/reset/brownout | Requests low; no ArtDmx; validate selected bundle; require ARM off then on and explicit GO |
| Ready/disarmed | Inspect and upload; outputs disabled |
| ARM switch on | Permit ready state; never start a sequence from the switch alone |
| GO | Apply pending entry once; start a new transition/follow generation |
| HOLD | Freeze transition progress and cancel pending follows; continue transmitting the frozen look |
| BLACKOUT | Latch compiled dark output; cancel follows; require explicit restore of saved state, then GO to resume |
| App, USB or internet loss | Continue the already armed local run and physical controls |
| Ethernet loss | Continue physical DMX; show network fault; do not replay missed network cues on reconnect |
| Ethernet recovery | Discover/validate destinations and send current state; do not rewind the script |
| SD read error | Hold the last complete frame, cancel follows, show fault; dark state remains in RAM |
| Watchdog reset | Output releases and recovery-required on reboot; venue fixtures' loss behavior remains external |
| End of script | Hold final complete look until explicit operator action |

BLACKOUT restoration must be a deliberate local menu action, distinct from an accidental second button edge. Restoring re-applies the saved frozen look; the operator separately resumes progression. DARK output cannot overcome another controller in an HTP merger. State names and interruption rules must agree with F11 and F17 before app implementation.

Remote commands carry command ID, session ID, selected bundle hash, operator lease ID, monotonically increasing sequence and playback generation. Deduplicate retries; reject stale sessions and late follows. A lease arbitrates remote commands locally; expiration does not stop an authorized autonomous sequence. Reconnection reads state first. Diagnostics distinguish a commanded value, a transmitted packet and any actual receiver feedback.
