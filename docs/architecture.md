# chezmoi v2 設計

この文書を設計の正本とする。`README.md` は入口、`docs/ubuntu.md` と `docs/macos.md` は OS 固有メモに留める。

## 対象

- `Ubuntu`: 主対象
- `macOS`: 対応対象
- `Windows`: 未対応

Windows 用資産は `assets/windows/` に置いてよいが、`chezmoi` が `$HOME` に配置してはいけない。

## 原則

- 正規入口は `chezmoi` の公式フローだけを使う
- `Ubuntu` と `macOS` を無理に同一化しない
- repo 専用 file を `$HOME` に漏らさない
- file の"存在"を OS で切り替える時は `.chezmoiignore.tmpl` を使う
- file の"内容"を `chezmoi data` や feature flag で切り替える時だけ `*.tmpl` を使う
- 暗黙の `hostname` や branch 分岐より `data.features` を優先する
- `chezmoi apply` は dotfiles 配置と軽量 script 実行までを担い、すべての runtime install を自動化しない

## 実行モデル

新規マシン:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <github-user-or-repo-url>
```

`chezmoi` 導入済み:

```bash
chezmoi init --apply <github-user-or-repo-url>
```

`chezmoi apply` の責務:

- dotfiles を `$HOME` に配置する
- local data を使って template を render する
- `run_onchange_*`, `run_once_*`, `run_*` を実行する
- manifest 駆動の package 同期と `mise` 本体の bootstrap を起動する

`chezmoi apply` の責務ではないもの:

- `mise install`
- `cargo install`
- ROS 2 の install
- feature を false にした時の自動 uninstall

ユーザー空間 runtime は `chezmoi apply` の後で明示的に入れる。

```bash
mise install
```

現在は `rust`、`delta`、Node.js LTS、coding agent CLI も `mise install` 側で揃える。

## Script 方針

- `run_onchange_*`: manifest 駆動の再実行可能な同期、共有 bootstrap、依存 package 導入後に行う軽い idempotent 設定に使う
- `run_once_*`: 依存関係を持たない軽い一回処理だけに使う
- `run_*`: GUI セッション依存の軽い後処理だけに使う

追加ルール:

- package 同期は OS ごとの `run_onchange_*` script で扱う
- script は OS ごとに分離し、責務を狭く保つ
- `mise install` と `cargo install` は標準 apply flow に入れない
- plain `run_*` が `chezmoi status` で `R` と表示されるのは通常挙動

## 機能フラグ

任意機能は各マシンのローカル設定で制御する。

`~/.config/chezmoi/chezmoi.toml`

```toml
[data.features]
ros2 = false
kicad = false
embedded = false
```

- `ros2`: Ubuntu 専用の設定分岐
- `kicad`: 任意
- `embedded`: 組み込み開発用の shell PATH 設定を有効にする
- `features.ros2` は ROS-aware な設定を有効にするだけで、ROS 2 自体は install しない
- `features.embedded` は `dot_zshrc.tmpl` 内では `embeddedEnabled` として扱い、toolchain 自体は install しない
- feature を false にしても自動 uninstall はしない

組み込み開発用 toolchain の version は machine-local data で切り替える。

```toml
[data.embedded]
armNoneEabiVersion = "15.2.1-1.1.1"
```

## 秘密情報

環境変数の秘密（API キー等）は age で暗号化して repo に置く。

- 対象: `~/.config/ai/secrets.env`（source は `private_dot_config/ai/encrypted_private_secrets.env.age`）
- `dot_zshrc.tmpl` が存在する時だけ source する。apply 後は `$HOME` に 0600 の平文で配置される
- 復号の設定は machine-local の `~/.config/chezmoi/chezmoi.toml` に置く（repo には入れない）

```toml
encryption = "age"

[age]
    useBuiltin = true
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1ythyyyga4jhspusm7r6pjnqnm6jh2v2x4ez86tu67dm3ngyghgrs6p5jtm"
```

- 秘密鍵は `~/.config/chezmoi/key.txt`（0600、repo 外）。バックアップとして Apple パスワードの項目「age key (chezmoi)」に key.txt 全文を保存する
- recipient（公開鍵）は秘密ではない。key.txt のコメント行にも同じ値がある
- `useBuiltin = true` のため runtime に age バイナリは不要（chezmoi 内蔵実装で復号する）。外部 `age` が要るのは `age-keygen` する時だけ
- 編集は `chezmoi edit --apply <target-path>`（復号→編集→再暗号化→apply まで一括）
- 秘密を追加する時は target に置いてから `chezmoi add --encrypt <target-path>`
- 新規マシンでは **`chezmoi init --apply` の前に** key.txt と上記 `[age]` 設定を復元する。無いと encrypted file の復号で apply が失敗する

## テンプレートと ignore

- file の存在自体を OS で切り替える時は `.chezmoiignore.tmpl` を使う
- file の内容を `chezmoi data` や feature flag で切り替える時だけ `*.tmpl` を使う
- repo 専用 path は `.chezmoiignore.tmpl` で除外する

## リポジトリ境界

配置対象:

- `dot_*`
- `private_*`
- `run_onchange_*`
- `run_once_*`
- `run_*`
- `.chezmoiexternal.toml`

repo 専用:

- `Makefile`
- `.github/`
- `docs/`
- `packages/`
- `assets/`
- `.vscode/`
- `AGENTS.md`
- 一時的 local state

OS ごとの package manifest と補足資料は repo 専用領域に置く。

## 保守ルール

- `README.md` は短く保ち、この文書へ誘導する
- repo 全体の非破壊検証は `make validate` を入口にする
- GitHub Actions の validation も `make validate` だけを呼ぶ薄い wrapper に保つ
- root に新しい file を置く前に、配置対象か repo 専用かを決める
- repo 専用 path を追加したら `.chezmoiignore.tmpl` に反映する
- 設計変更時は `README.md` とこの文書を合わせる
