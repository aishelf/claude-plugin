---
name: aishelf
description: Use when working with AIShelf — a team registry system for shared AI workflows, rules, skills, and prompts, managed via the `aishelf` CLI. Covers browsing/connecting/syncing registries and packages, reading or authoring resources, and materializing registry content (e.g. skills) natively into this host's agent directories (`~/.claude/skills`, etc.). Consult this whenever the user mentions AIShelf, connecting a registry, syncing team resources, or materializing shared skills/rules locally.
---

# AIShelf

AIShelf is a registry system for AI workflows, rules, skills, and prompts that a
team shares and keeps in sync via GitHub-backed registries. Everything happens
through the host-installed `aishelf` CLI — there is no other integration path
from this session.

**Before doing anything else, check the CLI is available:**
```
command -v aishelf
```

**If absent**: tell the user AIShelf isn't set up on this machine and mention
`npm install -g @aishelf/cli && aishelf install` gets it running (Docker-backed
by default). **Never run an install command yourself** — not
`npm install -g @aishelf/cli`, not `aishelf install`, not any other setup step
— unless the user explicitly asks for it. Just check and report; let the user
decide.

**If present**, all commands below are safe to run directly to answer the
user's question or carry out their request — pass `--json` for structured
output when you need to parse the result rather than show it to the user.

## Auth

- `aishelf auth login` — sign in with GitHub via the browser (interactive; only run if the user asks to log in).
- `aishelf auth status` — check whether the user is currently authenticated.
- `aishelf auth logout` — sign out and clear the stored token.

## Registries

- `aishelf registry list` — list connected registries.
- `aishelf registry connect <owner/repo> [--create] [--private] [--description <text>]` — connect a registry (optionally creating the GitHub repo first). Requires GitHub write access.
- `aishelf registry sync <owner/repo>` — pull the latest changes for a connected registry. Pass `--all` instead of `<owner/repo>` to sync every connected registry in parallel.
- `aishelf registry disconnect <owner/repo>` — remove the local clone and tracking entry (does not touch GitHub).
- `aishelf registry trust <owner/repo>` / `aishelf registry untrust <owner/repo>` — trust a registry to auto-accept its security violations, or revoke that trust.

## Packages

- `aishelf package list [--registry <owner/repo>]` — list packages across every connected registry, or scoped to one.
- `aishelf package create <owner/repo> <packageId>` — create a package and push it to GitHub.
- `aishelf package delete <owner/repo> <packageId>` — permanently delete a package, pushed to GitHub.

## Resources (workflows, rules, skills, prompts)

- `aishelf resource list [--registry <owner/repo>] [--package <packageId>] [--type <type>]` — filter independently by registry, package, and/or type, in any combination.
- `aishelf resource get <owner/repo> <packageId> <type> <name> [--path <fs-path>]` — print a resource's content. For **skills** (folders, not single files), pass `--path` to read a specific supporting file if the entry file references one — never substitute a workspace file for skill content.
- `aishelf resource init <owner/repo> <packageId> <type> <name>` — create a new local draft.
- `aishelf resource edit <owner/repo> <packageId> <type> <name> [--content <text>] [--path <fs-path>]` — edit a draft (reads piped stdin if `--content` is omitted).
- `aishelf resource copy <owner/repo> <packageId> <type> <name> [--from <local-path>]` — copy a file/folder into a draft, from a local path or from the existing registry resource.
- `aishelf resource commit <owner/repo> <packageId> <type> <name>` — push a draft to the registry (commits and pushes to GitHub).
- `aishelf resource delete <owner/repo> <packageId> <type> <name>` — revert a local draft, or delete from the registry and push if there's no draft.

## Materialization

Registry resources live in AIShelf's own store until materialized — symlinked
into the host directories each agent actually reads from (e.g. `~/.claude/skills`,
`~/.cursor/skills`, `~/.continue/skills`).

- `aishelf materialize apply [owner/repo] [packageId] [type] [name] [--claude-code] [--cursor] [--continue]` — materialize the given scope (everything connected, if no scope given).
- `aishelf materialize list` — show currently materialized links across all detected surfaces.
- `aishelf materialize clean [owner/repo] [packageId] [type] [name] [--claude-code] [--cursor] [--continue]` — remove managed materialized links, scoped or all.

After connecting or syncing a registry that has skills, suggest running
`aishelf materialize apply` so they become natively discoverable — don't run
it automatically without being asked.
