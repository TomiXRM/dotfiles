# macOS メモ

macOS 対応は repo 内に構造があり、2026年3月時点で主要フローの実機検証を進めています。

## 想定している挙動

- `brew` は事前導入済みを前提にする
- [run_onchange_10_macos_brew.sh.tmpl](/home/tomixrm/.local/share/chezmoi/run_onchange_10_macos_brew.sh.tmpl) が [packages/macos/brew/core.txt](/home/tomixrm/.local/share/chezmoi/packages/macos/brew/core.txt) を処理する
- [run_onchange_20_macos_cask.sh.tmpl](/home/tomixrm/.local/share/chezmoi/run_onchange_20_macos_cask.sh.tmpl) が [packages/macos/cask/core.txt](/home/tomixrm/.local/share/chezmoi/packages/macos/cask/core.txt) を処理する
- `features.kicad = true` の時だけ [packages/macos/cask/kicad.txt](/home/tomixrm/.local/share/chezmoi/packages/macos/cask/kicad.txt) を追加する
- `features.ros2` は macOS では無視する
- Ghostty は macOS の cask として管理し、設定ファイルは [config.tmpl](/home/tomixrm/.local/share/chezmoi/private_dot_config/ghostty/config.tmpl) から `~/.config/ghostty/config` に配置する

## 実機検証でわかったこと

- `brew install --cask` を複数 app に一括で投げると、Homebrew 管理外の既存 `.app` が `/Applications` にあるだけで script 全体が失敗する
- 例: `visual-studio-code` がすでに `/Applications/Visual Studio Code.app` として存在すると、他の cask まで巻き込んで `chezmoi apply` が落ちる
- `--adopt` は app ごとの差分で失敗しうる
- 例: `zed` は既存 `Zed.app` に対する adopt 中に app bundle 内の `xattr` 更新で失敗した
- `zed` では `/opt/homebrew/bin/zed` のような既存 binary artifact でも install が失敗する
- 現在の script は cask を 1 件ずつ処理し、Homebrew 管理済みなら skip、Homebrew 管理外の既存 app や binary artifact が見つかったら安全のため警告付きで skip する
- 既存 artifact を Homebrew 管理に寄せたい場合は、その app や binary を整理してから `chezmoi apply` を再実行する

## 検証したいこと

- [packages/macos/brew/core.txt](/home/tomixrm/.local/share/chezmoi/packages/macos/brew/core.txt) の formula 名が正しいか
- [packages/macos/cask/core.txt](/home/tomixrm/.local/share/chezmoi/packages/macos/cask/core.txt) の cask 名が正しいか
- [run_once_10_shell.sh.tmpl](/home/tomixrm/.local/share/chezmoi/run_once_10_shell.sh.tmpl) が、すでに `zsh` を使っている macOS で自然に振る舞うか
- [dot_zprofile](/home/tomixrm/.local/share/chezmoi/dot_zprofile) と [dot_zshrc.tmpl](/home/tomixrm/.local/share/chezmoi/dot_zshrc.tmpl) が標準の macOS shell setup を壊さないか
- VS Code CLI 周りを手動運用のままにするかどうか
- Ghostty の実運用設定をどこまで repo 管理に含めるか

## 現時点の扱い

macOS は Ubuntu より検証量が少ないですが、主要な `brew` / `cask` / shell 初期化フローは実機で確認を進めています。未確認事項が残る間は、Ubuntu と同じ完成度だとはみなさないでください。
