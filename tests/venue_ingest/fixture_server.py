"""Browser-test server: real API and storage, deterministic fake GPU only."""
import json
from pathlib import Path
import signal
import tempfile
import threading

from test_server import ROOT, api, make_launcher


def main():
    (ROOT / "tmp").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="venue-browser-", dir=ROOT / "tmp") as temporary:
        folder = Path(temporary)
        store = api.Store(folder / "data", max_bytes=1024**2)
        worker = api.Worker(store, make_launcher(folder))
        server = api.Server(("127.0.0.1", 0), store, worker)
        def stop(*_):
            threading.Thread(target=server.shutdown, daemon=True).start()
        signal.signal(signal.SIGTERM, stop)
        signal.signal(signal.SIGINT, stop)
        worker.start()
        print(json.dumps({"url": f"http://127.0.0.1:{server.server_port}", "dataDir": str(store.directory)}), flush=True)
        try:
            server.serve_forever()
        finally:
            server.server_close()
            worker.close()
            store.db.close()


if __name__ == "__main__":
    main()
