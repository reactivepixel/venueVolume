import { normalizeScript, patchErrors } from "./model.js";

export const clamp = (n) => Math.max(0, Math.min(100, Number(n) || 0));
export function scriptSegments(entries) {
  return entries.reduce((segments, entry) => {
    if (segments.at(-1)?.song !== entry.song)
      segments.push({ song: entry.song, entries: [] });
    segments.at(-1).entries.push(entry);
    return segments;
  }, []);
}
export function makeSnapshot(data, venue) {
  const presets = data.presets.map((p) =>
    p.name === "Midnight blue"
      ? { ...p, intensity: data.venueOverrides?.[venue] ?? data.intensity }
      : p,
  );
  const roles = [...new Set(data.fixtures.map((f) => f.role))];
  const script = normalizeScript(data.script).map((entry, i) => ({
    ...entry,
    song:
      entry.song ||
      (i === 0 ? "Walk-in" : i < 4 ? "01 · Into the blue" : "02 · Afterglow"),
    offset: entry.offset ?? (i === 0 ? 0 : i < 4 ? (i - 1) * 45 : (i - 4) * 60),
    midi: data.venueProgramming?.[venue]?.midiMappings?.[entry.entryId] ??
      entry.midi ?? { type: "note", channel: 1, number: 60 + i },
    assignments:
      entry.assignments ||
      roles.map((role, j) => ({
        role,
        preset:
          j === 0 ? entry.preset : j === 1 ? "Soft front key" : "Violet bloom",
      })),
  }));
  const houseEntryId = data.venueProgramming?.[venue]?.houseEntryId ??
    script.find((entry) => entry.name === "House open")?.entryId ?? null;
  return { fixtures: data.fixtures, presets, script, houseEntryId };
}
export function createRun(snapshot) {
  return {
    snapshot,
    armed: false,
    held: false,
    blackout: false,
    connected: true,
    master: 100,
    groupMasters: {},
    programmer: {},
    activeId: null,
    activeValues: {},
    hits: {},
    history: [],
    pass: 1,
    midiEnabled: false,
    lastMessage: "Ready · no cue called",
    serial: 0,
  };
}
export function cueValues(snapshot, entry) {
  const result = {};
  for (const f of snapshot.fixtures) {
    const assignment = entry?.assignments.find(
      (a) => a.role === f.role || a.fixtureId === f.id,
    );
    const preset = snapshot.presets.find((p) => p.name === assignment?.preset);
    result[f.id] = {
      intensity: preset?.intensity ?? 0,
      color: preset?.color ?? "#dfe9f2",
      pan: 50,
      tilt: 50,
    };
  }
  return result;
}
export function outputValue(run, fixture) {
  const base = run.activeValues[fixture.id] || {
    intensity: 0,
    color: "#dfe9f2",
    pan: 50,
    tilt: 50,
  };
  const value = { ...base, ...run.programmer[fixture.id] };
  const effective =
    run.blackout || !run.armed
      ? 0
      : Math.round(
          (((value.intensity * run.master) / 100) *
            (run.groupMasters[fixture.role] ?? 100)) /
            100,
        );
  return {
    ...value,
    effective,
    manual: !!run.programmer[fixture.id],
    unknown: !run.connected,
  };
}
export function midiMatches(mapping, bytes) {
  if (!mapping || !bytes?.length) return false;
  const [status, number, value] = bytes,
    type = status & 0xf0,
    channel = (status & 15) + 1;
  if (channel !== mapping.channel || number !== mapping.number) return false;
  return mapping.type === "note"
    ? type === 0x90 && value > 0
    : mapping.type === "cc"
      ? type === 0xb0 && value > 0
      : type === 0xc0;
}
export function nextMidiEntry(run, bytes) {
  const index = run.snapshot.script.findIndex(
    (e) => e.entryId === run.activeId,
  );
  // Forward-only matching prevents duplicate Note On packets from recalling a hit entry.
  return run.snapshot.script.find(
    (e, i) => i > index && !run.hits[e.entryId] && midiMatches(e.midi, bytes),
  );
}
export function reduceRun(run, action) {
  const blocked = !run.armed || run.held || run.blackout || !run.connected;
  const notice = (message) => ({
    ...run,
    lastMessage: message,
    serial: run.serial + 1,
  });
  switch (action.type) {
    case "arm":
      return patchErrors(run.snapshot.fixtures).length || !run.connected
        ? notice("Arming blocked: inspect patch and connection")
        : { ...run, armed: !run.armed, held: false, midiEnabled: false };
    case "hold":
      return !run.armed ? notice("Arm before changing playback hold") : {
        ...run,
        held: !run.held,
        lastMessage: run.held
          ? "Playing · cue input resumed; waiting for the next cue"
          : "Held · current cue retained; incoming cues discarded until Play",
      };
    case "blackout":
      return { ...run, blackout: !run.blackout };
    case "connection":
      return {
        ...run,
        connected: action.value,
        armed: false,
        midiEnabled: false,
        lastMessage: action.value
          ? "Connection restored · re-arm explicitly"
          : "Bridge disconnected · actual output unknown",
      };
    case "master":
      return { ...run, master: clamp(action.value) };
    case "group":
      return {
        ...run,
        groupMasters: {
          ...run.groupMasters,
          [action.role]: clamp(action.value),
        },
      };
    case "midi-enabled":
      return { ...run, midiEnabled: action.value };
    case "message":
      return notice(action.message);
    case "programmer": {
      const programmer = { ...run.programmer };
      for (const id of action.ids) {
        const f = run.snapshot.fixtures.find((f) => f.id === id);
        if (!f) continue;
        const current = outputValue(run, f);
        const values = { ...action.values };
        if (action.nudge !== undefined)
          values.intensity = clamp(current.intensity + action.nudge);
        programmer[id] = { ...programmer[id], ...values };
      }
      return { ...run, programmer };
    }
    case "release": {
      const programmer = { ...run.programmer };
      for (const id of action.ids || Object.keys(programmer))
        delete programmer[id];
      return { ...run, programmer };
    }
    case "apply-draft": {
      if (
        run.armed &&
        JSON.stringify(run.snapshot.fixtures) !==
          JSON.stringify(action.snapshot.fixtures)
      )
        return notice("Disarm before applying fixture or patch changes");
      if (
        run.activeId &&
        !action.snapshot.script.some((e) => e.entryId === run.activeId) &&
        run.armed
      )
        return notice("Disarm before removing the active script entry");
      return {
        ...run,
        snapshot: action.snapshot,
        lastMessage:
          "Draft applied to future cue calls · current look and programmer retained",
        serial: run.serial + 1,
      };
    }
    case "midi": {
      if (!run.midiEnabled || blocked)
        return notice(
          "MIDI ignored · input gated by arm, hold, blackout, or connection",
        );
      const entry = nextMidiEntry(run, action.bytes);
      if (!entry) return notice("MIDI received · no pending matching cue");
      return reduceRun(run, {
        type: "call",
        entryId: entry.entryId,
        source: "MIDI",
        at: action.at,
      });
    }
    case "house":
      return run.snapshot.houseEntryId
        ? reduceRun(run, { ...action, type: "restart", entryId: run.snapshot.houseEntryId, source: "House" })
        : notice("No house cue configured for this venue");
    case "back": {
      if (blocked) return notice("Back blocked · arm, connection, hold, or blackout");
      const index = run.snapshot.script.findIndex((e) => e.entryId === run.activeId);
      if (index < 1) return notice("Start of script · no previous cue");
      // Rewind playback eligibility, retaining the event log for audit.
      return reduceRun(run, { ...action, type: "restart", entryId: run.snapshot.script[index - 1].entryId, source: "Back" });
    }
    case "next":
    case "go": {
      const index = run.snapshot.script.findIndex(
        (e) => e.entryId === run.activeId,
      );
      const next = run.snapshot.script[index + 1];
      return next
        ? reduceRun(run, { ...action, type: "call", entryId: next.entryId })
        : notice("End of script · final state held");
    }
    case "restart": {
      if (blocked)
        return notice("Restart blocked · release hold/blackout and arm");
      const index = run.snapshot.script.findIndex(
        (e) => e.entryId === action.entryId,
      );
      if (index < 0) return run;
      const hits = { ...run.hits };
      run.snapshot.script.slice(index).forEach((e) => delete hits[e.entryId]);
      return reduceRun(
        { ...run, hits, pass: run.pass + 1 },
        {
          type: "call",
          entryId: action.entryId,
          source: action.source || "Restart",
          at: action.at,
        },
      );
    }
    case "call": {
      if (blocked)
        return notice("Cue blocked · arm, connection, hold, or blackout");
      const entry = run.snapshot.script.find(
        (e) => e.entryId === action.entryId,
      );
      if (!entry) return notice("Cue reference no longer exists");
      const event = {
        entryId: entry.entryId,
        name: entry.name,
        source: action.source || "Operator",
        at: action.at || Date.now(),
        pass: run.pass,
      };
      return {
        ...run,
        activeId: entry.entryId,
        activeValues: cueValues(run.snapshot, entry),
        hits: { ...run.hits, [entry.entryId]: event },
        history: [...run.history, event].slice(-100),
        lastMessage: `${entry.id} called by ${event.source}`,
        serial: run.serial + 1,
      };
    }
    default:
      return run;
  }
}
