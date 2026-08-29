---
name: cross-model-orchestration
description: 難易度・重要度の高いコーディングタスクで、Claude と Codex(GPT) という異なるモデルファミリを掛け合わせ、クロスプランニングとクロスファミリ検証で多様性から精度を引き上げる手法。実行中の Claude が Conductor となり、**herdr の隣接 pane にいる Codex / Claude** をワーカーとして駆動し、独立生成→交差レビュー→統合→検証ループで実装を仕上げる。全ワーカーが pane にいるので、人間がいつでも目視・割り込みできるのが要。ユーザが「複数モデルで」「codex も使って」「オーケストレーション」「クロスプランニング」「掛け合わせて精度を上げたい」等と求めたとき、または単一モデルで失敗/不安が残る重要タスクで使う。日常的に単一モデルで足りる軽量タスクや、コストに見合わない使い捨てには使わない。
---

# Cross-Model Orchestration

単一モデルの誤りは、同じモデルにレビューさせても見つからない（同じ盲点を共有する）。**異なるモデルファミリは互いに相関の弱い誤りをしやすい**（学習データ・ツール制約・同一プロンプト/文脈で完全に独立ではないが、盲点の重なりが小さい）ため、別ファミリに交差レビュー・交差検証させると、自分では気づけない欠陥が落ちやすい。多様性は精度を保証しないが期待値を上げる、というのが本 skill の前提。この「多様性で精度を上げる」効果を、学習済みコーディネータを作らずプロンプトオーケストレーションで再現するのが本 skill。実行中の Claude が **Conductor**（指揮者）となり、`codex` / `claude` をワーカーとして呼び分ける。

着想元の2論文（mechanism のみ蒸留。コーディネータの学習はしない）:
- **The Conductor** (arXiv:2512.04388) — 異プロバイダの複数 LLM を協調させる学習済み指揮者。動的トポロジ（誰が誰と通信するか）、適応的プロンプティング（各ワーカーの強みに合わせた指示）、再帰的トポロジ（自分自身をワーカーに選ぶ＝テスト時スケーリング）。
- **TRINITY** (arXiv:2512.04695) — 各ターンで異種 LLM に **Thinker / Worker / Verifier** の役割を割り当てる軽量コーディネータ。LiveCodeBench 86.2%。

## 既定トランスポートは herdr

**ワーカーは codex も claude も herdr の pane で動かし、`herdr agent prompt` で指示を差し込む。**
Bash から `codex exec` を叩いたり、SubAgent を spawn したりすると、人間から見えない
ところで作業が進み、レビューも介入もできない。herdr 経由なら人間は pane で各ワーカーの
思考と作業をリアルタイムに見られ、気に入らなければ自分で割り込める。
**Conductor が単独で完結するのではなく、人間を輪の中に残すのがこの skill の既定**。

judge は1行:

```bash
test "${HERDR_ENV:-}" = 1 && echo "herdr transport" || echo "fallback"
```

`HERDR_ENV=1` なら herdr（既定）。herdr の外にいる場合だけ `codex exec` と SubAgent に
フォールバックし、**その旨をユーザに明示する**（「人間が pane で見られない形で走らせます」）。

> herdr が入る前は claude レグを SubAgent で出していた。安くブラインドに生やせるのが
> 利点だったが、**人間から不可視**という致命的な欠点がある。pane なら同じブラインド性を
> 「新しい pane に新しい agent を立てて、タスク仕様だけ渡す」ことで満たせるので、
> 既定は pane に寄せた。SubAgent は「人間に見せる必要のない使い捨ての読み取り調査」
> など、可視性を捨ててよい場面に限る。

## ルーティング契約（ここを破ると誤配送する）

**pane やagent の指定は決定的に行う。LLM の記憶や画面の見た目に依存させない。**
誤った pane に指示を送っても *正常終了* してしまうため、事故が最も検出しにくい。

**識別子として使ってよいのは2つだけ。**

