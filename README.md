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

## `chezmoi.toml` について

任意機能は repo ではなく、そのマシンだけの chezmoi 設定で切り替えます。

```bash
chezmoi edit-config
```

編集先は通常 `~/.config/chezmoi/chezmoi.toml` です。この file は git 管理せず、Mac / Ubuntu / VM ごとに別々の値を持てます。

```toml
[data.features]
ros2 = false
kicad = false
embedded = true

[data.embedded]
armNoneEabiVersion = "15.2.1-1.1.1"
# armNoneEabiVersion = "14.2.1-1.1"

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
