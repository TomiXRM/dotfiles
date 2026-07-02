---
name: cosense
description: >
  Cosense(旧Scrapbox)を知識の集約場所として検索・参照・追記する。ユーザが「メモして」「Cosenseに
  保存/記録して」「前に決めた/調べたことあったっけ」と言った時、調査・設計・障害対応を始める前の
  知識recall、および設計判断・ハマりどころ・セッションhandoverの記録(capture)に使う。
  書き込みは自分のprojectのみ。tkgshn系projectは読み取り専用で、書き込みは絶対にしない。
---

# Cosense 知識ベース連携

CLI: `cosense`（Cosense運営元Helpfeel公式 `@helpfeel/cosense-cli`、mise の npm backend で管理）。
コマンドが見つからない環境では `mise x -- cosense ...` で呼ぶ。
開発の速いCLIなので、迷ったら `cosense <cmd> --help`（日本語）を正とする。

認証: `COSENSE_PAT`（`~/.config/ai/secrets.env`、age暗号化でchezmoi管理）。
`cosense whoami` が失敗したら未設定なので、ユーザにPAT設定を頼む（発行手順は references/browser-setup.md）。

## 設定

- 書き込み先（自分）: `https://scrapbox.io/tmxrm`
- 読み取り専用: tkgshn の各project（例: `https://scrapbox.io/tkgshn-private`。閲覧権限で読める）。**previewEdit の発行すら禁止**

## recall（読む）— 調査・設計・障害対応の開始時に、まず1回引く

安い順に:

0. **ローカルミラーがあれば最優先**: `rg <語> ~/front/cache/cosense/tmxrm/`（0トークン・最速・オフライン可。1ファイル=1ページ、1行目=正式タイトル。ブラケットリンク `[ページ名]` も本文に生で入っているので、関連ページの芋づる探索も rg でできる）。鮮度が必要なら先に `~/front/bin/cosense-sync` で差分同期
1. `cosense searchVector <projectUrl> "<自然文クエリ>"` — 意味検索（ミラーでは代替できない）
2. `cosense searchFullText <projectUrl> "<語>"` — 文字列一致（ミラーが無い環境向け）
3. `cosense browsePage <pageUrl>` — 本文をAI向け整形で読む（pageUrl = `<projectUrl>/<タイトル>`）
4. `cosense browseRelatedPages` / `list2hopLinks` — 周辺展開。トークンが重いので必要時のみ

ヒットした知見を使ったら、返答にページ名を出典として添える。

## capture（書く）

原則: **新規ページの乱造より既存ページへの追記**。書く前に必ず検索して置き場所を探す。

既存ページへの追記:

1. `cosense readPage <pageUrl>` → top-level `id`（pageId）と `lines[].id` を得る
2. ops JSON を stdin で `cosense previewEdit <projectUrl> <pageId>` に渡す
   - 末尾追記: `{"ops":[{"insertBefore":"_end","text":"1行目\n2行目"}]}`（`\n` で複数行）
   - 行置換: `{"ops":[{"replace":"<lineId>","text":"単行のみ"}]}`（改行入りtextは拒否される）
3. preview出力を確認してから `cosense submitEdit <projectUrl> <previewId>`
   - previewId は **5分で失効・1回限り**。409 NotFastForward が返ったら読み直して再preview

新規ページ（置き場が本当に無い時だけ）:

```
printf '%s' "ページタイトル\n 本文1行目\n 本文2行目" | cosense previewEdit --new <projectUrl>
```

1行目がtitle、2行目以降が本文。確認して submitEdit。

## 記法規約（tkgshn方式を踏襲）

- Scrapbox記法で書く。Markdownを書かない: `#見出し`・`**太字**` は禁止。箇条書き＋行頭スペースの階層で表現する
- 本文行は行頭スペース1個のインデントから始める。空行は空白を含まない完全な空行にする
- AI（自分）が書く行は `[( ...]` で包む（UserCSSで薄表示＝未承認ドラフト。人間が承認すると濃色に昇格する運用）
- **`[( ...]` の中でバッククォートのコード記法 `` `...` `` を使わない**（Scrapbox本体のパーサ制限。装飾記法とコード記法を同じ行に混ぜると `[(`/`]` がただの文字として表示されてしまい、装飾自体が成立しない。ネストしたリンクだけなら問題ない。実機DOM調査で確認済み、詳細は[chezmoi CI]ページ）
  - コードを見せたい時は地の文でそのまま書くか、コード部分は装飾行の下に行頭スペースを1段深くした**子行**として分離し、その行だけ`[(`を付けずバッククォートのまま書く（子行以外は下記の通り全部`[( ]`で包む。ブロック全体がAI由来なのは先頭行の`[claude code.icon]`でも示せている）
- 長い1行に詰め込まず、行頭スペースでの階層(ネスト)を徹底する。**子行を含めて1行ごとに`[( ]`で包む**（「ラベル: 説明文1。説明文2」のように1行に詰め込まない。ラベル単独の装飾行を親にし、説明文は1文ずつ子行(行頭スペース2個)にして、バッククォートを含まない行はその子行も`[( ]`で包む）
    ```
     [( 原因]
      [( [age暗号化]で秘密情報を管理する仕組み(PR #35)を入れた]
      CIランナー上にage鍵が存在しないため`chezmoi apply`が復号を試みて失敗する
    ```
    (最後の行はバッククォートを含むので`[( ]`を付けない。それ以外は子行も個別に`[( ]`で包む。`[( 原因: ...]`と1行に詰め込まない。実例は[chezmoi CI]ページ)
- 複数行ブロックは先頭行にだけ `[claude code.icon]`（Codexで動いているなら `[codex.icon]`）を付ける
- ページ/追記ブロックの冒頭に日付と指示の出所を残す:
  - `[2026/7/3]`
  - `>[tomixrm.icon]による指示: <指示の要約>`
- タスクは絵文字 ⬜ / ⏳ / ☑️ で表す（角括弧チェックボックスはリンク記法と衝突するので使わない）
- **積極的にリンクを張りにいく**。重要な単語・ドメインワード・テーマに近い語は、出てきたその場でブラケットリンクにする（リンク網の密度が n-hop 検索・ベクトル検索の効きを決める）
  - 例: MacBook の問題メモに USBC が出てきたら `[USBC]`。人物・案件・リポジトリ名・基板名・部品名・概念も同様
  - 迷ったらリンクにする。未作成ページへのリンクでも良い（将来の結節点になる）
- ページのテーマ/カテゴリには `#ハッシュタグ` も有効（ブラケットリンクと等価）。行末やページ末にまとめて付ける
  - ただし意図しないタグ化に注意: `#1` のような連番をシャープで書かない
- 機密（APIキー・トークン・第三者の個人情報の本文）は書かない

## 何をcaptureするか

- 設計判断とその理由（ADRに満たない粒度のもの）
- ハマった問題と解決（未来の自分が検索する前提で、症状の語彙を本文に入れる）
- セッションhandover（次セッションへの引き継ぎ。従来の `tmp/*.md` 手書きhandoverの代替）
- ユーザに「メモして」と言われたもの

ブラウザ側の一回きりセットアップ（薄表示CSS・承認UI・PAT発行）: references/browser-setup.md
