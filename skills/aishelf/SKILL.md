---
name: aishelf
description: Use when working with AIShelf — a team registry system for shared AI resources (currently workflows, rules, skills, and prompts, with more types possible over time), managed via the `aishelf` CLI. Covers browsing/connecting/syncing registries and packages, reading or authoring resources of any type, and materializing registry content natively into this host's agent directories (`~/.claude`, `~/.cursor`, `~/.agents`). Consult this whenever the user mentions AIShelf, connecting a registry, syncing team resources, or materializing shared resources locally.
---

# AIShelf

AIShelf is a registry system for AI resources — workflows, rules, skills, and
prompts today, and potentially other types the team adds later — that a team
shares and keeps in sync via GitHub-backed registries. Everything happens
through the host-installed `aishelf` CLI — there is no other integration path
from this session.

**Never read, write, or otherwise access files under `~/.aishelf/` (or
wherever AIShelf's local storage lives) directly** — not to peek at a
resource's content, not to check what's connected, not even just to look.
Always go through the CLI instead, even when a raw file read looks faster or
a path is visible in some output. The CLI enforces validation, git sync, and
config invariants that direct filesystem access silently bypasses, and its
on-disk layout is an implementation detail that can change without notice.

Nothing below is skill-specific: every command and concept
here applies uniformly to whatever resource types AIShelf currently supports.
If a resource type doesn't match what's listed in this doc, trust the CLI's
own output over this doc — `aishelf materialize config resource-type list`
always prints the live, current list.

**Before doing anything else, check the CLI is available:**
```
command -v aishelf
```

**If absent**: tell the user AIShelf isn't set up on this machine and mention
`npm install -g @aishelf/cli && aishelf service install` gets it running
(Docker-backed by default). **Never run an install command yourself** — not
`npm install -g @aishelf/cli`, not `aishelf service install`, not any other
setup step — unless the user explicitly asks for it. Just check and report;
let the user decide.

**If present**, all commands below are safe to run directly to answer the
user's question or carry out their request — pass `--json` for structured
output when you need to parse the result rather than show it to the user.

## Keeping the CLI updated

- `aishelf update [-y|--yes]` — check for and install the latest `@aishelf/cli`. `-y` skips the confirmation prompt.

Unlike the initial install, **it's fine to run this one yourself without
asking** — it's non-interactive with `-y`, idempotent (a no-op if you're
already current), and only touches the global `@aishelf/cli` npm package,
never the running service or any registry data. Run `aishelf update -y`
immediately, before any other `aishelf` command this session, whenever you
see either of these:
- The session-start sync hook prints an `AIShelf: CLI update required` line.
- Any `aishelf` command's stderr shows `AIShelf CLI update available: ...`.

This matters beyond "missing features": this CLI talks to a versioned HTTP
API on the local `aishelf-service`, so running stale is a real correctness
risk, not just a cosmetic one.

## Auth

These are top-level commands, not nested under an `auth` group.

- `aishelf login` — sign in with GitHub via the browser (interactive; only run if the user asks to log in).
- `aishelf status` — check whether the user is currently authenticated.
- `aishelf logout` — sign out and clear the stored token.

## Registries

- `aishelf registry list` — list connected registries.
- `aishelf registry connect <owner/repo> [--create] [--private] [--public] [--description <text>]` — connect a registry (optionally creating the GitHub repo first). Requires GitHub write access. When creating, the repo is private by default; pass `--public` to create it public instead. `--private` and `--public` are mutually exclusive — passing both is a CLI error.
- `aishelf registry sync <owner/repo>` — pull the latest changes for a connected registry. Pass `--all` instead of `<owner/repo>` to sync every connected registry in parallel.
- `aishelf registry disconnect <owner/repo>` — remove the local clone and tracking entry (does not touch GitHub).
- `aishelf registry trust <owner/repo>` / `aishelf registry untrust <owner/repo>` — trust a registry to auto-accept its security violations, or revoke that trust.

## Packages

- `aishelf package list [--registry <owner/repo>]` — list packages across every connected registry, or scoped to one.
- `aishelf package create <owner/repo> <packageId>` — create a package and push it to GitHub.
- `aishelf package delete <owner/repo> <packageId>` — permanently delete a package, pushed to GitHub.

