# chezmoi dotfiles

This repository is being redesigned around a simpler `chezmoi` v2 model.

- Supported platforms: `Ubuntu`, `macOS`
- Windows: not supported yet, but Windows-specific assets may live in the repo
- Current focus: make the repository predictable for both humans and LLM agents

The target architecture is documented in [docs/architecture.md](docs/architecture.md).

Platform notes:

- [docs/ubuntu.md](docs/ubuntu.md)
- [docs/macos.md](docs/macos.md)

Planned entrypoints:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <github-user-or-repo-url>
```

If `chezmoi` is already installed:

```bash
chezmoi init --apply <github-user-or-repo-url>
```

After `chezmoi` has applied files and OS packages, install user-space tools explicitly:

```bash
mise install
```

Tool installation remains explicit. Missing commands are not auto-installed at shell runtime.

Optional features are configured per machine in `~/.config/chezmoi/chezmoi.toml`:

```toml
[data.features]
ros2 = false
kicad = false
```

Notes:

- `ros2` is supported on Ubuntu only
- macOS package sync assumes `brew` is already installed
- ROS 2 follows the official Ubuntu flow documented in `docs/ubuntu.md`
- `ros2 = true` only enables ROS-related config paths; it does not install ROS 2 by itself

Current status on March 13, 2026:

- Ubuntu v2 flow has been restructured and validated on a real machine
- macOS structure exists in the repo, but real-machine validation is still pending
