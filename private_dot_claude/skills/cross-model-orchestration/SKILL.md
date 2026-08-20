---
name: cross-model-orchestration
description: 難易度・重要度の高いコーディングタスクで、Claude と Codex(GPT) という異なるモデルファミリを掛け合わせ、クロスプランニングとクロスファミリ検証で多様性から精度を引き上げる手法。実行中の Claude が Conductor となり、**herdr の隣接 pane にいる Codex** をワーカーとして駆動し、独立生成→交差レビュー→統合→検証ループで実装を仕上げる。人間が全ワーカーの働きを pane で目視・介入できるのが要。ユーザが「複数モデルで」「codex も使って」「オーケストレーション」「クロスプランニング」「掛け合わせて精度を上げたい」等と求めたとき、または単一モデルで失敗/不安が残る重要タスクで使う。日常的に単一モデルで足りる軽量タスクや、コストに見合わない使い捨てには使わない。
---

# Cross-Model Orchestration

単一モデルの誤りは、同じモデルにレビューさせても見つからない（同じ盲点を共有する）。**異なるモデルファミリは互いに相関の弱い誤りをしやすい**（学習データ・ツール制約・同一プロンプト/文脈で完全に独立ではないが、盲点の重なりが小さい）ため、別ファミリに交差レビュー・交差検証させると、自分では気づけない欠陥が落ちやすい。多様性は精度を保証しないが期待値を上げる、というのが本 skill の前提。この「多様性で精度を上げる」効果を、学習済みコーディネータを作らずプロンプトオーケストレーションで再現するのが本 skill。実行中の Claude が **Conductor**（指揮者）となり、`codex` / `claude` をワーカーとして呼び分ける。

着想元の2論文（mechanism のみ蒸留。コーディネータの学習はしない）:
- **The Conductor** (arXiv:2512.04388) — 異プロバイダの複数 LLM を協調させる学習済み指揮者。動的トポロジ（誰が誰と通信するか）、適応的プロンプティング（各ワーカーの強みに合わせた指示）、再帰的トポロジ（自分自身をワーカーに選ぶ＝テスト時スケーリング）。
- **TRINITY** (arXiv:2512.04695) — 各ターンで異種 LLM に **Thinker / Worker / Verifier** の役割を割り当てる軽量コーディネータ。LiveCodeBench 86.2%。

## 既定トランスポートは herdr

**Codex は herdr の隣接 pane で動かし、`herdr agent prompt` で指示を差し込む。** `codex exec` を Bash から直接叩くと、人間から見えないところで Codex が走り、レビューも介入もできない。herdr 経由なら、人間は pane で Codex の思考と作業をリアルタイムに見られ、必要なら自分で割り込める。**Conductor が単独で完結するのではなく、人間を輪の中に残すのがこの skill の既定**。

判定は1行:

```bash
test "${HERDR_ENV:-}" = 1 && echo "herdr transport" || echo "fallback: codex exec"
```

`HERDR_ENV=1` なら herdr トランスポート（既定）。herdr の外で走っている場合だけ `codex exec` にフォールバックし、**その旨をユーザに明示する**（「人間が pane で見られない形で走らせます」）。

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
| `codex` | GPT | **herdr 隣接 pane**（`agent prompt`）／ `codex exec` はフォールバック | **高**（Conductor と別ファミリ） |
| `claude` | Claude | **ネイティブ SubAgent**（`Agent` ツール） | 低（Conductor と同ファミリ＝再帰/自己ワーカー） |

