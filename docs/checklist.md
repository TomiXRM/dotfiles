# 評価チェックリスト（Ubuntu）

このリポジトリの導入が「順序通り・再現可能・副作用なし」で動くかを確認するための最小チェックです。

## 入口（bootstrap）
- [ ] `bootstrap/bootstrap.sh` が実行できる
- [ ] `chezmoi` がインストールされる（`chezmoi --version`）
- [ ] `chezmoi init --apply <repo>` が通る

## 冪等性（最重要）
- [ ] `chezmoi apply` を2回連続で実行してもエラーなし

## 実行順序（run_once）
- [ ] `run_once_10_os_base` が apt を処理する
- [ ] `run_once_11_zsh` が zsh をデフォルトに設定する
- [ ] `run_once_12_apt_thirdparty` が未登録パッケージをスキップする
- [ ] `run_once_15_toshy` がインストール後に `toshy_config.py` をコピーする
- [ ] `run_once_20_gui` が flatpak を処理する
- [ ] `run_once_90_cargo` が必要時のみ動作する

## シェル・PATH・mise
- [ ] `echo "$SHELL"` が zsh になっている
- [ ] `~/.local/bin` が PATH に含まれている
- [ ] `mise --version` が通る

## 入力系（Ubuntu）
- [ ] `~/.config/fcitx5/` の設定が適用されている
- [ ] `~/.config/toshy/toshy_config.py` が存在する

## third-party apt
- [ ] `docs/thirdparty_apt.md` の手順を実行済み
- [ ] `packages/apt_thirdparty.txt` の対象がインストールできる
