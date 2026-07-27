#!/usr/bin/env bash
# Pulls the latest content for every connected AIShelf registry, then
# reconciles host symlinks (~/.claude/skills, etc.) against it — so a
# session never reads stale registry content just because nobody ran
# `aishelf registry sync` recently. Never blocks or fails the session:
# no-ops silently if the CLI isn't installed or the local service is down.
# `registry sync --all` already materializes internally after syncing
# (same as single-registry sync/connect), so this is one call, not two.
set -u

command -v aishelf >/dev/null 2>&1 || exit 0

result=$(aishelf registry sync --all --json 2>/dev/null) || exit 0

# The materialize step inside `sync --all` only writes links that are
# missing or wrong — already a no-op for anything already materialized.
# This just decides whether to say anything, so a fully-synced host stays
# silent instead of narrating a no-op on every session start.
changed=$(node -e "
try {
  const r = JSON.parse(process.argv[1]);
  const groups = (r.materialized && r.materialized.materialized) || [];
  const any = groups.some(d => (d.created && d.created.length) || (d.pruned && d.pruned.length));
  console.log(any ? '1' : '0');
} catch {
  console.log('0');
}
" "$result" 2>/dev/null || echo "0")

if [ "$changed" = "1" ]; then
  echo "AIShelf: synced registries and materialized updated content into local agent directories."
fi

exit 0