- Conductor 自身が Claude なので、**多様性の本体は codex ただ一つ**。claude ワーカーは「再帰的トポロジ（自己呼び出しによるテスト時スケーリング）」枠と捉える。以前あった GLM レグは廃止した（契約終了）。**プールが2ファミリしかない以上、codex を落とすと交差検証が成立しない**——codex が使えない状況は縮退ではなく中止に近いと扱い、ユーザに伝える。
- **claude レグはネイティブ SubAgent で出す**。SubAgent は前提知識ゼロで spawn されるのでブラインド＝フラットに判断でき、`claude -p` の権限/stdin の地雷を回避し、結果がツール結果で返る。役割→`subagent_type`: Thinker=`Plan`／Worker=`general-purpose`（worktree 指定）／Verifier=`Explore`（Edit/Write を持たない＝構造的に read-only だが Bash でテストは実行可）。詳細は adapters.md「Transport A」。
- ⚠️ **SubAgent を増やしても多様性は増えない**（同ファミリ）。安く生やせる分、Claude sub を量産して「クロスモデル」と錯覚しないこと。予算は codex を優先。spawn 時は Conductor の仮説を渡さず**タスク仕様だけ**渡してブラインド性を守る。
- 正確な呼び出しコマンド・出力捕捉・worktree・検証スキーマは `references/adapters.md` を読んでから dispatch する。最初に `SKILL` をこの skill ディレクトリに設定する: `SKILL="${SKILL:-$HOME/.claude/skills/cross-model-orchestration}"`。

役割（TRINITY 由来）。Conductor が各ターン、モデルの強みを見て割り当て、ファミリを**ローテ**して同一ファミリの偏りを避ける:
- **Thinker** — 独立に方針/設計を立てる（読み取り専用）
- **Worker** — 実装する（隔離 worktree 内で編集）
- **Verifier** — テスト実行 + 差分レビューで pass/fail と論点を返す。**実装したのと必ず別ファミリ**に担当させる（自己検証は禁止）。claude を検証者にするときは `Explore` SubAgent を使う（構造的に read-only）。worker サンドボックスがオフラインでテストコマンドを完走できることも事前に確認する。

## 4つの原則（なぜ効くか）

1. **異種性 > 同質性。** 同じ問いに別ファミリを当てると誤りの相関が下がる。codex を3回回すより codex+claude を1回ずつの方が盲点が埋まりやすい。
2. **Blind-first, then cross。** まず各モデルに**独立**に生成させ（互いの出力を見せない）、その後で相互に交差させる。最初から共有するとアンカリング/集団思考で多様性が潰れる。新規 spawn の SubAgent は会話文脈を一切持たない（プロンプトだけ）ので**構造的にブラインド**——この性質は資産。ワーカーには**タスク仕様だけ**を渡す。
3. **クロスファミリ検証（被検証者≠検証者ファミリ）。** ルールは「実装したモデルに自分の出力を検証させない」こと。pool={codex,claude} なので、claude 実装→codex 検証 / codex 実装→claude 検証の2通りしかない。**どちらも成立しなくなったら交差検証は不能**と明記し、Conductor の単独レビューに落とす（黙って自己検証に流れない）。
4. **Conductor は投票でなく統合。** 多数決で1案を選ぶのではなく、**1つの基盤案**（最良の差分）を選び、他案からは**個別にレビューした上で安全な改善だけ**を接ぎ木する。独立実装どうしのハンクを盲目的に合体させると不変条件が壊れるので、無差別な union は禁止。

## light モード — クロスプランニング + 統合

実装方針を固めたい、設計が分かれうるが実装自体は中規模、というとき。ファイル編集は最後だけ。

1. **フレーミング。** Conductor がタスクを1つの焦点化スペックにまとめ、各ワーカー向けに**強みを踏まえた個別プロンプト**を書く（`$RUN/prompt-{codex,claude}.txt`）。codex 向けは CMO エンベロープで包む。
2. **独立 plan（並列・ブラインド）。** codex は herdr pane へ `agent prompt --wait`、claude は `Plan` SubAgent を**同じターンで**並列に出す → codex は reply ファイル、SubAgent は最終メッセージがそのまま plan。互いの案は見せない。
3. **交差レビュー。** 各 plan を**別ファミリ**に渡し「この案の穴・見落とし・リスクを挙げよ」と批評させる。
4. **統合。** Conductor が全 plan + 全批評を読み、最強要素を接ぎ木した単一の実装計画を作る。割れた論点は理由付きで裁定。
5. **実装 + 軽い検証。** Conductor（または指名 Worker）が実装し、ビルド/テストを通す。割れていた箇所は別ファミリに1回クロスレビューさせる。

