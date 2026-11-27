import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      "/api/accounts": { target: "http://localhost:3001", rewrite: (p) => p.replace(/^\/api\/accounts/, "") },
      "/api/transfers": { target: "http://localhost:3002", rewrite: (p) => p.replace(/^\/api\/transfers/, "") },
      "/api/chat": { target: "http://localhost:3003", rewrite: (p) => p.replace(/^\/api\/chat/, "") },
    },
  },
});
