import { useEffect, useState } from "react";

export const DEFAULT_MAX_BYTES = 10 * 1024 ** 3;
export const movieAccept = ".mov,.mp4,.m4v,video/quicktime,video/mp4,video/x-m4v";

export function movieError(file, maximum = DEFAULT_MAX_BYTES) {
  if (!file) return "Choose a movie to upload.";
  if (!/\.(mov|mp4|m4v)$/i.test(file.name)) return "Choose a MOV, MP4, or M4V movie.";
  if (!file.size) return "This movie is empty. Choose another recording.";
  if (file.size > maximum) return `Choose a movie smaller than ${formatBytes(maximum)}.`;
  return "";
}

export function formatBytes(bytes) {
  return bytes >= 1024 ** 3 ? `${(bytes / 1024 ** 3).toFixed(1)} GB`
    : bytes >= 1024 ** 2 ? `${(bytes / 1024 ** 2).toFixed(1)} MB`
      : `${Math.max(1, Math.ceil(bytes / 1024))} KB`;
}

export async function venueRequest(path = "", options = {}) {
  let response;
  try {
    response = await fetch(`/api/venues${path}`, {
      ...options,
      headers: { "Content-Type": "application/json", ...options.headers },
    });
  } catch (error) {
    if (error.name === "AbortError") throw error;
    throw new Error("Cannot reach the venue intake service. Check the connection and try again.");
  }
  const data = await response.json().catch(() => null);
  if (!response.ok || !data) {
    throw new Error(data?.error || "The venue intake service is unavailable. Start it and try again.");
  }
  return data;
}

export function uploadMovie(id, file, onProgress, signal) {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    const abort = () => xhr.abort();
    const finish = (error, result) => {
      signal.removeEventListener("abort", abort);
      if (error) reject(error); else resolve(result);
    };
    xhr.open("PUT", `/api/venues/${id}/movie`);
    xhr.setRequestHeader("Content-Type", "application/octet-stream");
    xhr.upload.onprogress = (event) => {
      if (event.lengthComputable) onProgress(Math.round(100 * event.loaded / event.total));
    };
    xhr.onload = () => {
      let data;
      try { data = JSON.parse(xhr.responseText); } catch { /* Unavailable proxy. */ }
      if (xhr.status >= 200 && xhr.status < 300 && data) finish(null, data);
      else finish(new Error(data?.error || "The upload failed. Check the connection and try again."));
    };
    xhr.onerror = () => finish(new Error("The upload was interrupted. Choose the same movie to try again."));
    xhr.onabort = () => finish(new Error("Upload cancelled. You can retry once the connection has closed."));
    signal.addEventListener("abort", abort, { once: true });
    if (signal.aborted) { finish(new Error("Upload cancelled.")); return; }
    xhr.send(file);
  });
}

export function useVenueLibrary(enabled = true) {
  const [state, setState] = useState({ venues: [], maxUploadBytes: DEFAULT_MAX_BYTES, loading: true, error: "" });
  const [revision, setRevision] = useState(0);
  useEffect(() => {
    if (!enabled) return;
    const controller = new AbortController();
    let timer;
    const poll = async () => {
      try {
        const data = await venueRequest("", { signal: controller.signal });
        if (!controller.signal.aborted) setState({ ...data, loading: false, error: "" });
      } catch (error) {
        if (!controller.signal.aborted) setState((old) => ({ ...old, loading: false, error: error.message }));
      }
      if (!controller.signal.aborted) timer = setTimeout(poll, 3000);
    };
    poll();
    return () => { controller.abort(); clearTimeout(timer); };
  }, [enabled, revision]);
  return { ...state, refresh: () => setRevision((value) => value + 1) };
}

export function processingLabel(record) {
  if (record.status === "processing") return ({
    init: "Starting Movie2Splat", extract: "Extracting movie frames",
    colmap: "Reconstructing the room", train: "Training the splat",
    export: "Exporting the splat", complete: "Finishing processing",
  })[record.stage] || "Processing movie";
  return ({ awaiting_upload: "Awaiting movie", uploading: "Uploading movie",
    queued: "Queued for processing", ready: "Splat ready", failed: "Processing failed" })[record.status] || record.status;
}
