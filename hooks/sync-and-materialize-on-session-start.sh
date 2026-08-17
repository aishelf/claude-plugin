#!/usr/bin/env bash
# Pulls the latest content for every connected AIShelf registry, then
# reconciles host symlinks (~/.claude/skills, etc.) against it — so a
# session never reads stale registry content just because nobody ran
# `aishelf registry sync` recently. Also nudges the agent to self-update
# an outdated CLI (see block below). Never blocks or fails the session:
# no-ops silently if the CLI isn't installed or the local service is down.
# `registry sync --all` already materializes internally after syncing
# (same as single-registry sync/connect), so this is one call, not two.
set -u

command -v aishelf >/dev/null 2>&1 || exit 0

# CLI self-update nudge. The CLI itself checks for updates on every
# invocation and caches the result at ~/.aishelf/cli-update-check.json
# (refreshed at most every 24h, written by the CLI's own passive check —
# see cli/src/utils/update-check.ts), but its per-invocation notice goes
# to stderr, which the sync call below deliberately discards (2>/dev/null)
# to keep --json output parseable. That means an outdated CLI would
# otherwise go completely unnoticed by the agent driving this session —
# this block re-surfaces it on stdout instead, where the agent reads it
# as session-start context and can act on it directly. No extra network
# call: this only reads the cache the sync call is about to (re)populate.
current_version=$(aishelf --version 2>/dev/null)
cache_file="$HOME/.aishelf/cli-update-check.json"
if [ -n "$current_version" ] && [ -f "$cache_file" ]; then
  latest_version=$(node -e "
try {
  const fs = require('fs');
  const cache = JSON.parse(fs.readFileSync(process.argv[1], 'utf-8'));
  const parse = (v) => String(v).split('.').map((n) => parseInt(n, 10) || 0);
  const [cm, cn, cp] = parse(cache.latestVersion);
  const [am, an, ap] = parse(process.argv[2]);
  const newer = cm > am || (cm === am && cn > an) || (cm === am && cn === an && cp > ap);
  if (newer) console.log(cache.latestVersion);
} catch {}
" "$cache_file" "$current_version" 2>/dev/null)
  if [ -n "$latest_version" ]; then
    echo "AIShelf: CLI update required — you have ${current_version}, ${latest_version} is available. Run \`aishelf update -y\` now, before any other aishelf command this session."
  fi
fi

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