## deep モード — 役割ローテ + 検証ループ / トーナメント

一度失敗した、または失敗が高くつくタスク。**並列実装 → クロス検証 → 反復**。

1. **隔離 worktree を用意。** 各 Worker に detached `git worktree` を1つ（`references/adapters.md` のレシピ）。並列編集が衝突しない。
2. **並列実装（トーナメント）。** codex と claude を各自の worktree で**独立に**実装させる（編集は未コミットで残る）。dispatch はヘテロだが capture は均一: codex は herdr pane（`--cwd "$RUN/wt-codex"` で split した pane、または `agent prompt` の仕様に作業ディレクトリを明記）、claude レグは **`general-purpose` SubAgent を Conductor 作成の `$RUN/wt-claude` に向けて**実装させる（deep では Agent の `isolation:"worktree"` は使わない——パスがハーネス管理で codex 検証者が届かない）。
3. **クロスファミリ検証。** 各 worker の差分を patch に捕捉し（`git add -A` 後にビルド成果物を除外してから `git diff --staged`）、**被検証者と別ファミリ**の Verifier に渡す。Verifier は「ソースを書き換えず、差分をレビューしテストを実行」して JSON verdict（`pass` / `issues`）を返す。**claude 検証者は `Explore` SubAgent が最適**。codex 検証者にはエンベロープの `role=verifier` で verdict JSON をファイルに書かせる。
4. **裁定（投票でなく統合）。** 勝者 patch を**1つの基盤**として `git apply --3way` で本 repo に採用し、テストで確認。他案からは個別レビュー済みの改善だけを足す。**未コミットを branch merge しようとしない**——空ブランチで何も入らない（adapters.md の patch ベース採用を使う）。
5. **反復（再帰的テスト時スケーリング）。** 全 fail なら、verdict の `issues` を次ラウンドの焦点プロンプトに畳み込んでステップ2へ戻る。codex レグは同じ pane に続けて `agent prompt` すれば文脈が残る（完全にブラインドな再挑戦なら pane を作り直す）。claude レグは `SendMessage`（文脈保持）か新規 spawn（ブラインド）を使い分ける。**ラウンド上限**（既定2〜3）を最初に宣言し、未収束で打ち切ったら最良 patch + 残課題を正直に報告。
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

- **人間を締め出す。** `HERDR_ENV=1` なのに `codex exec` で回し、人間が pane で見られない状態を作る。既定は herdr 経由。
- **無印の差し込み。** エンベロープなしで他 pane に prompt を投げる。人間から見て誰の指示か分からず、受け手も規約を知らないので返路が壊れる。
- **pane 出力を直接読もうとする。** `agent read` は代替スクリーンを遡れない。**必ず reply ファイル**で受ける。
- **自己検証。** 実装したモデルに「これで正しいか」を聞く。同じ盲点を通す。必ず別ファミリへ。
- **早すぎる共有。** plan を出す前に他案を見せる → 全モデルが似た案に収束し多様性ゼロ。必ず blind-first。
- **投票で終了。** 多数決で1案を採用し残りを捨てる → 各案の良い部分を捨てている。統合せよ。
- **無限ループ。** Verifier が通らず延々回す。ラウンド上限を最初に決め、打ち切り時は最良差分 + 残課題を正直に報告。
- **repo 汚染 / pane 汚染。** `$RUN`（mktemp）と worktree に隔離し、最後に消す。作った pane も自分で片付ける。
- **空ブランチ merge / 採用前の cleanup。** worker の編集は未コミット。必ず patch に捕捉→ `git apply`→確認→ cleanup の順（adapters.md）。
- **claude sub の水増し。** SubAgent は同ファミリで多様性が増えない。codex を落として claude を3体出すのは交差検証ではない。
- **コスト無視の濫用。** 軽量タスクに deep を回す。スケール表に従う。

## 出典

- arXiv:2512.04388 *Learning to Orchestrate Agents in Natural Language with the Conductor*
- arXiv:2512.04695 *TRINITY: An Evolved LLM Coordinator*
