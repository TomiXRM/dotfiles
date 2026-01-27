# dotfilesを作るぞ！！

## 使い方（Ubuntu優先）
### 入口（bootstrap）
```bash
./bootstrap/bootstrap.sh <github-username or repo-url>
```

### 通常フロー
```bash
chezmoi init --apply <github-username or repo-url>
```

### 実行順序（重要）
1. `bootstrap/bootstrap.sh` 実行
2. `chezmoi init --apply`
3. `run_once_10_os_base.sh.tmpl`（apt）
4. `run_once_11_zsh.sh.tmpl`（zsh をデフォルトシェルに設定）
5. `run_once_12_apt_thirdparty.sh.tmpl`（外部リポジトリ前提のapt）
6. `run_once_15_toshy.sh.tmpl`（toshy install → config適用）
7. `run_once_20_gui.sh.tmpl`（flatpak）
8. shell 再起動
9. `mise install`
10. `run_once_90_cargo.sh.tmpl`（cargo）

### 注意
- `toshy_config.py` は Toshy のインストール後にコピーする（run_once_15）。
- GUI は flatpak を優先、`snap` は使わない。
- `packages/apt_thirdparty.txt` は外部リポジトリ追加が必要なものを分離（リポジトリ追加は手動で行う）。
- 追加手順は `docs/thirdparty_apt.md` を参照。
