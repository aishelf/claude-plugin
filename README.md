# AIShelf plugin for Claude Code

Connects Claude Code to [AIShelf](https://aishelf.dev) — a team registry
system for sharing workflows, rules, skills, and prompts via GitHub-backed
registries.

## Prerequisites

The plugin talks to AIShelf entirely through the host-installed `aishelf` CLI.
It doesn't work without it:

```bash
npm install -g @aishelf/cli
aishelf service install
```

## Install

```
/plugin marketplace add aishelf/claude-plugin
/plugin install aishelf@aishelf-tools
```

## What it does

- **Skill** (`skills/aishelf/SKILL.md`): teaches Claude the full `aishelf`
  CLI surface — connecting/syncing registries and packages, reading and
  authoring resources (workflows, rules, skills, prompts), and materializing
  registry content into this host's agent directories (`~/.claude`,
  `~/.cursor`, `~/.agents`). Consulted automatically whenever a session
  touches AIShelf.
- **SessionStart hook** (`hooks/sync-and-materialize-on-session-start.sh`):
  on session start/resume, syncs every connected registry and reconciles
  materialized symlinks, so a session never reads stale registry content just
  because nobody ran `aishelf registry sync` recently. No-ops silently if the
  CLI isn't installed or the local service isn't running.

## License

Proprietary — see [LICENSE](./LICENSE).

## Links

- Homepage: https://aishelf.dev
- Source: https://github.com/aishelf/claude-plugin
