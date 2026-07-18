# dotfiles

- 設計: [docs/architecture.md](docs/architecture.md)
- Ubuntu固有: [docs/ubuntu.md](docs/ubuntu.md)
- Mac固有: [docs/macos.md](docs/macos.md)

## セットアップ

事前に age の鍵を復元します（無いと apply が暗号化ファイルの復号で失敗します。設計は [docs/architecture.md](docs/architecture.md) の「秘密情報」）。

```bash
mkdir -p ~/.config/chezmoi
# Apple パスワードの「age key (chezmoi)」全文を貼り付ける
$EDITOR ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
```

あわせて `~/.config/chezmoi/chezmoi.toml` に `encryption` / `[age]` を書きます（例は下の「`chezmoi.toml` について」）。

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

## `chezmoi.toml` について

任意機能は repo ではなく、そのマシンだけの chezmoi 設定で切り替えます。編集先は通常 `~/.config/chezmoi/chezmoi.toml` 。このファイルはgitで管理しない。

```bash
chezmoi edit-config
```

```toml
encryption = "age"

[age]
    useBuiltin = true
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1ythyyyga4jhspusm7r6pjnqnm6jh2v2x4ez86tu67dm3ngyghgrs6p5jtm" # 公開鍵（秘密ではない）

[data.features]
ros2 = false
kicad = false
embedded = true

[data.embedded]
# armNoneEabiVersion = "15.2.1-1.1.1"
armNoneEabiVersion = "14.2.1-1.1.1"

```

- `encryption` / `[age]`: 秘密情報（暗号化した環境変数）の復号設定。詳細は [docs/architecture.md](docs/architecture.md) の「秘密情報」
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
