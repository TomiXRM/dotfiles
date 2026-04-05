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

現在は `rust` に加えて `delta` も `mise install` 側で揃える。

## Script 方針

- `run_onchange_*`: manifest 駆動の再実行可能な同期と共有 bootstrap に使う
- `run_once_*`: `chsh` のような軽い一回処理だけに使う
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
```

- `ros2`: Ubuntu 専用の設定分岐
- `kicad`: 任意
- `features.ros2` は ROS-aware な設定を有効にするだけで、ROS 2 自体は install しない
- feature を false にしても自動 uninstall はしない

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
