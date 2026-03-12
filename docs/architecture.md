# chezmoi v2 Architecture

## Status

This document describes the v2 architecture that now drives the repository.

Status as of March 13, 2026:

- Ubuntu has been restructured around this model and validated with `chezmoi apply`
- macOS follows the same high-level design, but still needs real-machine verification
- Treat this file as the source of truth when future work changes the repository layout or execution model

## Goals

- Keep `chezmoi` readable, predictable, and maintainable over multiple years
- Support `Ubuntu` and `macOS` cleanly without pretending they are the same platform
- Keep repository-only files out of `$HOME`
- Make optional toolsets explicit and machine-local
- Make maintenance repeatable for humans and LLM agents

## Supported Platforms

- `Ubuntu`: primary target
- `macOS`: supported target
- `Windows`: not supported yet

Windows-specific files may be stored in the repository as assets, but they must not be deployed into `$HOME` by `chezmoi`.

## Non-Goals

- Full Windows provisioning
- A custom bootstrap script as the primary entrypoint
- Automatic installation of every developer runtime during `chezmoi apply`
- Automatic removal of previously-installed optional packages when a feature is disabled
- Hidden host-specific behavior based on machine names

## Entry Model

The default entrypoint is the official `chezmoi` flow.

Fresh machine:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <github-user-or-repo-url>
```

Machine with `chezmoi` already installed:

```bash
chezmoi init --apply <github-user-or-repo-url>
```

No repository-specific bootstrap script is required for normal setup.

## Separation of Responsibilities

### `chezmoi`

`chezmoi` is responsible for:

- Deploying dotfiles into `$HOME`
- Rendering templates from local machine data
- Running lightweight orchestration scripts
- Triggering repeatable OS package sync from declarative package lists

`chezmoi` is not responsible for:

- Acting as a full replacement for configuration management systems
- Hiding platform-specific behavior behind a fake abstraction layer
- Installing every user-space developer tool automatically

### OS Package Managers

OS-level packages are installed by platform-specific `run_onchange_*` scripts.

- Ubuntu: `apt`, `flatpak`, third-party package sources if explicitly modeled
- macOS: `brew`, `cask`

These scripts are allowed to run during `chezmoi apply` because they are tied to declarative package manifests and should re-run when those manifests change.

### `mise`

`mise` is the user-space runtime manager.

- `mise` configuration is deployed by `chezmoi`
- `mise install` is run manually by the user
- `mise install` is not executed from `run_once_*`
- `mise install` is not executed from `run_onchange_*`
- shell-time auto-install should stay disabled

Reasoning:

- `mise` tool installation is network-heavy and failure-prone
- `run_once_*` does not react well to future tool list changes
- shell activation and PATH issues are easier to debug when `mise install` is explicit

### `cargo`

`cargo install` is not part of the default `chezmoi apply` flow.

- use it only for tools that do not fit OS package managers or `mise`
- run it manually or behind an explicit opt-in script

## Script Policy

### `run_onchange_*`

Use `run_onchange_*` for repeatable, manifest-driven operations.

Examples:

- Ubuntu core `apt` packages
- Ubuntu optional `flatpak` packages
- macOS `brew` packages
- macOS `cask` apps

Rule:

- if the rendered script changes, it may re-run
- the script body should be generated from package manifest files and local feature flags
- package sync scripts should install only missing packages and skip network refresh when their manifests are already satisfied

### `run_once_*`

Use `run_once_*` only for small one-time operations.

Examples:

- changing the login shell with `chsh`
- one-time local initialization that is not package-manifest driven

Do not use `run_once_*` for:

- package synchronization
- `mise install`
- `cargo install`
- large downloads from moving targets

### `run_*`

Use plain `run_*` scripts for cheap, idempotent follow-up actions that depend on current session state rather than package manifests.

Examples:

- enabling a GNOME Shell extension after the files already exist
- retrying lightweight desktop integration steps that may be skipped when no GUI session is active

Note:

- plain `run_*` scripts normally appear as `R` in `chezmoi status`; this means they will run on the next `chezmoi apply`, not that the repository is dirty

## Feature Flags

Optional toolsets are controlled by local machine data instead of repository branches or host-name heuristics.

Local file:

`~/.config/chezmoi/chezmoi.toml`

```toml
[data.features]
ros2 = false
kicad = false
```

For a robotics Ubuntu machine:

```toml
[data.features]
ros2 = true
kicad = true
```

### Feature Semantics

- `ros2`: Ubuntu only
- `kicad`: optional

If a feature is disabled later, the repository does not automatically uninstall what was previously installed. Disabling a feature only stops future installation from the manifests.

For `ros2`, the feature flag exists at the repository level, but installation follows the official ROS 2 Ubuntu instructions instead of the normal package manifests.

## Repository Boundaries

The repository must clearly separate deployable `chezmoi` source files from repository-only materials.

### Deployable by `chezmoi`

- `dot_*`
- `private_*`
- `run_onchange_*`
- `run_once_*`
- `.chezmoiexternal.toml`
- other files that are intentionally mapped to `$HOME`

### Repository-Only

- `docs/`
- `packages/`
- `assets/`
- `.vscode/`
- `AGENTS.md`
- temporary local tooling state such as `.serena/`

Repository-only paths must be excluded from deployment via `.chezmoiignore.tmpl`.

## Target Repository Structure

```text
.
├── .chezmoiexternal.toml
├── .chezmoiignore.tmpl
├── dot_zprofile
├── dot_zshrc.tmpl
├── dot_mise.toml
├── private_dot_config/
├── private_dot_local/
├── run_onchange_10_ubuntu_apt.sh.tmpl
├── run_onchange_20_ubuntu_gui.sh.tmpl
├── run_onchange_30_ubuntu_input.sh.tmpl
├── run_40_ubuntu_gnome_input.sh.tmpl
├── run_onchange_10_macos_brew.sh.tmpl
├── run_onchange_20_macos_cask.sh.tmpl
├── run_once_10_shell.sh.tmpl
├── packages/
│   ├── ubuntu/
│   │   ├── apt/
│   │   │   ├── core.txt
│   │   │   ├── gui.txt
│   │   │   └── input.txt
│   │   ├── apt_thirdparty/
│   │   │   └── core.txt
│   │   └── flatpak/
│   │       ├── core.txt
│   │       └── kicad.txt
│   ├── macos/
│   │   ├── brew/
│   │   │   └── core.txt
│   │   └── cask/
│   │       ├── core.txt
│   │       └── kicad.txt
│   └── common/
│       └── cargo.txt
├── assets/
│   └── windows/
│       └── solidworks/
│           └── swSettings.sldreg
└── docs/
    └── architecture.md
