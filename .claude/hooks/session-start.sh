#!/bin/bash
# Prepares a Claude Code cloud session: gems, Postgres, databases, Tailwind build.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

# `bundle install` (not --deployment) so the installed gems are cached with the container.
bundle install --quiet
command -v rbenv >/dev/null && rbenv rehash

# Start the local Postgres cluster and give the current user a superuser role.
if command -v pg_ctlcluster >/dev/null; then
  version=$(pg_lsclusters --no-header | awk 'NR==1 {print $1}')
  cluster=$(pg_lsclusters --no-header | awk 'NR==1 {print $2}')
  pg_ctlcluster "$version" "$cluster" start 2>/dev/null || true
  su postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$(whoami)'\"" | grep -q 1 ||
    su postgres -c "createuser --superuser $(whoami)"
fi

bin/rails db:prepare
RAILS_ENV=test bin/rails db:prepare
bin/rails tailwindcss:build