| 値 | 例 | 制御に使えるか |
|---|---|---|
| `pane_id` | `w6:p3` | **使う**。pane 操作の唯一の識別子 |
| agent name | `cmo-reviewer` | **使う**。agent 操作に限り有効 |
| pane label | `review-worker` | **使わない**（表示専用。実測で `pane read <label>` は失敗する） |
| agent kind | `claude` / `codex` | **使わない**（種類であって個体ではない） |
| terminal title | `Fix auth bug` | **使わない**（agent が動的に書き換える） |

**`--current` を他 agent の指定に使わない。** `--current` は「自分の pane の検出」ではなく、
実質 `$HERDR_PANE_ID` の読み出し。実測で、**偽の pane ID を環境変数に入れると検証せず
そのまま信用する**（herdrdev/herdr#2012）。環境変数が無い場合はエラーにならず
**UI のフォーカス pane に黙ってフォールバック**する。背景プロセスやネストした agent は
親の `HERDR_PANE_ID` を継承するので、loop の中では特に危ない。
Conductor 自身を指すときだけ使い、ワーカーの指定には必ず保存した ID を使う。

**手順は「作る → JSON から取る → 保存する → 使う前に照合する」。**

```bash
# 作る。ID は必ずレスポンスから取る（予測しない）
PANE="$(herdr pane split --current --direction right --cwd "$REPO" --no-focus \
        | python3 -c 'import json,sys;print(json.load(sys.stdin)["result"]["pane"]["pane_id"])')"
herdr agent start cmo-reviewer --kind codex --pane "$PANE"

# 人間向けに役割を label に出す（表示専用。制御には使わない）
herdr pane rename "$PANE" cmo-reviewer

# 保存する
python3 -c "import json;print(json.dumps({'reviewer':{'name':'cmo-reviewer','pane_id':'$PANE'}}))" > "$RUN/routes.json"

# 使う前に照合する。食い違ったら探しに行かず停止する
ACTUAL="$(herdr agent list | python3 -c '
import json,sys
for a in json.load(sys.stdin)["result"]["agents"]:
    if a.get("agent_name")=="cmo-reviewer": print(a["pane_id"]); break
')"
[ "$ACTUAL" = "$PANE" ] || { echo "routing mismatch: expected=$PANE actual=$ACTUAL" >&2; exit 1; }
```

不一致のときに「それっぽい pane」を探すのは禁止。**停止が正解**。誤配送して
正常終了する方がはるかに危険。

## agent が受け取れない2つの状態

どちらも `agent prompt` が **入力を送る前に** 弾く。握り潰さず、人間に見せる。

- **`agent_not_ready`** — `agent start` した直後、起動中に blocked になった状態。
  名前は `agent read` / `agent send-keys` には使えるので、**idle になるまで待ってから** prompt する。
- **`agent_blocked`** — 承認ダイアログや質問で止まっている。`agent read` で何を聞かれて
  いるか確認し、**勝手に答えず人間に判断を仰ぐ**。CMO の自動応答規約はここには適用しない。

`--wait` が `blocked` で返ってくるのも完了ではない。必ず `agent get` で状態を見る。

## CMO エンベロープ — 差し込みの明示と自動応答

herdr 経由で他 pane の agent に投げるプロンプトは、必ず**エンベロープで包む**。受け手はこれを見て「人間ではなく Conductor から来た CMO の依頼だ」と判別し、規約に従って自動的に応答する。エンベロープは**自己記述的**なので、受け手側に事前設定は要らない。

```
[CMO/herdr] from=claude@<pane> run=<runid> role=<thinker|worker|verifier> reply=<絶対パス>

<Conductor が書いた焦点化タスク仕様>

--- CMO 応答規約 ---
1. 最終回答は必ず reply= の絶対パスに書く（このpaneの出力は代替スクリーンで
   流れると Conductor から読めないため。ファイルが唯一の確実な返路）
2. 書き終えたら本文には "CMO-DONE <reply>" の1行だけ返す
3. 他ワーカーの案は意図的に渡していない。独立に判断すること
4. role=verifier のときは reply に verdict JSON のみを書く
   （スキーマ: references/verdict.schema.json）
5. 判断に迷ったら勝手に埋めず、reply に「不明点」として列挙する
```

