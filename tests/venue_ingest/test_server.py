"""Real HTTP/storage/worker integration; stub only the costly GPU launcher."""
import hashlib
import http.client
import importlib.util
import json
from pathlib import Path
import socket
import tempfile
import threading
import time
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("venue_ingest", ROOT / "services/venue-ingest/server.py")
api = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(api)
MOVIE = b"\x00\x00\x00\x18ftypqt  " + b"\x00" * 100
PROPERTIES = ["x", "y", "z", "f_dc_0", "f_dc_1", "f_dc_2", "opacity",
              "scale_0", "scale_1", "scale_2", "rot_0", "rot_1", "rot_2", "rot_3"] + [f"f_rest_{i}" for i in range(45)]
PLY = ("ply\nformat binary_little_endian 1.0\nelement vertex 1\n" +
       "".join(f"property float {p}\n" for p in PROPERTIES) + "end_header\n").encode() + b"\x00" * (4 * len(PROPERTIES))


def make_launcher(folder):
    launcher = folder / "launcher.py"
    (folder / "fixture.ply").write_bytes(PLY)
    launcher.write_text('''#!/usr/bin/env python3
import json, pathlib, sys, time
source = pathlib.Path(sys.argv[-1])
root = source.parent.parent
mode_file = source.parent / "test-mode"
mode = mode_file.read_text() if mode_file.exists() else "ok"
with (root / "events").open("a") as stream:
    stream.write("start:" + source.parent.name + "\\n")
print("launcher arguments:", sys.argv[1:], flush=True)
work = source.with_suffix(".gsplat")
work.mkdir(exist_ok=True)
(work / "status.json").write_text(json.dumps({"stage": "train", "frames": 150, "registered": 144}))
time.sleep(0.1)
if mode == "ok":
    source.with_suffix(".ply").write_bytes((pathlib.Path(__file__).parent / "fixture.ply").read_bytes())
with (root / "events").open("a") as stream:
    stream.write("end:" + source.parent.name + "\\n")
sys.exit(1 if mode == "fail" else 0)
''')
    launcher.chmod(0o755)
    return launcher


