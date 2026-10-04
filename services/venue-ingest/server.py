#!/usr/bin/env python3
"""Single-host venue intake: durable movie uploads and one Movie2Splat worker."""

import argparse
import fcntl
import hashlib
import json
import mimetypes
import os
from pathlib import Path
import re
import shutil
import signal
import sqlite3
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit, unquote
import uuid

ROOT = Path(__file__).resolve().parents[2]
MAX_UPLOAD_BYTES = 10 * 1024**3
EXTENSIONS = {".mov", ".mp4", ".m4v"}
STAGES = {"init", "extract", "colmap", "train", "export", "complete"}


class Problem(Exception):
    def __init__(self, status, message):
        self.status, self.message = status, message


def timestamp():
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def text_field(data, key, required=False, limit=160):
    value = data.get(key, "")
    if not isinstance(value, str) or len(value) > limit or any(ord(c) < 32 for c in value):
        raise Problem(400, f"Invalid {key}.")
    value = value.strip()
    if required and not value:
        raise Problem(400, f"{key.capitalize()} is required.")
    return value


def valid_ply(path):
    """Use the launcher's Gaussian PLY contract, including after crash recovery."""
    try:
        with path.open("rb") as stream:
            header = stream.read(65536)
        end = header.find(b"end_header\n")
        if end < 0:
            return False
        header = header[:end + 11]
        count = re.search(rb"\nelement vertex (\d+)\n", header)
        properties = set(re.findall(rb"\nproperty float (\S+)", header))
        required = {b"x", b"y", b"z", b"f_dc_0", b"f_dc_1", b"f_dc_2", b"opacity",
                    b"scale_0", b"scale_1", b"scale_2", b"rot_0", b"rot_1", b"rot_2", b"rot_3"}
        required.update(f"f_rest_{i}".encode() for i in range(45))
        return (header.startswith(b"ply\nformat binary_little_endian 1.0\n") and count is not None
                and int(count[1]) > 0 and required <= properties
                and path.stat().st_size >= end + 11 + int(count[1]) * len(properties) * 4)
    except OSError:
        return False


class Store:
    def __init__(self, directory, max_bytes=MAX_UPLOAD_BYTES):
        self.directory = Path(directory).resolve()
        self.directory.mkdir(parents=True, exist_ok=True)
        self.max_bytes = max_bytes
        self.lock = threading.RLock()
        self.db = sqlite3.connect(self.directory / "venues.sqlite3", check_same_thread=False)
        self.db.execute("PRAGMA journal_mode=WAL")
        self.db.execute("CREATE TABLE IF NOT EXISTS venues (id TEXT PRIMARY KEY, record TEXT NOT NULL)")
        self.db.commit()

    def list(self):
        with self.lock:
            return [json.loads(row[0]) for row in self.db.execute("SELECT record FROM venues ORDER BY rowid DESC")]

    def get(self, identifier):
        with self.lock:
            row = self.db.execute("SELECT record FROM venues WHERE id = ?", (identifier,)).fetchone()
            if row is None:
                raise Problem(404, "Venue not found.")
            return json.loads(row[0])

    def update(self, identifier, changes, allowed=None):
        with self.lock:
            record = self.get(identifier)
            if allowed is not None and record["status"] not in allowed:
                raise Problem(409, "The venue has changed. Refresh its status before trying again.")
            record.update(changes, updatedAt=timestamp())
            with self.db:
                self.db.execute("UPDATE venues SET record = ? WHERE id = ?", (json.dumps(record), identifier))
            return record

    def create(self, data):
        identifier = text_field(data, "idempotencyKey", required=True)
        try:
            if str(uuid.UUID(identifier)) != identifier:
                raise ValueError()
        except ValueError:
            raise Problem(400, "A UUID idempotencyKey is required.")
        filename = text_field(data, "filename", required=True, limit=255)
        if "/" in filename or "\\" in filename or Path(filename).suffix.lower() not in EXTENSIONS:
            raise Problem(400, "Choose a MOV, MP4, or M4V movie.")
        size = data.get("size")
        if type(size) is not int or size < 1:
            raise Problem(400, "Choose a nonempty movie.")
        if size > self.max_bytes:
            raise Problem(413, "The movie exceeds the upload size limit.")
        show, template = text_field(data, "show"), text_field(data, "template")
        if bool(show) != bool(template):
            raise Problem(400, "Choose both a show and a starting configuration, or set up later.")
        details = dict(filename=filename, size=size,
                       name=text_field(data, "name") or Path(filename).stem[:160],
                       city=text_field(data, "city"), show=show, template=template)
        with self.lock:
            existing = self.db.execute("SELECT record FROM venues WHERE id = ?", (identifier,)).fetchone()
            if existing:
                record = json.loads(existing[0])
                if record["intake"] != details:
                    raise Problem(409, "This upload ID already belongs to a different movie or venue.")
                return record
            record = dict(id=identifier, **details, intake=details,
                          setupStatus="configured" if show else "needs_setup",
                          status="awaiting_upload", stage=None, error=None, sha256=None,
                          createdAt=timestamp(), updatedAt=timestamp(), attempts=0)
            self.folder(identifier).mkdir()
            with self.db:
                self.db.execute("INSERT INTO venues VALUES (?, ?)", (identifier, json.dumps(record)))
            return record

    def folder(self, identifier):
        # IDs in storage are generated UUIDs, never supplied paths.
        return self.directory / identifier

    def source(self, record):
        return self.folder(record["id"]) / ("source" + Path(record["filename"]).suffix.lower())

    def public(self, record):
        result = {key: value for key, value in record.items() if key != "intake"}
        if record["status"] == "processing":
            try:
                progress = json.loads((self.folder(record["id"]) / "source.gsplat/status.json").read_text())
                if progress.get("stage") in STAGES:
                    result["stage"] = progress["stage"]
                for field in ("frames", "registered"):
                    if type(progress.get(field)) is int:
                        result[field] = progress[field]
            except (OSError, ValueError):
                pass
        result["assetUrl"] = f"/api/venues/{record['id']}/splat" if record["status"] == "ready" else None
        result["logUrl"] = f"/api/venues/{record['id']}/log" if record["attempts"] else None
        return result