3つの狙いがある。

- **明示**: 先頭の `[CMO/herdr]` で、人間が pane を見たとき「これは Claude が差し込んだ」と一目で分かる。`from=` に Conductor の pane ID が入るので出所も辿れる。
- **自動連携**: 受け手はエンベロープ自体を読めば規約が分かるので、`AGENTS.md` などの事前仕込みなしに噛み合う。トリガーは `[CMO/herdr]` の文字列。
- **確実な返路**: **`herdr agent read` は TUI の代替スクリーンを遡れない**（herdr 公式 skill も同じ制約を認め、ファイル経由を回避策として挙げている）。長い回答を取りこぼさないために、返答は最初からファイルに書かせる。

受け手側の検知を強化したいときだけ、`~/.codex/AGENTS.md` に「`[CMO/herdr]` で始まる入力は CMO 依頼として規約に従う」と1行足す。**必須ではない**（エンベロープだけで成立する）。

## ワーカープールと役割

| ワーカー | ファミリ | 呼び出し | 多様性への寄与 |
|---|---|---|---|
| `codex` | GPT | **herdr pane**（`agent start --kind codex` → `agent prompt`） | **高**（Conductor と別ファミリ） |
| `claude` | Claude | **herdr pane**（`agent start --kind claude`）／ SubAgent は可視性を捨ててよい時だけ | 低（Conductor と同ファミリ＝再帰/自己ワーカー） |

- Conductor 自身が Claude なので、**多様性の本体は codex ただ一つ**。claude ワーカーは
  「再帰的トポロジ（自己呼び出しによるテスト時スケーリング）」枠と捉える。以前あった
  GLM レグは廃止した（契約終了）。**プールが2ファミリしかない以上、codex を落とすと
  交差検証が成立しない**——codex が使えない状況は縮退ではなく中止に近いと扱い、ユーザに伝える。
- **claude レグも pane で出す。** 新しい pane に新しい agent を立て、Conductor の仮説を
  渡さず**タスク仕様だけ**渡せば、SubAgent と同じブラインド性が得られる。加えて人間が
  見られる。read-only を構造的に保証したい検証役では、`--kind claude` の pane に
  「差分をレビューしテストを実行するだけ。ソースは書き換えるな」と規約で縛る
  （SubAgent の `Explore` のようなツール剥奪はできないので、**規約 + 差分確認**で担保する）。
- ⚠️ **claude を増やしても多様性は増えない**（同ファミリ）。pane を3つ並べて
  「クロスモデル」と錯覚しないこと。予算は codex を優先する。
- pane を増やすほど人間の画面が狭くなる。**同時に立てるワーカーは2〜3が実用上限**。
  それ以上必要なら tab を分ける（`herdr tab create`）。
- 正確な呼び出しコマンド・出力捕捉・worktree・検証スキーマは `references/adapters.md` を
  読んでから dispatch する。最初に `SKILL` をこの skill ディレクトリに設定する:
  `SKILL="${SKILL:-$HOME/.claude/skills/cross-model-orchestration}"`。

役割（TRINITY 由来）。Conductor が各ターン、モデルの強みを見て割り当て、ファミリを**ローテ**して同一ファミリの偏りを避ける:
- **Thinker** — 独立に方針/設計を立てる（読み取り専用）
- **Worker** — 実装する（隔離 worktree 内で編集）
- **Verifier** — テスト実行 + 差分レビューで pass/fail と論点を返す。**実装したのと必ず別ファミリ**に担当させる（自己検証は禁止）。worker サンドボックスがオフラインでテストコマンドを完走できることも事前に確認する。

## 5つの原則（なぜ効くか）

0. **人間を輪に残す。** ワーカーは全員 pane にいて、人間がいつでも見て割り込める。
   速さのために可視性を捨てない。Conductor が裏で全部やってしまうと、間違った前提で
   走っていることに誰も気づけない。**pane に出す = レビュー可能にする**。
