import { defineConfig } from "vite"
import RubyPlugin from "vite-plugin-ruby"
import react from "@vitejs/plugin-react"

// Builds the driver app (app/frontend). The rider site uses importmap and doesn't go through Vite.
export default defineConfig({
  plugins: [ RubyPlugin(), react() ],
  test: {
    environment: "jsdom",
    include: [ "**/*.test.{js,jsx}" ], // relative to app/frontend (vite-plugin-ruby sets the root)
    setupFiles: [ "test/setup.js" ]
  }
})