class IntakeTests(unittest.TestCase):
    def setUp(self):
        (ROOT / "tmp").mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=ROOT / "tmp")
        self.folder = Path(self.temp.name)
        self.store = api.Store(self.folder / "data", max_bytes=1024)
        self.worker = api.Worker(self.store, make_launcher(self.folder))
        # Port 0 asks the OS to reserve an unused port atomically.
        self.server = api.Server(("127.0.0.1", 0), self.store, self.worker, self.folder)
        self.port = self.server.server_port
        self.thread = threading.Thread(target=self.server.serve_forever)
        self.thread.start()

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()
        self.worker.close()
        self.store.db.close()
        self.temp.cleanup()

    def request(self, method, path="/api/venues", data=None, headers=None):
        connection = http.client.HTTPConnection("127.0.0.1", self.port, timeout=5)
        body = json.dumps(data).encode() if isinstance(data, dict) else data
        default_headers = {"Content-Type": "application/json" if isinstance(data, dict) else "application/octet-stream"}
        connection.request(method, path, body, {**default_headers, **(headers or {})})
        response = connection.getresponse()
        result = response.read()
        if response.headers.get_content_type() == "application/json":
            result = json.loads(result)
        status = response.status
        connection.close()
        return status, result

    def create(self, **extra):
        data = dict(idempotencyKey=str(uuid.uuid4()), filename="venue.MOV", size=len(MOVIE), **extra)
        status, record = self.request("POST", data=data)
        self.assertEqual(status, 201, record)
        return record, data

    def upload(self, record):
        status, saved = self.request("PUT", f"/api/venues/{record['id']}/movie", MOVIE)
        self.assertEqual(status, 202, saved)
        return saved

    def wait_status(self, record, wanted):
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            latest = self.store.get(record["id"])
            if latest["status"] == wanted:
                return latest
            time.sleep(0.02)
        self.fail(f"Expected {wanted}, got {latest}")

    def test_standalone_upload_process_import_and_persistence(self):
        record, data = self.create()
        self.assertEqual(record["name"], "venue")
        self.assertEqual(record["setupStatus"], "needs_setup")
        setup = dict(name="Glasshouse", city="Brooklyn", show="Afterglow", template="Touring rig")
        self.assertEqual(self.request("POST", f"/api/venues/{record['id']}/setup", setup)[0], 409)
        uploaded = self.upload(record)
        self.assertEqual(uploaded["sha256"], hashlib.sha256(MOVIE).hexdigest())
        self.assertEqual(self.store.source(record).read_bytes(), MOVIE)
        self.worker.start()
        self.wait_status(record, "ready")
        status, ready = self.request("GET", f"/api/venues/{record['id']}")
        self.assertEqual(status, 200)
        self.assertEqual(ready["setupStatus"], "needs_setup")
        self.assertEqual(self.request("GET", ready["assetUrl"]), (200, PLY))
        self.assertIn(b"--resume", self.request("GET", ready["logUrl"])[1])
        status, imported = self.request("POST", f"/api/venues/{record['id']}/setup", setup)
        self.assertEqual(status, 200)
        self.assertEqual(imported["setupStatus"], "configured")
        self.assertEqual(imported["show"], "Afterglow")
        self.assertEqual(imported["assetUrl"], ready["assetUrl"])
        self.assertEqual(self.request("POST", data=data)[1]["id"], record["id"])
        reopened = api.Store(self.store.directory)
        try:
            self.assertEqual(reopened.get(record["id"])["name"], "Glasshouse")
            self.assertEqual(len(reopened.list()), 1)
        finally:
            reopened.db.close()

    def test_saas_upload_keeps_configuration_and_serializes_gpu_jobs(self):
        records = [self.create(name=f"Room {i}", show="Tour", template="Rig")[0] for i in range(3)]
        for record in records:
            self.upload(record)
        self.worker.start()
        for record in records:
            ready = self.wait_status(record, "ready")
            self.assertEqual(ready["setupStatus"], "configured")
            self.assertEqual(ready["template"], "Rig")
        expected = [f"{stage}:{record['id']}" for record in records for stage in ("start", "end")]
        self.assertEqual((self.store.directory / "events").read_text().splitlines(), expected)

    def test_retry_failure_and_reject_missing_output(self):
        failed, _ = self.create()
        invalid, _ = self.create()
        (self.store.folder(failed["id"]) / "test-mode").write_text("fail")
        (self.store.folder(invalid["id"]) / "test-mode").write_text("missing")
        self.upload(failed); self.upload(invalid)
        self.worker.start()
        self.wait_status(failed, "failed")
        self.wait_status(invalid, "failed")
        self.assertIsNone(self.request("GET", f"/api/venues/{invalid['id']}")[1]["assetUrl"])
        (self.store.folder(failed["id"]) / "test-mode").unlink()
        self.assertEqual(self.request("POST", f"/api/venues/{failed['id']}/retry", {})[0], 202)
        ready = self.wait_status(failed, "ready")
        self.assertEqual(ready["attempts"], 2)
        self.assertEqual(self.request("POST", f"/api/venues/{failed['id']}/retry", {})[0], 409)

    def test_restart_recovers_processing_and_preserves_queue(self):
        finished, _ = self.create()
        interrupted, _ = self.create()
        queued, _ = self.create()
        for record in (finished, interrupted, queued):
            self.upload(record)
        self.store.update(finished["id"], {"status": "processing"})
        self.store.source(finished).with_suffix(".ply").write_bytes(PLY)
        self.store.update(interrupted["id"], {"status": "processing"})
        self.worker.start()
        self.wait_status(finished, "ready")
        self.assertIn("interrupted", self.wait_status(interrupted, "failed")["error"])
        self.wait_status(queued, "ready")

    def test_invalid_uploads_and_idempotency(self):
        record, data = self.create()
        self.assertEqual(self.request("POST", data=data)[1]["id"], record["id"])
        self.assertEqual(self.request("POST", data={**data, "name": "Changed"})[0], 409)
        for change, expected in [({"filename": "../bad.mov"}, 400), ({"filename": "x.txt"}, 400),
                                 ({"size": 0}, 400), ({"size": 1025}, 413), ({"size": True}, 400),
                                 ({"show": "Tour"}, 400), ({"idempotencyKey": "../path"}, 400)]:
            self.assertEqual(self.request("POST", data={**data, **change})[0], expected)
        path = f"/api/venues/{record['id']}/movie"
        self.assertEqual(self.request("PUT", path, b"short")[0], 400)
        self.assertEqual(self.request("PUT", path, b"x" * len(MOVIE))[0], 415)
        self.assertEqual(self.store.get(record["id"])["status"], "awaiting_upload")
        self.assertFalse((self.store.folder(record["id"]) / "upload.part").exists())
        self.upload(record)
        self.assertEqual(self.request("PUT", path, MOVIE)[0], 409)
        self.assertEqual(len(self.store.list()), 1)

    def test_disconnected_upload_is_retryable(self):
        record, _ = self.create()
        with socket.create_connection(("127.0.0.1", self.port)) as connection:
            connection.sendall((f"PUT /api/venues/{record['id']}/movie HTTP/1.0\r\nHost: 127.0.0.1:{self.port}\r\n"
                                f"Content-Length: {len(MOVIE)}\r\n\r\n").encode() + MOVIE[:12])
            connection.shutdown(socket.SHUT_WR)
            response = connection.recv(4096)
            self.assertIn(b"400", response)
        self.wait_status(record, "awaiting_upload")
        self.upload(record)

    def test_origin_and_file_boundaries(self):
        self.assertEqual(self.request("GET", headers={"Host": "evil.example"})[0], 403)
        self.assertEqual(self.request("GET", headers={"Origin": "https://evil.example"})[0], 403)
        self.assertEqual(self.request("GET", headers={"Sec-Fetch-Site": "cross-site"})[0], 403)
        self.assertEqual(self.request("GET", "/../secret")[0], 404)
        self.assertEqual(self.request("GET", "/api/venues/" + str(uuid.uuid4()))[0], 404)
        (self.folder / "index.html").write_text("<main>Movie upload</main>")
        self.assertEqual(self.request("GET", "/upload")[1], b"<main>Movie upload</main>")


if __name__ == "__main__":
    unittest.main()