1. **異種性 > 同質性。** 同じ問いに別ファミリを当てると誤りの相関が下がる。codex を3回回すより codex+claude を1回ずつの方が盲点が埋まりやすい。
2. **Blind-first, then cross。** まず各モデルに**独立**に生成させ（互いの出力を見せない）、その後で相互に交差させる。最初から共有するとアンカリング/集団思考で多様性が潰れる。新しく立てた pane の agent は会話文脈を一切持たない（渡したプロンプトだけ）ので**構造的にブラインド**——この性質は資産。ワーカーには**タスク仕様だけ**を渡す。
3. **クロスファミリ検証（被検証者≠検証者ファミリ）。** ルールは「実装したモデルに自分の出力を検証させない」こと。pool={codex,claude} なので、claude 実装→codex 検証 / codex 実装→claude 検証の2通りしかない。**どちらも成立しなくなったら交差検証は不能**と明記し、Conductor の単独レビューに落とす（黙って自己検証に流れない）。
4. **Conductor は投票でなく統合。** 多数決で1案を選ぶのではなく、**1つの基盤案**（最良の差分）を選び、他案からは**個別にレビューした上で安全な改善だけ**を接ぎ木する。独立実装どうしのハンクを盲目的に合体させると不変条件が壊れるので、無差別な union は禁止。

## light モード — クロスプランニング + 統合

実装方針を固めたい、設計が分かれうるが実装自体は中規模、というとき。ファイル編集は最後だけ。

1. **pane を用意して routes.json に保存。** ワーカーぶんの pane を split し、`agent start` して、ルーティング契約どおり ID を保存する。label に役割名を出しておくと人間が追える。
2. **フレーミング。** Conductor がタスクを1つの焦点化スペックにまとめ、各ワーカー向けに**強みを踏まえた個別プロンプト**を書き（`$RUN/prompt-{codex,claude}.txt`）、CMO エンベロープで包む。
3. **独立 plan（並列・ブラインド）。** 各 pane へ `agent prompt --wait` を投げる。**投げる前に routes.json と `agent list` を照合**。互いの案は見せない。回答は reply ファイルで受ける。
4. **交差レビュー。** 各 plan を**別ファミリの pane**に渡し「この案の穴・見落とし・リスクを挙げよ」と批評させる。
5. **統合。** Conductor が全 plan + 全批評を読み、最強要素を接ぎ木した単一の実装計画を作る。割れた論点は理由付きで裁定。
6. **実装 + 軽い検証。** Conductor（または指名 Worker）が実装し、ビルド/テストを通す。割れていた箇所は別ファミリに1回クロスレビューさせる。
7. **後始末。** 自分が作った pane だけ閉じる。

## deep モード — 役割ローテ + 検証ループ / トーナメント

一度失敗した、または失敗が高くつくタスク。**並列実装 → クロス検証 → 反復**。

1. **隔離 worktree を用意。** 各 Worker に detached `git worktree` を1つ（`references/adapters.md` のレシピ）。並列編集が衝突しない。
2. **並列実装（トーナメント）。** 各ワーカーの pane を **`--cwd "$RUN/wt-<worker>"` で split** して、その worktree の中に立てる。こうすると dispatch も capture も均一になり、どのワーカーの差分も同じ `git -C "$RUN/wt-<worker>" diff` で取れる。編集は未コミットで残す。
3. **クロスファミリ検証。** 各 worker の差分を patch に捕捉し（`git add -A` 後にビルド成果物を除外してから `git diff --staged`）、**被検証者と別ファミリ**の Verifier pane に渡す。エンベロープの `role=verifier` で「ソースを書き換えず、差分をレビューしテストを実行し、verdict JSON だけを reply に書く」と縛る。pane の agent はツール剥奪ができないので、**read-only は規約で縛り、最後に worktree の差分が増えていないか確認して担保する**。
4. **裁定（投票でなく統合）。** 勝者 patch を**1つの基盤**として `git apply --3way` で本 repo に採用し、テストで確認。他案からは個別レビュー済みの改善だけを足す。**未コミットを branch merge しようとしない**——空ブランチで何も入らない（adapters.md の patch ベース採用を使う）。
5. **反復（再帰的テスト時スケーリング）。** 全 fail なら、verdict の `issues` を次ラウンドの焦点プロンプトに畳み込んでステップ2へ戻る。**同じ pane に続けて `agent prompt` すれば文脈が残り、pane を作り直せば完全にブラインドな再挑戦**になる。前回の試行を踏まえさせたいか、しがらみを断ちたいかで使い分ける。**ラウンド上限**（既定2〜3）を最初に宣言し、未収束で打ち切ったら最良 patch + 残課題を正直に報告。
6. **後始末。** patch 採用を確認した**後で** worktree を削除し（`worktree remove --force` + `worktree prune`）、`$RUN` を消す。順序を守らないと未コミットの成果を失う。**自分が作った pane だけ**閉じる（人間の pane や既存 agent は触らない）。