```

## Package Layout Rules

- `core.txt` contains packages installed on every machine for that OS/package manager
- feature files contain only optional packages
- package files are plain text, one item per line, comments allowed

## Planned Package Behavior

### Ubuntu

- `apt/core.txt`: CLI/system/core packages
- `apt/gui.txt`: Ubuntu GUI support packages such as `flatpak`
- `apt/input.txt`: Ubuntu input stack packages such as `fcitx5`
- `apt_thirdparty/core.txt`: third-party packages such as `tailscale` or `code`
- `flatpak/core.txt`: optional core GUI applications chosen for Ubuntu
- `flatpak/kicad.txt`: KiCad, enabled only when `features.kicad = true`
- `run_onchange_30_ubuntu_input.sh.tmpl`: installs Toshy and Ubuntu input packages
- `run_onchange_30_ubuntu_input.sh.tmpl`: tracks a desired Toshy ref and records the applied ref in local state
- `run_40_ubuntu_gnome_input.sh.tmpl`: retries xremap GNOME extension enablement when a GNOME session is active
- ROS 2 installation is manual and follows the official ROS 2 Jazzy Ubuntu instructions

### macOS

- `brew/core.txt`: CLI/system packages
- `cask/core.txt`: GUI applications
- `cask/kicad.txt`: KiCad, enabled only when `features.kicad = true`

## Windows Assets

Windows assets belong under `assets/windows/`.

Example:

- `assets/windows/solidworks/swSettings.sldreg`

These files are versioned in Git but are not deployed by `chezmoi` until Windows support is intentionally designed.

## Maintenance Rules for Humans and LLM Agents

- This document is the primary architecture reference
- `README.md` stays short and points here
- do not add repository-only files unless their deployment behavior is explicit
- before adding any new root-level file, decide whether it is deployable or repo-only
- if a file is repo-only, make sure `.chezmoiignore.tmpl` excludes it
- prefer explicit feature flags over implicit host detection
- keep script responsibilities narrow and obvious from filenames

## Migration Order

1. Add `.chezmoiignore.tmpl` and exclude repository-only paths
2. Move Windows-only assets into `assets/windows/`
3. Rebuild `packages/` into the target OS/feature layout
4. Replace current `run_once_*` package installers with `run_onchange_*`
5. Remove automatic `mise install` and `cargo install` from the apply flow
6. Rewrite scripts to match the new package manifests and feature flags
7. Validate that `README.md` and this document still describe the repository accurately
