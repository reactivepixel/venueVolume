// GLB snapshots belong in IndexedDB, never in the small shared localStorage record.
const database = () =>
  new Promise((resolve, reject) => {
    const request = indexedDB.open("vv-venue-scenes", 1);
    request.onupgradeneeded = () =>
      request.result.createObjectStore("snapshots", { keyPath: "id" });
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
export async function sceneStorage(action, value) {
  const db = await database();
  try {
    return await new Promise((resolve, reject) => {
      const tx = db.transaction(
        "snapshots",
        action === "list" ? "readonly" : "readwrite",
      );
      const store = tx.objectStore("snapshots");
      const request =
        action === "list"
          ? store.getAll()
          : action === "put"
            ? store.put(value)
            : store.delete(value);
      tx.oncomplete = () => resolve(request.result);
      tx.onerror = () => reject(tx.error);
      tx.onabort = () =>
        reject(tx.error || new Error("Snapshot storage was interrupted."));
    });
  } finally {
    db.close();
  }
}