役割ローテの例: R1 = Thinker:codex / Worker:claude / Verifier:codex、R2 = 強みと R1 の結果で割り当て替え。

## 予算スケーリング（重要度に合わせる）

`empirical-prompt-tuning` と同じ思想で、重要度とコストに応じて規模を決める。

| 重要度 | モード | ワーカー | ラウンド |
|---|---|---|---|
| 中 | light | codex + claude | 1 |
| 高 | light→必要なら deep | codex + claude（役割ローテ） | 1〜2 |
| 最高/再失敗 | deep（トーナメント） | codex + claude + クロス検証 | 2〜3 |

着手前に「この規模を回す価値があるか」を一言で見積もり、過剰なら light に落とす。

## アンチパターン

- **人間を締め出す。** `HERDR_ENV=1` なのに `codex exec` や SubAgent で回し、人間が pane で見られない状態を作る。既定は herdr 経由。
- **label / title で pane を指す。** 表示用の値を識別子に使う。実測で `pane read <label>` は失敗する。制御は pane_id と agent name だけ。
- **`--current` でワーカーを指す。** 環境変数の読み出しでしかなく、偽の値も検証されない（#2012）。継承した古い ID で別 pane に誤配送し、しかも正常終了する。
- **不一致時に探しに行く。** routes.json と `agent list` が食い違ったら停止する。「それっぽい pane」への配送が一番危ない。
- **blocked を握り潰す。** `agent_blocked` は承認待ち。CMO 規約の自動応答を適用せず、人間に判断を仰ぐ。
- **無印の差し込み。** エンベロープなしで他 pane に prompt を投げる。人間から見て誰の指示か分からず、受け手も規約を知らないので返路が壊れる。
- **pane 出力を直接読もうとする。** `agent read` は代替スクリーンを遡れない。**必ず reply ファイル**で受ける。
- **自己検証。** 実装したモデルに「これで正しいか」を聞く。同じ盲点を通す。必ず別ファミリへ。
- **早すぎる共有。** plan を出す前に他案を見せる → 全モデルが似た案に収束し多様性ゼロ。必ず blind-first。
- **投票で終了。** 多数決で1案を採用し残りを捨てる → 各案の良い部分を捨てている。統合せよ。
- **無限ループ。** Verifier が通らず延々回す。ラウンド上限を最初に決め、打ち切り時は最良差分 + 残課題を正直に報告。
- **repo 汚染 / pane 汚染。** `$RUN`（mktemp）と worktree に隔離し、最後に消す。作った pane も自分で片付ける。
- **空ブランチ merge / 採用前の cleanup。** worker の編集は未コミット。必ず patch に捕捉→ `git apply`→確認→ cleanup の順（adapters.md）。
- **claude の水増し。** claude を何体並べても同ファミリで多様性は増えない。codex を落として claude を3体出すのは交差検証ではない。
- **コスト無視の濫用。** 軽量タスクに deep を回す。スケール表に従う。

## 出典

- arXiv:2512.04388 *Learning to Orchestrate Agents in Natural Language with the Conductor*
- arXiv:2512.04695 *TRINITY: An Evolved LLM Coordinator*
