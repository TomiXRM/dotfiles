# dotfiles 成長プラン（草案）

## 目的
- `docs/rule.md` の思想（分離・順序・冪等）に沿って、まずは Ubuntu で再現性の高い環境構築を実現する。
- 「入口 → 司令 → OS → shell → mise → cargo」の順序を崩さない。
- Mac 対応は後回し（設計だけ残し、実装は Ubuntu 優先）。

## 現状資産
- 方針: `docs/rule.md`
- 収集対象: `docs/want_to_organize.md`
- 既存資産: `今まで使ってたdotfilesリポジトリ/`（toshy/fcitx5 等）

## ディレクトリ設計（提案）
- `home/`：chezmoi の管理対象（`dot_`/`private_` 命名）
- `scripts/`：補助スクリプト（OS別・機能別）
- `packages/`：パッケージ一覧（例: `apt.txt`, `flatpak.txt`, `cargo.txt`）
- `docs/`：運用ルール/手順/設計メモ
- `bootstrap/`：入口スクリプト（curl で叩く前提）

## フェーズ別ワークフロー
### 1. Bootstrap（入口）
- 目標: `chezmoi` を入れて `chezmoi init --apply` まで到達。
- 成果物: `bootstrap/bootstrap.sh`（curl で取得・実行可能）
- 例: `curl -fsSL <url>/bootstrap.sh | bash`
- 内容: `curl/git` 確認 → `chezmoi` 導入 → `chezmoi init --apply`

### 2. Chezmoi（司令塔）
- 目標: OS/arch 分岐と実行順制御を chezmoi に集約。
- 成果物: `home/` 配下の設定、`run_once_XX_*.sh.tmpl`
- 例:
  - `run_once_10_os_base.sh.tmpl`（apt）
  - `run_once_15_toshy.sh.tmpl`（toshy install → config 適用）
  - `run_once_20_gui.sh.tmpl`（flatpak）
  - `run_once_90_cargo.sh.tmpl`（最後の逃げ道）
- ルール: 数字で順序固定、冪等、OS/arch はテンプレ分岐。

### 3. OSパッケージ
- 目標: GUI/サービスは OS 側で管理（mise に逃がさない）。
- 成果物: `packages/apt.txt`, `packages/flatpak.txt`, `packages/apt_thirdparty.txt`
- 実行: `run_once_10_*` / `run_once_20_*` から呼び出し。

### 4. shell → mise
- 目標: shell 再起動後に `mise install` を実行。
- 成果物: `mise` 設定ファイル（例: `home/.config/mise/config.toml`）
- 実行: `chezmoi apply` 後に手順として明記（自動実行は避ける）

### 5. cargo（最終手段）
- 目標: OS/mise で入らないものだけを最小で扱う。
- 成果物: `packages/cargo.txt` + 冪等インストールスクリプト

## 既存資産の取り込み方針
- `今まで使ってたdotfilesリポジトリ/keyboards/` を段階的に `home/.config/` へ移植。
- `toshy_config.py` や `fcitx5` の設定は最優先で chezmoi 化。
- 移植後、旧リポジトリは参照専用にする（削除は後回し）。

## Ubuntu 向け詳細（優先）
- 前提: `snap` は使わない（意図的）。
- 入力系（最優先）:
  - `fcitx5`, `fcitx5-mozc`（apt）
  - `toshy`（git clone + script）
  - `xremap`（設定不要、インストールだけ）
  - `toshy_config.py` を `~/.config/toshy/toshy_config.py` に配置
- GUI（apt/flatpak）:
  - `zed`, `vscode`（apt）
  - `KiCAD`（flatpak）
  - Chrome は deb 直インストール（例: `wget ... && sudo apt install ./google-chrome-stable_current_amd64.deb`）
- OS 基盤:
  - `flatpak`, `gnome-sushi`, `gnome-shell-extension-manager`, `net-tools`, `can-utils`
- 例コマンド（apt）:
  - `sudo apt update && sudo apt install -y $(cat packages/apt.txt)`

## Toshy のシーケンス（重要）
- Toshy のインストール後に `toshy_config.py` をコピーする。
- `assets/toshy/toshy_config.py` を `run_once_15_toshy.sh.tmpl` で適用する。
- Toshy 本体は一時ディレクトリに clone して、インストール後に削除する。

## 実行フロー（新規マシン）
1. `bootstrap.sh` 実行
2. `chezmoi init --apply`
3. `run_once_10_*`（OS 基盤）
4. `run_once_20_*`（GUI）
5. shell 再起動
6. `mise install`
7. `run_once_90_*`（cargo 最小）

## 実行フロー（既存マシン）
- 現状を正として `chezmoi add` で取り込み → 破壊的変更は避ける。
- 取り込み後に `diff` で確認し、OS/arch 分岐へ整理。

## 検証チェックリスト
- `chezmoi apply` を複数回流しても破綻しない。
- Ubuntu で OS/arch 分岐が想定通り動作する。
- GUI インストールが OS 側で完結している。
- shell 再起動 → `mise install` の順序が守られている。

## 直近の作業チケット（提案）
- [ ] 入口: `bootstrap/` の整備
- [ ] `packages/` の雛形作成（apt/flatpak/cargo）と依存追加
- [ ] `run_once_10_*.sh.tmpl` の作成
- [ ] `run_once_15_toshy.sh.tmpl` の作成
- [ ] `fcitx5` の設定移植（現行PCの設定を使用）
- [ ] Chrome deb インストールの手順スクリプト化

## 承認ポイント
- ディレクトリ構成とファイル命名
- run_once の分割方針（番号/責務）
- mise の実行方法（手動 or 自動）
