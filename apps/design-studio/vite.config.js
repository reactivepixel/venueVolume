import { defineConfig } from "vite";

export default defineConfig({
  server: {
    proxy: {
      "/api/venues": {
        target: process.env.VV_INTAKE_URL || "http://127.0.0.1:8788",
        // Preserve Host so the intake service can verify same-origin requests.
        changeOrigin: false,
        timeout: 0,
        proxyTimeout: 0,
      },
    },
  },
});
