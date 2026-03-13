# macOS メモ

macOS 対応は repo 内に構造がありますが、まだ実機検証していません。

## 想定している挙動

- `brew` は事前導入済みを前提にする
- [run_onchange_10_macos_brew.sh.tmpl](/home/tomixrm/.local/share/chezmoi/run_onchange_10_macos_brew.sh.tmpl) が [packages/macos/brew/core.txt](/home/tomixrm/.local/share/chezmoi/packages/macos/brew/core.txt) を処理する
- [run_onchange_20_macos_cask.sh.tmpl](/home/tomixrm/.local/share/chezmoi/run_onchange_20_macos_cask.sh.tmpl) が [packages/macos/cask/core.txt](/home/tomixrm/.local/share/chezmoi/packages/macos/cask/core.txt) を処理する
- `features.kicad = true` の時だけ [packages/macos/cask/kicad.txt](/home/tomixrm/.local/share/chezmoi/packages/macos/cask/kicad.txt) を追加する
- `features.ros2` は macOS では無視する
- Ghostty は macOS の cask として管理し、設定ファイルは [config.tmpl](/home/tomixrm/.local/share/chezmoi/private_dot_config/ghostty/config.tmpl) から `~/.config/ghostty/config` に配置する

## 検証したいこと

- [packages/macos/brew/core.txt](/home/tomixrm/.local/share/chezmoi/packages/macos/brew/core.txt) の formula 名が正しいか
- [packages/macos/cask/core.txt](/home/tomixrm/.local/share/chezmoi/packages/macos/cask/core.txt) の cask 名が正しいか
- [run_once_10_shell.sh.tmpl](/home/tomixrm/.local/share/chezmoi/run_once_10_shell.sh.tmpl) が、すでに `zsh` を使っている macOS で自然に振る舞うか
- [dot_zprofile](/home/tomixrm/.local/share/chezmoi/dot_zprofile) と [dot_zshrc.tmpl](/home/tomixrm/.local/share/chezmoi/dot_zshrc.tmpl) が標準の macOS shell setup を壊さないか
- VS Code CLI 周りを手動運用のままにするかどうか
- Ghostty の実運用設定をどこまで repo 管理に含めるか

## 現時点の扱い

macOS は「設計済み・未検証」です。実機で検証が終わるまでは、Ubuntu と同じ完成度だとみなさないでください。