class Worker:
    def __init__(self, store, launcher=None):
        self.store = store
        self.launcher = Path(launcher or ROOT / "apps/mov2splat/scripts/host.sh").resolve()
        self.stopping = threading.Event()
        self.wake = threading.Event()
        self.thread = threading.Thread(target=self.run, name="movie2splat-worker", daemon=True)

    def start(self):
        self.thread.start()

    def close(self):
        # Graceful shutdown waits for the active GPU job, preserving its result.
        self.stopping.set()
        self.wake.set()
        if self.thread.is_alive():
            self.thread.join()

    def run(self):
        # The child inherits this lock. A restarted service waits for an orphaned
        # launcher before recovering records or starting another GPU job.
        with (self.store.directory / ".processor.lock").open("a") as gpu_lock:
            while not self.stopping.is_set():
                try:
                    fcntl.flock(gpu_lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    break
                except BlockingIOError:
                    self.stopping.wait(1)
            if self.stopping.is_set():
                return
            for record in self.store.list():
                if record["status"] == "processing":
                    ready = valid_ply(self.store.source(record).with_suffix(".ply"))
                    self.store.update(record["id"], dict(status="ready" if ready else "failed",
                        stage="complete" if ready else record["stage"],
                        error=None if ready else "Processing was interrupted. Retry to resume the saved movie."))
            while not self.stopping.is_set():
                queued = [record for record in reversed(self.store.list()) if record["status"] == "queued"]
                if queued:
                    try:
                        self.process(queued[0], gpu_lock.fileno())
                    except Exception as error:
                        # A failed job must not take the queue down with it.
                        self.store.update(queued[0]["id"], dict(status="failed", error=f"Processing failed: {error}"))
                else:
                    self.wake.wait(1)
                    self.wake.clear()

    def process(self, record, lock_fd):
        identifier = record["id"]
        folder = self.store.folder(identifier)
        source = self.store.source(record)
        self.store.update(identifier, dict(status="processing", stage="init", error=None,
            attempts=record["attempts"] + 1), allowed={"queued"})
        # Do not show progress from an earlier failed attempt while Docker starts.
        (folder / "source.gsplat/status.json").unlink(missing_ok=True)
        with (folder / "processor.log").open("ab", buffering=0) as log:
            log.write(f"\n--- Attempt {record['attempts'] + 1} at {timestamp()} ---\n".encode())
            result = subprocess.run([str(self.launcher), "--resume", str(source)],
                cwd=ROOT, stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT,
                pass_fds=(lock_fd,))
        if result.returncode == 0 and valid_ply(source.with_suffix(".ply")):
            self.store.update(identifier, dict(status="ready", stage="complete", error=None))
        else:
            self.store.update(identifier, dict(status="failed", error=
                f"Movie2Splat did not produce a valid splat (exit {result.returncode}). Review the processing log, then retry."))


class Server(ThreadingHTTPServer):
    daemon_threads = False

    def __init__(self, address, store, worker, static_dir=None):
        self.store, self.worker = store, worker
        self.static_dir = Path(static_dir or ROOT / "apps/design-studio/dist").resolve()
        super().__init__(address, Handler)


class Handler(BaseHTTPRequestHandler):
    server_version = "VenueIntake/1.0"

    def log_message(self, *args):
        pass

    def reply(self, status, data):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(body)

    def length(self, maximum):
        if self.headers.get("Transfer-Encoding"):
            raise Problem(400, "Chunked transfer is not supported. Send Content-Length.")
        values = self.headers.get_all("Content-Length", [])
        if len(values) != 1 or not values[0].isdigit():
            raise Problem(411, "Content-Length is required.")
        size = int(values[0])
        if size > maximum:
            raise Problem(413, "Request exceeds the size limit.")
        return size

    def json_body(self):
        if self.headers.get_content_type() != "application/json":
            raise Problem(415, "Send application/json.")
        try:
            data = json.loads(self.rfile.read(self.length(16384)))
        except (ValueError, UnicodeError):
            raise Problem(400, "Invalid JSON.")
        if not isinstance(data, dict):
            raise Problem(400, "Expected a JSON object.")
        return data

    def do_GET(self):
        self.dispatch()

    def do_POST(self):
        self.dispatch()

    def do_PUT(self):
        self.dispatch()

    def dispatch(self):
        self.connection.settimeout(120)
        try:
            # The service is local-only. Require same-origin requests through
            # either its static server or Vite's same-origin proxy; no CORS.
            host = self.headers.get("Host", "")
            if urlsplit("//" + host).hostname not in {"localhost", "127.0.0.1", "::1"}:
                raise Problem(403, "The intake service only accepts local hostnames.")
            origin = self.headers.get("Origin")
            if origin and urlsplit(origin).netloc != host:
                raise Problem(403, "Cross-origin access is not allowed.")
            if self.headers.get("Sec-Fetch-Site") == "cross-site":
                raise Problem(403, "Cross-site access is not allowed.")
            path = urlsplit(self.path).path
            store = self.server.store
            if path == "/api/venues":
                if self.command == "GET":
                    return self.reply(200, dict(venues=[store.public(r) for r in store.list()], maxUploadBytes=store.max_bytes))
                if self.command == "POST":
                    return self.reply(201, store.public(store.create(self.json_body())))
            match = re.fullmatch(r"/api/venues/([0-9a-f-]{36})(?:/(movie|retry|setup|splat|log))?", path)
            if match:
                identifier, action = match.groups()
                record = store.get(identifier)
                if self.command == "GET" and not action:
                    return self.reply(200, store.public(record))
                if self.command == "PUT" and action == "movie":
                    return self.upload(record)
                if self.command == "POST" and action == "retry":
                    self.json_body()
                    record = store.update(identifier, dict(status="queued", error=None, stage=None), allowed={"failed"})
                    self.server.worker.wake.set()
                    return self.reply(202, store.public(record))
                if self.command == "POST" and action == "setup":
                    data = self.json_body()
                    changes = {key: text_field(data, key, required=key == "name") for key in ("name", "city", "show", "template")}
                    record = store.update(identifier, dict(**changes, setupStatus="configured"), allowed={"ready"})
                    return self.reply(200, store.public(record))
                if self.command == "GET" and action in {"splat", "log"}:
                    if action == "splat" and record["status"] != "ready":
                        raise Problem(409, "The splat is not ready yet.")
                    file = store.source(record).with_suffix(".ply") if action == "splat" else store.folder(identifier) / "processor.log"
                    return self.send_file(file, download=f"venue-{identifier}.{'ply' if action == 'splat' else 'log'}")
            if path.startswith("/api/") or self.command != "GET":
                raise Problem(404, "Endpoint not found.")
            relative = unquote(path).lstrip("/")
            file = (self.server.static_dir / relative).resolve()
            if not file.is_relative_to(self.server.static_dir):
                raise Problem(404, "Page not found.")
            if path in {"/", "/upload", "/upload/"}:
                file = self.server.static_dir / "index.html"
            return self.send_file(file)
        except Problem as error:
            self.reply(error.status, {"error": error.message})
        except (BrokenPipeError, ConnectionResetError, TimeoutError):
            pass
        except Exception:
            self.reply(500, {"error": "The intake service could not complete this request. Check its storage and try again."})

    def upload(self, record):
        store = self.server.store
        length = self.length(store.max_bytes)
        if length != record["size"]:
            raise Problem(400, "The movie size does not match the upload record.")
        identifier = record["id"]
        partial = store.folder(identifier) / "upload.part"
        # Reserve before reading so two clients cannot write the same file.
        store.update(identifier, dict(status="uploading", error=None), allowed={"awaiting_upload"})
        queued = False
        try:
            free = shutil.disk_usage(store.directory).free
            if free < length + 64 * 1024**2:
                raise Problem(507, "There is not enough storage for this movie.")
            digest = hashlib.sha256()
            prefix = b""
            with partial.open("wb") as output:
                remaining = length
                while remaining:
                    chunk = self.rfile.read(min(1024**2, remaining))
                    if not chunk:
                        raise Problem(400, "Upload interrupted. Choose the same movie to try again.")
                    if len(prefix) < 64:
                        prefix += chunk[:64 - len(prefix)]
                    output.write(chunk)
                    digest.update(chunk)
                    remaining -= len(chunk)
                output.flush()
                os.fsync(output.fileno())
            # ISO BMFF / QuickTime atom signature; decoding and reconstruction
            # validation remain inside the isolated Movie2Splat container.
            if len(prefix) < 12 or prefix[4:8] not in {b"ftyp", b"moov", b"mdat", b"wide", b"free", b"skip"}:
                raise Problem(415, "This file is not a recognizable MOV, MP4, or M4V movie.")
            partial.replace(store.source(record))
            record = store.update(identifier, dict(status="queued", sha256=digest.hexdigest(), error=None))
            queued = True
        finally:
            partial.unlink(missing_ok=True)
            if not queued:
                store.update(identifier, dict(status="awaiting_upload", error="Upload did not finish. Choose the same movie to try again."))
        self.server.worker.wake.set()
        self.reply(202, store.public(record))

    def send_file(self, file, download=None):
        if not file.is_file():
            raise Problem(404, "File not found. Build the design studio first if opening the app.")
        with file.open("rb") as stream:
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream" if download else (mimetypes.guess_type(file)[0] or "application/octet-stream"))
            self.send_header("Content-Length", str(os.fstat(stream.fileno()).st_size))
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Cache-Control", "no-store")
            if download:
                self.send_header("Content-Disposition", f'attachment; filename="{download}"')
            self.end_headers()
            shutil.copyfileobj(stream, self.wfile)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8788)
    parser.add_argument("--data-dir", type=Path, default=ROOT / ".venue-ingest")
    parser.add_argument("--max-upload-bytes", type=int, default=MAX_UPLOAD_BYTES)
    args = parser.parse_args()
    if args.max_upload_bytes < 1:
        parser.error("--max-upload-bytes must be positive")
    args.data_dir.mkdir(parents=True, exist_ok=True)
    with (args.data_dir / ".service.lock").open("a") as service_lock:
        try:
            fcntl.flock(service_lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            parser.error("Another intake service is using this data directory")
        store = Store(args.data_dir, args.max_upload_bytes)
        # A terminated HTTP upload can be repeated against its existing record.
        for record in store.list():
            if record["status"] == "uploading":
                (store.folder(record["id"]) / "upload.part").unlink(missing_ok=True)
                store.update(record["id"], dict(status="awaiting_upload", error="Upload interrupted. Choose the same movie to try again."))
        worker = Worker(store)
        server = Server(("127.0.0.1", args.port), store, worker)
        def stop(*_):
            threading.Thread(target=server.shutdown, daemon=True).start()
        signal.signal(signal.SIGINT, stop)
        signal.signal(signal.SIGTERM, stop)
        worker.start()
        print(f"Venue intake listening at http://127.0.0.1:{args.port} (uploads: {store.directory})", flush=True)
        try:
            server.serve_forever()
        finally:
            server.server_close()
            print("Finishing any active Movie2Splat job before shutdown…", flush=True)
            worker.close()
            store.db.close()


if __name__ == "__main__":
    main()
