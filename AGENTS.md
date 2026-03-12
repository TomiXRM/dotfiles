# Repository Guidelines

## Project Structure
- `README.md` is a short entrypoint for humans.
- `docs/architecture.md` is the primary design document and the source of truth for the v2 repository model.
- `docs/ubuntu.md` contains Ubuntu-specific workflow notes.
- `docs/macos.md` is a validation memo for future macOS verification.
- Deployable `chezmoi` source files live at repo root using standard conventions such as `dot_*`, `private_*`, `run_onchange_*`, and `run_once_*`.
- Repository-only materials live under paths such as `docs/`, `packages/`, `assets/`, and `.vscode/` and must not be deployed into `$HOME`.
- Windows-specific files may exist under `assets/windows/`, but Windows is not a supported target yet.

## Supported Platforms
- `Ubuntu`: primary target
- `macOS`: supported target
- `Windows`: unsupported for now

## Entry Commands
- Fresh machine:
  - `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <github-user-or-repo-url>`
- If `chezmoi` is already installed:
  - `chezmoi init --apply <github-user-or-repo-url>`
- User-space runtime installation is explicit:
  - `mise install`

## Script Conventions
- Use `run_onchange_*` for repeatable, manifest-driven operations such as `apt`, `brew`, `cask`, `flatpak`, or Ubuntu input-layer sync.
- Use `run_once_*` only for lightweight one-time actions such as `chsh`.
- Do not run `mise install` from `run_once_*` or `run_onchange_*`.
- Do not run `cargo install` as part of the default apply flow.
- Keep scripts explicit and OS-scoped instead of building a single abstraction layer across platforms.

## Feature Flags
- Optional toolsets are controlled by local machine data in `~/.config/chezmoi/chezmoi.toml`.
- Current feature flags:
  - `features.ros2`: Ubuntu only
  - `features.kicad`: optional
- `features.ros2` uses the official ROS 2 Ubuntu flow rather than the normal package manifests.
- Prefer explicit feature flags over hostname-based behavior or ad hoc branching.

## Repository Boundaries
- Before adding a new top-level file, decide whether it is:
  - deployable by `chezmoi`, or
  - repository-only
- Repository-only files must be excluded via `.chezmoiignore.tmpl`.
- Do not let docs, package manifests, editor caches, or local tool state leak into managed `$HOME` targets.

## Verification
- There is no full automated test suite yet.
- Minimum verification for script/documentation changes:
  - `bash -n` for shell files
  - `chezmoi execute-template < file.tmpl | bash -n` for rendered shell templates
  - `jq empty` for JSON files
  - `python3 -m py_compile` for Python-based config files
- When changing architecture or workflow, keep `README.md` and `docs/architecture.md` aligned.

## Commit & PR Guidelines
- Use short, imperative commit messages.
- Keep changes scoped to one concern when possible.
- For larger changes, document:
  - target OS
  - feature flags involved
  - exact setup or verification steps
  - any manual follow-up actions required after `chezmoi apply`
