# Cosense側の一回きりセットアップ

以下人間がやりまする

## 1. AI行の薄表示CSS（project settings → UserCSS）

自分のprojectの settings ページに:

```
code:style.css
 .deco-\( {
   opacity: 0.5;
 }
```

これで `[( ...]` で包まれた行（=AIドラフト）が薄く表示される。
カッコ`[(`と文章の間にはスペース1個挟む必要あり。

## 2. 承認UI

自分のprofileページ（`<project>/<自分の名前>`）の code:script.js に1行:

```
code:script.js
 import '/api/code/tkgshn-extension/llm-auto-humanize/script.js';
```

ハードリロード後、ブラウザconsoleに `[llm-auto-humanize] active` が出ればOK。

- 薄い行を選択 → ポップアップ「承認」で人間色に昇格（複数行可、スマホ本命）
- 薄い行を編集してカーソル/フォーカスを離すと自動承認（PCの保険）
- 白い行を選択 → 「灰色に」で逆操作（往復可）

tkgshn-extension は public project で、コードは単一ソース（彼が直すと全importer に即反映）。
挙動を固定したくなったら自分のprojectにコードをコピーして import 先を差し替える。

## 3. Personal Access Token（PAT）

1. scrapbox.io → settings → Personal Access Tokens で発行
2. `chezmoi edit --apply ~/.config/ai/secrets.env` で1行追記: `export COSENSE_PAT=<発行したPAT>`
3. `exec zsh` → `cosense whoami <cosense url>` で確認

PATは自分のアカウント紐付けなので、メンバー招待されているprivate project（tkgshnのもの等）もこのPATで読める。
`COSENSE_PAT` は `~/.cosense/settings.json` より優先される（headless/新マシンでもsecrets.envの復元だけで動く）。
