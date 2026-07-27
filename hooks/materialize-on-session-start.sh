#!/usr/bin/env bash
# Reconciles host symlinks (~/.claude/skills, etc.) with connected AIShelf
# registries at the start of a session. Never blocks or fails the session:
# no-ops silently if the CLI isn't installed or the local service is down.
set -u

command -v aishelf >/dev/null 2>&1 || exit 0

result=$(aishelf materialize apply --json 2>/dev/null) || exit 0

# `materialize apply` only writes links that are missing or wrong — already
# a no-op for anything already materialized. This just decides whether to
# say anything, so a fully-synced host stays silent instead of narrating a
# no-op on every session start.
changed=$(node -e "
try {
  const r = JSON.parse(process.argv[1]);
  const any = (r.materialized || []).some(d => (d.created && d.created.length) || (d.pruned && d.pruned.length));
  console.log(any ? '1' : '0');
} catch {
  console.log('0');
}
" "$result" 2>/dev/null || echo "0")

if [ "$changed" = "1" ]; then
  echo "AIShelf: materialized updated registry content into local agent directories."
fi

exit 0
