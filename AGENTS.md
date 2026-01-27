# Repository Guidelines

## Project Structure & Module Organization
- `README.MD` describes the direction and links to detailed docs.
- `docs/` holds project rules and targets:
  - `docs/rule.md` defines the setup philosophy and execution order.
  - `docs/want_to_organize.md` lists desired tools and OS-specific needs.
- `今まで使ってたdotfilesリポジトリ/` is a legacy dotfiles repo with prior scripts and input configs (e.g., `install.sh`, `keyboards/`).

## Build, Test, and Development Commands
- No build or test commands are defined at the repo root yet.
- Expected bootstrap flow (from `docs/rule.md`):
  - `chezmoi init --apply` (after installing `chezmoi`).
- When adding scripts or tooling, document the exact commands in `README.MD` and keep them OS-scoped (e.g., `apt` vs `brew`).

## Coding Style & Naming Conventions
- Prefer clear, explicit scripts over abstraction; keep OS-specific logic separated.
- Follow the documented ordering for chezmoi scripts: `run_once_XX_*.sh.tmpl` where `XX` is the execution order.
- Keep scripts idempotent and safe to re-run.
- If you add new configuration files, place them following chezmoi conventions at repo root and note their purpose in `docs/`.

## Testing Guidelines
- There is no automated test suite yet.
- Manual verification should follow the sequence in `docs/rule.md` and confirm:
  - `chezmoi apply` is repeatable.
  - OS packages install cleanly.
  - Shell restart happens before `mise install`.
- If you introduce tests (e.g., shell checks), add a short “How to run” note here.

## Commit & Pull Request Guidelines
- The root repo has no Git history yet. The legacy repo history uses short, imperative messages like “add …”, “fix …”, “update …”.
- Use concise, imperative commit messages and keep changes scoped.
- PRs should include:
  - Target OS (Mac/Ubuntu) and any arch constraints.
  - Exact install/verify steps.
  - Notes on any manual UI steps (screenshots if GUI settings change).

## Configuration Principles (Read Before Editing)
- Follow the order: bootstrap → chezmoi → OS packages → shell restart → mise → cargo.
- Keep GUI installs in OS package managers; avoid `snap`.
- Isolate exceptions and platform-specific logic; avoid single “all-in-one” install scripts.
