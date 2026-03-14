# リポジトリ運用メモ

## 構成

- `README.md` は人間向けの短い入口
- `docs/architecture.md` は v2 設計の一次情報
- `docs/ubuntu.md` は Ubuntu 固有メモ
- `docs/macos.md` は macOS 検証メモ
- 配置対象は root の `dot_*`, `private_*`, `run_onchange_*`, `run_once_*`, `run_*`
- repo 専用の資料や資産は `docs/`, `packages/`, `assets/`, `.vscode/` に置く
- Windows 用ファイルは `assets/windows/` に置くが、Windows 自体はまだ正式対応しない

## 対応 OS

- `Ubuntu`: 主対象
- `macOS`: 対応対象
- `Windows`: 未対応

## 入口コマンド

- 新規マシン:
  - `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <github-user-or-repo-url>`
- `chezmoi` 導入済み:
  - `chezmoi init --apply <github-user-or-repo-url>`
- ユーザー空間 runtime 導入:
  - `mise install`

## Script ルール

- `run_onchange_*` は manifest 駆動の再実行可能な処理と共有 bootstrap に使う
- `run_once_*` は `chsh` のような軽い一回処理だけに使う
- `run_*` は GUI セッション依存の軽処理に使う
- `mise` 本体の bootstrap は script に入れてよいが、`mise install` は script に入れない
- `cargo install` は標準 apply flow に入れない
- script は OS ごとに分離し、責務を狭く保つ

## 機能フラグ

- 任意機能は `~/.config/chezmoi/chezmoi.toml` で制御する
- 現在の機能:
  - `features.ros2`: Ubuntu 専用
  - `features.kicad`: 任意
- `features.ros2` は ROS 2 の自動 install ではなく、ROS-aware な設定分岐のために使う

## リポジトリ境界

- root に file を追加する前に、配置対象か repo 専用かを決める
- repo 専用なら `.chezmoiignore.tmpl` に入れる
- docs, package manifest, editor cache, local state を `$HOME` に漏らさない

## 最低限の確認

- shell script: `bash -n`
- template script: `chezmoi execute-template < file.tmpl | bash -n`
- JSON: `jq empty`
- Python config: `python3 -m py_compile`
- 設計変更時は `README.md` と `docs/architecture.md` を合わせる

## コミット

- commit message は日本語で短く命令形
- Pull Request の title と body も日本語で書く
- 変更は可能な限り 1 関心に絞る
- 大きい変更では次を明記する
  - 対象 OS
  - 機能フラグ
  - 検証手順
  - `chezmoi apply` 後の手動作業
