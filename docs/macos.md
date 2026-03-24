# macOS メモ

macOS 対応は repo 内に構造があり、2026年3月時点で主要フローの実機検証を進めています。

## 想定している挙動

- `brew` は事前導入済みを前提にする
- [run_onchange_10_macos_brew.sh.tmpl](../run_onchange_10_macos_brew.sh.tmpl) が [packages/macos/brew/core.txt](../packages/macos/brew/core.txt) を処理する
- [run_onchange_15_mise_install.sh.tmpl](../run_onchange_15_mise_install.sh.tmpl) が `mise` を `~/.local/bin/mise` に bootstrap する
- [run_onchange_20_macos_cask.sh.tmpl](../run_onchange_20_macos_cask.sh.tmpl) が [packages/macos/cask/core.txt](../packages/macos/cask/core.txt) を処理する
- [packages/macos/cask/fonts.txt](../packages/macos/cask/fonts.txt) で Ghostty 向けフォントを処理する
- `features.kicad = true` の時だけ [packages/macos/cask/kicad.txt](../packages/macos/cask/kicad.txt) を追加する
- `features.ros2` は macOS では無視する
- Ghostty は macOS 専用の設定として管理し、`~/.config/ghostty/config` に配置する

## Ghostty 用フォント方針

- Ghostty の設定では `JetBrains Mono` と `BIZ UDGothic` を使う
- 再現性のため、macOS では [packages/macos/cask/fonts.txt](../packages/macos/cask/fonts.txt) からフォント cask を入れる
- 現在の対象:
  - `font-jetbrains-mono-nerd-font`
  - `font-biz-udgothic`
- `~/.config/ghostty/config` が編集対象で、`ghostty` 自体は Linux では `.chezmoiignore.tmpl` で無視する
- フォント install は `chezmoi apply` 側の cask pipeline に寄せる

## 実機検証でわかったこと

- `brew install --cask` を複数 app に一括で投げると、Homebrew 管理外の既存 `.app` が `/Applications` にあるだけで script 全体が失敗する
  - 例: `visual-studio-code` がすでに `/Applications/Visual Studio Code.app` として存在すると、他の cask まで巻き込んで `chezmoi apply` が落ちる
- `--adopt` は app ごとの差分で失敗しうる
  - 例: `zed` は既存 `Zed.app` に対する adopt 中に app bundle 内の `xattr` 更新で失敗した
  - `zed` では `/opt/homebrew/bin/zed` のような既存 binary artifact でも install が失敗する
- `font-biz-udgothic` では `~/Library/Fonts` に既存 font artifact があるだけで install が失敗する
- 現在の script は cask を 1 件ずつ処理し、Homebrew 管理済みなら skip、Homebrew 管理外の既存 app / font / binary artifact が見つかったら安全のため警告付きで skip する
- 既存 artifact を Homebrew 管理に寄せたい場合は、その app / font / binary を整理してから `chezmoi apply` を再実行する

## 検証したいこと