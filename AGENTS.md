# リポジトリ運用メモ

設計・構成・対応 OS・配置ルール・feature flag・script 方針は [docs/architecture.md](docs/architecture.md) を正本とする。`AGENTS.md` には重複して書かない。

## 参照順

- 入口: `README.md`
- 設計判断: `docs/architecture.md`
- OS 固有の補足: `docs/ubuntu.md`, `docs/macos.md`

## 変更時の最低限

- 設計に関わる変更は `docs/architecture.md` を更新し、`README.md` は入口として整合だけ保つ
- 編集は source state で行い、`$HOME` の target file を直接編集しない
- source から target を確認する時は `chezmoi target-path <source-path>` を使う
- target から source を確認する時は `chezmoi source-path <target-path>` を使う
- render 後の target 内容を確認する時は `chezmoi cat <target-path>` を使う
- repo 全体の非破壊検証は `make validate` を入口にする
- 変更後は対象 `source-path` ごとに次を順に確認する
- `chezmoi status --source-path <source-path>`
- `chezmoi diff --source-path <source-path>`
- `chezmoi apply --dry-run --verbose --source-path <source-path>`
- file / symlink を安全に staging 検証したい時は scripts を除外して次を使う
- `chezmoi apply --destination /tmp/chezmoi-validate-home --exclude=scripts --source-path <source-path>`
- `chezmoi verify --destination /tmp/chezmoi-validate-home --exclude=scripts --source-path <source-path>`
- `run_*` は staging apply しない。render と syntax check と dry-run までに留める
- `run_*.sh.tmpl`: `chezmoi execute-template --file <source-path> | bash -n`
- zsh config の template: `chezmoi execute-template --file <source-path> | zsh -n`
- zsh config の非 template: `zsh -n <file>`
- shell script を新規追加した時だけ `bash -n <file>`
- shell 以外の `*.tmpl`: `chezmoi execute-template --file <source-path> >/dev/null`
- JSON: `jq empty <file>`
- Python config: `python3 -m py_compile <file>`
- feature flag や template data を触った時は `chezmoi data --format=yaml` で現在値を確認する
- feature flag の分岐を試す時は `chezmoi execute-template --file <source-path> --override-data '{"features":{"ros2":false}}'` のように確認する
- `run_onchange_*` を再評価したい時だけ `chezmoi state delete-bucket --bucket=entryState` を使う
- `run_once_*` を再実行したい時だけ `chezmoi state delete-bucket --bucket=scriptState` を使う

## コミット

- commit message は日本語で短く命令形
- Pull Request の title と body も日本語で書く
- 変更は可能な限り 1 関心に絞る
- 大きい変更では対象 OS、機能フラグ、検証手順、`chezmoi apply` 後の手動作業を明記する
