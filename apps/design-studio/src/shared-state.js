import { useMemo, useSyncExternalStore } from "react";

// Same-origin prototype transport. The production bridge owns authoritative state.
const stores = new Map();
export function sharedStore(key, initial) {
  if (stores.has(key)) return stores.get(key);
  let value = initial;
  const read = () => {
    try {
      return JSON.parse(localStorage.getItem(key)) ?? value;
    } catch {
      return value;
    }
  };
  value = read();
  const listeners = new Set();
  const channel =
    typeof BroadcastChannel !== "undefined" ? new BroadcastChannel(key) : null;
  const notify = () => listeners.forEach((fn) => fn());
  const receive = () => {
    value = read();
    notify();
  };
  channel?.addEventListener("message", receive);
  window.addEventListener("storage", (event) => {
    if (event.key === key) receive();
  });
  const store = {
    snapshot: () => value,
    subscribe: (fn) => {
      listeners.add(fn);
      return () => listeners.delete(fn);
    },
    set: (update) => {
      const commit = () => {
        const latest = read();
        value = typeof update === "function" ? update(latest) : update;
        try {
          localStorage.setItem(key, JSON.stringify(value));
        } catch {
          /* In-memory mode remains usable. */
        }
        notify();
        channel?.postMessage({ changed: true });
        return value;
      };
      return navigator.locks
        ? navigator.locks.request(key, commit)
        : Promise.resolve(commit());
    },
  };
  stores.set(key, store);
  return store;
}
export function useSharedState(key, initial) {
  const store = useMemo(() => sharedStore(key, initial), [key]);
  return [useSyncExternalStore(store.subscribe, store.snapshot), store.set];
}
