# dotfiles

- 設計: [docs/architecture.md](docs/architecture.md)
- Ubuntu固有: [docs/ubuntu.md](docs/ubuntu.md)
- Mac固有: [docs/macos.md](docs/macos.md)

## セットアップ

新規マシン:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply TomiXRM
```

秘密（`COSENSE_PAT` 等）は repo に入っていません。必要なマシンだけ手で作ります。無くても apply は通ります。

```bash
mkdir -p ~/.config/ai && chmod 600 ~/.config/ai/secrets.env
$EDITOR ~/.config/ai/secrets.env   # export COSENSE_PAT=...
```

`chezmoi` 導入済み:

```bash
chezmoi init --apply TomiXRM
```

`chezmoi apply` は dotfiles 配置と軽量 script 実行までを担います。ユーザー空間 runtime はその後に明示的に入れます。

```bash
mise install
```

## `chezmoi.toml` について

## プロファイル

`profile` でこの repo が何を配置するかを切り替えます。既定は `full`（全部）。

| profile | 対象 | 用途 |
|---|---|---|
| `full`（既定） | 全部 | 自分の常用マシン |
| `input` | Ubuntu のキーボード/日本語入力設定だけ | 会社の PC、実験用 NUC |

`input` で入るのは fcitx5 の設定・`.xinputrc`・toshy の設定・xremap の GNOME 拡張と、
それらを入れる 2 本のスクリプトだけです。zsh・mise・エージェント類・個人の
git 設定などは一切配置されません。

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init TomiXRM
chezmoi edit-config     # [data] profile = "input" を書く
chezmoi apply
```

```toml
[data]
profile = "input"
```

`.chezmoiignore.tmpl` は「全部無視してから入力まわりだけ名指しで戻す」アローリスト
方式なので、repo にファイルが増えても `input` に勝手に混ざりません。

任意機能は repo ではなく、そのマシンだけの chezmoi 設定で切り替えます。編集先は通常 `~/.config/chezmoi/chezmoi.toml` 。このファイルはgitで管理しない。

```bash
chezmoi edit-config
```

```toml
[data.features]
ros2 = false
kicad = false
embedded = true

[data.embedded]
# armNoneEabiVersion = "15.2.1-1.1.1"
armNoneEabiVersion = "14.2.1-1.1.1"

```

- `features`
  - `features.ros2`: Ubuntu 専用の設定分岐。ROS 2 自体は install しない
  - `features.kicad`: 任意の KiCad install 分岐
  - `features.embedded`: `dot_zshrc.tmpl` 内で `embeddedEnabled` として扱い、`true` の時だけ組み込み開発用 PATH を追加する
- `arm-none-eabi-gcc` の version 切り替え
  - `features.embedded = true` の時、`arm-none-eabi-gcc` は xPack の配置済み version を PATH に追加します。toolchain 本体は自動 install しない
  - 配置先
    - macOS: `~/Library/xPacks/@xpack-dev-tools/arm-none-eabi-gcc/<version>/.content/bin`
    - Linux: `~/.local/xPacks/@xpack-dev-tools/arm-none-eabi-gcc/<version>/.content/bin`

反映:

```bash
chezmoi apply --source-path dot_zshrc.tmpl
exec zsh
```

確認:

```bash
echo "$ARM_NONE_EABI_VERSION"
command -v arm-none-eabi-gcc
```
