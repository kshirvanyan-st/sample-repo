# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
# Loaded on demand by the playback controller when WebRTC isn't available.
pin "hls.js", to: "https://cdn.jsdelivr.net/npm/hls.js@1.6.13/dist/hls.mjs", preload: false
pin_all_from "app/javascript/lib", under: "lib"
