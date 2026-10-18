# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "map_helpers"
# MapLibre is three ES modules that import each other by relative path, so they are served
# unchanged from public/ instead of through the asset pipeline (which renames files).
pin "maplibre-gl", to: "/vendor/maplibre-gl-6.12.0/maplibre-gl.mjs" # @6.12.0
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "cable"
