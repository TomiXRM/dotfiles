# 環境構築の思想

## 目的

* chezmoi + mise + 他で作るMac/Ubuntuの環境構築
* **どのマシンでも同じ結果**を、**同じ手順**で再現する
* 失敗しても**どこが壊れたか一瞬で分かる**
* 抽象化しすぎない。**分離と順序**で勝つ

---

## レイヤと責務

### 0. bootstrap（入口）

* 役割：**入口を作るだけ**
* やること：`curl/git`確認 → `chezmoi`導入 → `chezmoi init --apply`
* やらないこと：apt/brew/mise/cargo

### 1. chezmoi（司令塔）

* 役割：**設定配布・条件分岐・実行順制御**
* 管轄：dotfiles、OS/arch分岐、スクリプト起動
* 手段：`run_once_XX_*.sh.tmpl`（数字＝順序）

### 2. OSパッケージ（実体）

* Ubuntu：`apt`（システム/CLI/サービス）、`flatpak`（GUI）
* Mac：`brew` / `brew cask`
* 原則：**GUIはOS側**、**サービスはOS側**

### 3. mise（ユーザ空間）

* 役割：**ランタイム/CLIの再現性**
* 管轄：Rust/uv/CLI/code-agent
* ルール：**shell確定後に `mise install`**

### 4. cargo（最後の逃げ道）

* 条件：mise/OSで無理なものだけ
* 方法：宣言ファイル化＋冪等スクリプト

---

## 原則（破るな）

* **抽象化しない**：apt/flatpak/brewを統一しない
* **分離する**：GUI/サービス/CLI/ランタイム
* **順序を固定**：入口→司令→OS→shell→mise→cargo
* **冪等**：何度流しても壊れない

---

## 実行シーケンス（正）

```txt
curl | bash (bootstrap)
  ↓
chezmoi init --apply
  ↓
[10] OS基盤（apt/brew）
  ↓
[20] GUI（flatpak/cask）
  ↓
shell再起動（zsh + mise有効）
  ↓
mise install
  ↓
[90] cargo install（最小）
```

---

## Ubuntuの切り分け

* `apt`：CLI / build / service / driver
* `flatpak`：GUIのみ
* `snap`：使わない（意図的）

---

## ARM/例外の扱い

* テンプレでOS/arch分岐
* 例外は**ビルド用スクリプトに隔離**
* `/opt` or `$HOME/.local` 配置

---

## 失敗しやすい地雷

* chezmoi apply中に `mise install`
* GUIをmiseで管理
* install.sh一枚に全部詰める

---

## 合言葉

* **入口は薄く**
* **司令はchezmoi**
* **実体はOS**
* **再現性はmise**
* **cargoは最後**
