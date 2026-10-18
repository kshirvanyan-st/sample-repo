#!/bin/bash
# Prepares a Claude Code cloud session: gems, Postgres with PostGIS, databases, Tailwind build.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

bundle install --quiet
npm ci --no-audit --no-fund --silent
command -v rbenv >/dev/null && rbenv rehash

if command -v pg_ctlcluster >/dev/null; then
  version=$(pg_lsclusters --no-header | awk 'NR==1 {print $1}')
  cluster=$(pg_lsclusters --no-header | awk 'NR==1 {print $2}')

  # The app needs PostGIS; cloud images ship plain Postgres.
  if ! psql -d postgres -tAc "SELECT 1 FROM pg_available_extensions WHERE name='postgis'" 2>/dev/null | grep -q 1; then
    (apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "postgresql-${version}-postgis-3") >/dev/null 2>&1 || true
  fi

  pg_ctlcluster "$version" "$cluster" start 2>/dev/null || true
  su postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$(whoami)'\"" | grep -q 1 ||
    su postgres -c "createuser --superuser $(whoami)"
fi

bin/rails db:prepare
RAILS_ENV=test bin/rails db:prepare
bin/rails tailwindcss:build
