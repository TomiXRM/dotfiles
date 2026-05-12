# dotfiles

`Ubuntu` と `macOS` 向けの `chezmoi` ベース dotfiles です。設計の正本は [docs/architecture.md](docs/architecture.md) に置き、OS 固有の補足は [docs/ubuntu.md](docs/ubuntu.md) と [docs/macos.md](docs/macos.md) に分けます。

## セットアップ

新規マシン:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply TomiXRM
```

`chezmoi` 導入済み:

```bash
chezmoi init --apply TomiXRM
```

`chezmoi apply` は dotfiles 配置と軽量 script 実行までを担います。ユーザー空間 runtime はその後に明示的に入れます。

```bash
mise install
```

## 要点

- 正式対応は `Ubuntu` と `macOS`。`Windows` は未対応で、資産は `assets/windows/` にだけ置く
- file の存在を OS で切り替える時は `.chezmoiignore.tmpl` を使う
- file の内容を `chezmoi data` や feature flag で切り替える時だけ `*.tmpl` を使う
- `features.ros2` は Ubuntu 専用の設定分岐で、ROS 2 の自動 install はしない
- 任意機能は `~/.config/chezmoi/chezmoi.toml` の `data.features` で切り替える

```toml
[data.features]
ros2 = false
kicad = false
embedded = false
```

`features.embedded` は `dot_zshrc.tmpl` 内で `embeddedEnabled` として扱われ、`true` の時だけ組み込み開発用 PATH を追加します。ツール本体は自動 install しません。

`arm-none-eabi-gcc` は xPack の配置済み version を PATH に追加します。version を切り替える時は、対象 version を install したうえで machine-local data を変えてから apply します。

```toml
[data.embedded]
armNoneEabiVersion = "15.2.1-1.1.1"
```

反映確認:

```bash
chezmoi execute-template --file dot_zshrc.tmpl --override-data '{"features":{"embedded":true},"embedded":{"armNoneEabiVersion":"15.2.1-1.1.1"}}' | rg 'ARM_NONE_EABI_VERSION|arm-none-eabi'
chezmoi apply --source-path dot_zshrc.tmpl
```