## Resources (workflows, rules, skills, prompts today — see the note above if that ever changes)

- `aishelf resource list [--registry <owner/repo>] [--package <packageId>] [--type <type>]` — filter independently by registry, package, and/or type, in any combination.
- `aishelf resource get <owner/repo> <packageId> <type> <name> [--path <fs-path>]` — print a resource's content. Some resource types are folder-shaped (currently only `skills`; a future type could be too) rather than a single file — for those, pass `--path` to read a specific supporting file if the entry file references one. Never substitute a workspace file for a resource's actual content.
- `aishelf resource init <owner/repo> <packageId> <type> <name>` — create a new local draft.
- `aishelf resource edit <owner/repo> <packageId> <type> <name> [--content <text>] [--path <fs-path>]` — edit a draft (reads piped stdin if `--content` is omitted).
- `aishelf resource copy <owner/repo> <packageId> <type> <name> [--from <local-path>]` — copy a file/folder into a draft, from a local path or from the existing registry resource.
- `aishelf resource commit <owner/repo> <packageId> <type> <name>` — push a draft to the registry (commits and pushes to GitHub).
- `aishelf resource delete <owner/repo> <packageId> <type> <name>` — revert a local draft, or delete from the registry and push if there's no draft.

## Materialization

Registry resources live in AIShelf's own store until materialized — symlinked
into the host directories each agent actually reads from: `~/.claude` (Claude
Code), `~/.cursor` (Cursor), and `~/.agents` (shared by both Devin and
Antigravity — they're independently toggleable but resolve to the same host
folder).

- `aishelf materialize apply [owner/repo] [packageId] [type] [name] [--claude-code] [--cursor] [--devin] [--antigravity]` — materialize the given scope (everything connected, if no scope given). This always both creates what's missing **and** prunes what's stale in the same pass — there is no separate clean/gc command.
- `aishelf materialize list [--claude-code] [--cursor] [--devin] [--antigravity]` — show currently materialized links across all detected surfaces.

After connecting or syncing a registry, suggest running `aishelf materialize
apply` so its content — whatever resource types it contains — becomes
natively discoverable in this host's tools. Don't run it automatically
without being asked.

**A resource you just synced or materialized might not be immediately
usable as a native skill/command in *this* session** — Claude Code's own
timing for re-scanning `~/.claude/skills`/`~/.claude/commands` after a
mid-session filesystem change isn't something this doc can guarantee. If the
user wants to use a resource you just connected, synced, or materialized and
it isn't showing up as invokable yet, don't tell them it's unavailable —
fall back to `aishelf resource get <owner/repo> <packageId> <type> <name>`
(or `aishelf materialize list` to find its materialized path) and use its
content directly. It always works, regardless of the current session's
discovery state, and treats the CLI as the source of truth rather than
waiting on a re-scan that may only happen next session.

## Materialize Configuration

Automatic materialize (the kind that runs on `registry connect`/`registry sync`)
is governed by a persisted config. **Explicit** actions — `materialize apply`
itself, and every `materialize config` mutation below — always run
regardless of this config's `enabled` flag; only the *automatic* trigger on
connect/sync respects it. Every mutating command below reactively re-applies
materialize immediately after persisting the change, so a toggle takes effect
right away with no separate `apply` needed.

- `aishelf materialize config get [--enabled] [--surfaces] [--disabled-registries] [--per-resource-type]` — print the whole config, or a single field.
- `aishelf materialize config enable` / `aishelf materialize config disable` — turn automatic materialize on registry connect/sync on or off.
- `aishelf materialize config surface enable|disable|list [<surface>] [--all]` — control which surfaces (`claude-code`/`cursor`/`devin`/`antigravity`) automatic materialize targets. `<surface>` and `--all` are mutually exclusive; one is required for `enable`/`disable`.
- `aishelf materialize config registry-source enable|disable|list [<owner/repo>] [--all]` — control which connected registries participate in *unscoped* automatic materialize (a `materialize apply <owner/repo> ...` with an explicit registry always ignores this).
- `aishelf materialize config resource-type enable|disable|list [<type>] [--all]` — control which resource types (`workflows`/`rules`/`skills`/`prompts`) participate in unscoped automatic materialize (same explicit-scope-overrides-config rule as above).
