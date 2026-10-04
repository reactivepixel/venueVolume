# Services

Long-running backend, networking, device-discovery, and hardware-interface services belong here.

During R&D, a service should be extracted only when it needs an independent process, deployment lifecycle, or fault boundary.

- [Venue intake](venue-ingest/README.md) owns persistent movie uploads, venue
  setup metadata and a serial Movie2Splat worker for the SaaS prototype.
