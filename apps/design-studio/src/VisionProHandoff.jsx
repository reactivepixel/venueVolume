import React, { useState } from "react";
import { ArrowUpRight, Copy } from "lucide-react";
import { Button, Field } from "./components";
import { fixturePlacementLink } from "./vision-pro-link";

export default function VisionProHandoff({ loadout, unit }) {
  const [message, setMessage] = useState("");
  let link;
  try {
    link = fixturePlacementLink(loadout.id, unit.id);
  } catch (error) {
    return <p role="alert">{error.message}</p>;
  }
  async function copy() {
    try {
      await navigator.clipboard.writeText(link);
      setMessage("Placement link copied. Open it on Vision Pro.");
    } catch {
      setMessage(
        "Copy the link from the field below. Clipboard access is unavailable.",
      );
    }
  }
  return (
    <div className="vision-pro-handoff">
      <p>
        Open <strong>{loadout.name}</strong> in Venue Volume on Vision Pro and
        start placing <strong>{unit.name}</strong>.
      </p>
      <div className="callout warning">
        <p>
          <strong>Existing native Load Out required.</strong> This link
          identifies the Load Out and fixture; it does not transfer them.
          Automatic SaaS import and Movie2Splat scan loading in visionOS are not
          available yet. The app will explain if this Load Out is missing.
        </p>
      </div>
      <a className="button primary" href={link}>
        Open on this Vision Pro <ArrowUpRight size={16} />
      </a>
      <p className="panel-note">
        Using a computer or phone? Copy this link and open it on Vision Pro with
        the updated Venue Volume app installed. Clicking here cannot remotely
        launch a different device.
      </p>
      <Field label="Vision Pro placement link">
        <input
          readOnly
          value={link}
          onFocus={(event) => event.target.select()}
        />
      </Field>
      <Button onClick={copy}>
        <Copy size={16} />
        Copy placement link
      </Button>
      {message && <p role="status">{message}</p>}
      <p className="panel-note">
        Placement remains unchanged until you place the fixture in the app.
        Returning placement changes to SaaS still requires a future sync
        integration.
      </p>
    </div>
  );
}
