# macOS Notes

macOS support exists in the repository design, but it has not been validated on a real machine yet.

Current intended behavior:

- `brew` is assumed to be preinstalled
- [run_onchange_10_macos_brew.sh.tmpl](/home/tomixrm/.local/share/chezmoi/run_onchange_10_macos_brew.sh.tmpl) installs CLI packages from [packages/macos/brew/core.txt](/home/tomixrm/.local/share/chezmoi/packages/macos/brew/core.txt)
- [run_onchange_20_macos_cask.sh.tmpl](/home/tomixrm/.local/share/chezmoi/run_onchange_20_macos_cask.sh.tmpl) installs GUI packages from [packages/macos/cask/core.txt](/home/tomixrm/.local/share/chezmoi/packages/macos/cask/core.txt)
- `features.kicad = true` adds [packages/macos/cask/kicad.txt](/home/tomixrm/.local/share/chezmoi/packages/macos/cask/kicad.txt)
- `features.ros2` is ignored on macOS

Validation to do on a real Mac:

- confirm Homebrew formula names in [packages/macos/brew/core.txt](/home/tomixrm/.local/share/chezmoi/packages/macos/brew/core.txt)
- confirm cask names in [packages/macos/cask/core.txt](/home/tomixrm/.local/share/chezmoi/packages/macos/cask/core.txt)
- confirm [run_once_10_shell.sh.tmpl](/home/tomixrm/.local/share/chezmoi/run_once_10_shell.sh.tmpl) behaves sensibly when `zsh` is already the default shell
- confirm [dot_zprofile](/home/tomixrm/.local/share/chezmoi/dot_zprofile) and [dot_zshrc.tmpl](/home/tomixrm/.local/share/chezmoi/dot_zshrc.tmpl) do not interfere with the default macOS shell setup
- decide whether VS Code command-line setup should stay manual on macOS

Until that validation is complete, treat macOS support as planned rather than fully verified.
