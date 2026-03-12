# Ubuntu Notes

This document describes the intended Ubuntu behavior for the v2 repository.

This flow was validated on an Ubuntu machine on March 13, 2026.

## Target Assumptions

- target distro: Ubuntu 24.04 (`noble`)
- desktop environment: GNOME
- shell: `zsh`
- input stack: `fcitx5` + `mozc` + `Toshy` + managed `xremap` extension

## Ubuntu Layers

### 1. Core apt

Managed by:

- [run_onchange_10_ubuntu_apt.sh.tmpl](/home/tomixrm/.local/share/chezmoi/run_onchange_10_ubuntu_apt.sh.tmpl)
- [packages/ubuntu/apt/core.txt](/home/tomixrm/.local/share/chezmoi/packages/ubuntu/apt/core.txt)

This layer contains repeatable CLI and system packages that should exist on every Ubuntu machine managed by this repo.

When every manifest entry is already installed, the script skips `apt-get update`.

### 2. GUI apt and flatpak

Managed by:

- [run_onchange_20_ubuntu_gui.sh.tmpl](/home/tomixrm/.local/share/chezmoi/run_onchange_20_ubuntu_gui.sh.tmpl)
- [packages/ubuntu/apt/gui.txt](/home/tomixrm/.local/share/chezmoi/packages/ubuntu/apt/gui.txt)
- [packages/ubuntu/flatpak/core.txt](/home/tomixrm/.local/share/chezmoi/packages/ubuntu/flatpak/core.txt)
- [packages/ubuntu/flatpak/kicad.txt](/home/tomixrm/.local/share/chezmoi/packages/ubuntu/flatpak/kicad.txt)

`features.kicad = true` adds KiCad through flatpak.

When the configured apt and flatpak entries are already present, the script skips both `apt-get update` and flatpak installs.

### 3. Input stack

Managed by:

- [run_onchange_30_ubuntu_input.sh.tmpl](/home/tomixrm/.local/share/chezmoi/run_onchange_30_ubuntu_input.sh.tmpl)
- [run_40_ubuntu_gnome_input.sh.tmpl](/home/tomixrm/.local/share/chezmoi/run_40_ubuntu_gnome_input.sh.tmpl)
- [packages/ubuntu/apt/input.txt](/home/tomixrm/.local/share/chezmoi/packages/ubuntu/apt/input.txt)

This layer installs:

- `fcitx5`
- `fcitx5-mozc`
- `fcitx5-config-qt`
- Toshy using its upstream installer, currently tracking the `TOSHY_REF` value in [run_onchange_30_ubuntu_input.sh.tmpl](/home/tomixrm/.local/share/chezmoi/run_onchange_30_ubuntu_input.sh.tmpl)
- existing Toshy installs are treated as satisfied unless the desired `TOSHY_REF` changes
- xremap GNOME enablement is retried by a lightweight `run_*` script so it can succeed later from an active GNOME session

When the manifest packages are already installed, this layer skips `apt-get update` and only evaluates the Toshy state logic.

The following files are deployed directly by `chezmoi`:

- [dot_xinputrc](/home/tomixrm/.local/share/chezmoi/dot_xinputrc)
- [private_profile](/home/tomixrm/.local/share/chezmoi/private_dot_config/private_fcitx5/private_profile)
- [private_config](/home/tomixrm/.local/share/chezmoi/private_dot_config/private_fcitx5/private_config)
- [org.fcitx.Fcitx5.desktop](/home/tomixrm/.local/share/chezmoi/private_dot_config/autostart/org.fcitx.Fcitx5.desktop)
- [toshy_config.py](/home/tomixrm/.local/share/chezmoi/private_dot_config/toshy/toshy_config.py)
- [extension.js](/home/tomixrm/.local/share/chezmoi/private_dot_local/private_share/gnome-shell/extensions/xremap@k0kubun.com/extension.js)

## Feature Flags

Machine-local feature flags live in:

`~/.config/chezmoi/chezmoi.toml`

```toml
[data.features]
ros2 = false
kicad = false
```

### `kicad`

- Ubuntu optional
- when `true`, KiCad is installed from [packages/ubuntu/flatpak/kicad.txt](/home/tomixrm/.local/share/chezmoi/packages/ubuntu/flatpak/kicad.txt)

### `ros2`

- Ubuntu optional
- does not auto-install from the standard `run_onchange` package manifests
- enables ROS-related shell configuration in generated dotfiles
- follow the official ROS 2 Jazzy Ubuntu instructions instead

Official ROS 2 docs:

- ROS 2 Jazzy installation overview: https://docs.ros.org/en/jazzy/Installation.html
- Ubuntu deb packages: https://docs.ros.org/en/jazzy/Installation/Ubuntu-Install-Debs.html

Recommended package choice from the official docs:

- `ros-jazzy-desktop` for a full desktop install
- `ros-jazzy-ros-base` if a bare-bones install is enough

Important:

- `features.ros2 = true` does not install ROS 2 by itself
- it only tells this repository to treat the machine as ROS-aware
- the generated shell config will only activate ROS if `/opt/ros/*/setup.zsh` exists

## Third-Party Packages

Managed by:

- [packages/ubuntu/apt_thirdparty/core.txt](/home/tomixrm/.local/share/chezmoi/packages/ubuntu/apt_thirdparty/core.txt)

These package names are allowed in the package sync flow, but the required repositories must exist first.

Current third-party packages:

- `tailscale`
- `code`

Official installation docs:

- Tailscale Linux: https://tailscale.com/docs/install/linux
- VS Code download/install: https://code.visualstudio.com/download
- Zed Linux installation: https://zed.dev/docs/installation

Zed is intentionally documented as a manual follow-up item for now instead of an automatic Ubuntu package.

## Post-Apply Manual Steps

After `chezmoi init --apply` or `chezmoi apply`:

1. If the login shell changed, log out and back in.
2. Run `mise install` to install the tools declared in [dot_mise.toml](/home/tomixrm/.local/share/chezmoi/dot_mise.toml).
3. If `features.ros2 = true`, follow the official ROS 2 Ubuntu installation docs.
4. If the GNOME extension is not immediately active, restart the GNOME session and re-run `chezmoi apply` so [run_40_ubuntu_gnome_input.sh.tmpl](/home/tomixrm/.local/share/chezmoi/run_40_ubuntu_gnome_input.sh.tmpl) can retry enablement.

## Validation Checklist

Base validation:

- `echo "$SHELL"`
- `command -v mise`
- `command -v fcitx5`
- `test -f ~/.config/toshy/toshy_config.py`
- `gsettings get org.gnome.shell enabled-extensions`

Optional validation:

- `flatpak list | grep org.kicad.KiCad`
- `ros2 --help`

## Known Follow-Up Items

- Decide whether `mise` tools should stay on `latest` or be pinned later
- Decide whether Toshy should be pinned to a tag or commit instead of tracking `main`
- Verify whether additional Ubuntu-native packages are needed specifically for Toshy on fresh machines
- Decide whether Zed should remain manual on Ubuntu or be modeled through a supported package path later
