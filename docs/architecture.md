# コードの構成と拡張のしかた

ステージ・敵・ボス・地形・背景・モデルを増やしていくための設計メモ。
「何があるか」はデータ（登録表とステージ定義）に書き、「どう動くか」は種類ごとのスクリプトに書く。
登録表に足したものは、ゲーム本編と閲覧モード（VIEWER）の両方に自動で出てくる。

## フォルダ

| 場所 | 中身 |
|---|---|
| `scripts/game.gd` | 世界（カメラ・地形・ユニット・弾・エフェクト）とルール（スコア・当たり・残機・状態遷移）。ステージの中身は持たない |
| `scripts/stage/` | `stage_def.gd`（ステージ定義の基底）、`stage1.gd`（ステージ 1 の中身）、`stages.gd`（ステージの並び）、`stage.gd`（定義を実行する：ウェーブ・エリア・ボス戦）、`formations.gd`（編隊の雛形） |
| `scripts/enemies/` | `enemy.gd`（敵の共通部分）、種類ごとのスクリプト（`dart.gd` など）、`enemy_kinds.gd`（種類の登録表） |
| `scripts/bosses/` | `boss_base.gd`（中ボス・ボスの共通部分）、`lazaro.gd`、`star_cortex.gd`、`bosses.gd`（登録表） |
| `scripts/terrain/` | `terrain.gd`（地上の区画を流す）、`backdrop.gd`（星雲・惑星・星・深層の構造物）、`islandgen.gd`（区画の生成）、`island.gd`（区画とタイル） |
| `scripts/models/` | `models.gd`（共通の色と振り分け）、`ship_models.gd` / `enemy_models.gd` / `boss_models.gd` / `item_models.gd` / `ground_models.gd` |
| `scripts/viewer/` | 閲覧モード（`viewer.gd`）、一覧の組み立て（`viewer_catalog.gd`）、左の情報パネル（`viewer_panel.gd`） |
| `scripts/bot.gd` | 自動操縦（`--autoplay` と閲覧モードの B） |
| その他 `scripts/*.gd` | 自機・ショット・敵弾・アイテム・エフェクト・HUD・効果音・配色・入力・ボクセル |

## つながり

```
Stages ──> StageDef（stage1.gd …）
              ├─ areas  ──> Terrain（区画の並び・間隔） / Stage（エリア名表示・漂流物）
              ├─ backdrop ─> Backdrop（背景）
              ├─ waves  ──> Stage ──> Game.spawn_enemy(種類) ──> EnemyKinds ──> enemies/<種類>.gd
              │                  └──> Game.spawn_boss(種類)  ──> Bosses     ──> bosses/<名前>.gd
              └─ boss（ボスの種類）・スクロール速度・タイムボーナス・コンテナの間隔
見た目: Vox.get_mesh(名前) ──> Models ──> 各グループの make(名前)
```

## ステージを足す

1. `scripts/stage/stage2.gd` を作り、`extends StageDef` にする（`stage1.gd` を写して書き換えるのが早い）。
2. `_init()` で `title` / `subtitle` / `boss` / `areas` / `first_area` / `backdrop` などを決める。
   - `areas` はエリア名ごとに `label`（出だしの表示）、`sections`（区画の種類と大きさ）、`gap`（区画の間隔）、`stream`（漂流物、任意）。
   - `layout_seed` を変えると同じ指定でも区画の形が変わる。
3. `build_waves(f)` で `wave(エリア名, 出現リスト, 制限時間, 中ボスか)` を並べる。出現リストは `f.col(...) + f.vform(...)` のように `Formations` の雛形を足し合わせる。中ボスは `[[0.0, "lazaro", {}]]`。
4. `scripts/stage/stages.gd` の `LIST` に足す。ステージ 1 をクリアすると次へ進む（形態・シールド・エネルギー・スコアは持ち越し）。`--stage=2` で直接始められる。

## 敵の種類を足す

1. `scripts/enemies/<種類>.gd` を作り、`extends Enemy` にする。
   - `INFO`：`name`、`category`（`small` 小型 / `medium` 中型 / `ground` 地上 / `carrier` パワーアップ運搬 / `hazard` 漂流物）、`desc`、`demos`（閲覧モードでの見せ方：`[ラベル, Formations のメソッド名, 引数]`）。
   - `_init_kind()` で耐久・半径・スコア・エネルギー・爆発の大きさなど。モデル名が種類名と違うときは `mesh_name`。
   - `_behave(dt)` で動きと攻撃。出現時の指定は `p` に入っている。危険な攻撃の前は `game.warn` / `game.warn_then` で予兆を出す。
   - 画面の外で待ってから来る敵（後ろの `chaser`、横の `flanker`）の予兆は、レティクルが画面の縁に出る。1 列の編隊で狙い（自機の位置）と予兆を 1 つにまとめるときは、`Formations.chasers` のように列の全員に同じ辞書（`group`）を渡し、先頭が書いて後続が読む。
2. `scripts/enemies/enemy_kinds.gd` の `KINDS` に足す。
3. モデルを `scripts/models/enemy_models.gd` に足す（`NAMES` と `make`）。
4. 新しい編隊が要るなら `scripts/stage/formations.gd` に雛形を足す。
5. スコアを決めたら `docs/scoring.md` も更新する。

`category` が `medium` の敵は、ウェーブの「早回し（最後の 1 機は残っていても次へ）」の対象外になり、自動操縦は少し離れて戦う。

## 中ボス・ボスを足す

1. `scripts/bosses/<名前>.gd` を作り、`extends BossBase` にする。
   - `INFO`：`name`（警告と体力ゲージの名前）、`role`（`mid` / `boss`）、`desc`、`demos`（閲覧モードの途中から再生：`[ラベル, 合図]`、合図は `viewer_skip` に渡る）。
   - 部位は `game.spawn_part(self, モデル名, 半径)` で作る（当たり判定は敵と同じ）。部位への被弾は `on_hit`、部位の撃破は `on_part_killed` に来る。
   - `gauge()` で HUD の体力ゲージ、`force_defeat()` は閲覧モードの K（撃破）、`debug_state()` は閲覧モードの状態表示。
   - ステージのボス（`final`）は、倒れきったら `game.boss_destroyed(self)` を呼ぶとステージクリアになる。中ボスは去るときに `finished = true` にして `game.remove_boss(self)`。
2. `scripts/bosses/bosses.gd` の `KINDS` に足す。
3. モデルを `scripts/models/boss_models.gd` に足す。
4. ステージ定義の `boss`、または中ボスのウェーブに名前を書く。

## 地形（区画）を足す

- 既存の種類（hull / trench / solar / reactor / fragment / asteroid）の組み合わせと大きさは、ステージ定義の `areas[*].sections` だけで変えられる。
- 新しい種類は `scripts/terrain/islandgen.gd` に、外形（`make` の最初の match）・タイルの置き方（2 つ目の match）・表面（`_structure` か専用の関数）を足し、`KINDS` に加える。閲覧モードの TERRAIN に「KIND …」として標準サイズで出る。

## 背景を足す

ステージ定義の `backdrop` に `nebula` / `planet` / `stars` / `deep` を書く（どれも省略可。中身は `scripts/terrain/backdrop.gd` の冒頭）。ステージが変わると作り直される。色合いは配色（`palette.gd`、F2）が決める。

## モデルを足す

各グループのスクリプト（`scripts/models/*_models.gd`）の `NAMES` に名前を足し、`make()` で作る。`Vox.get_mesh(名前)` で使え、閲覧モードの MODELS に並ぶ。

## 閲覧モード（VIEWER）

タイトルで「VIEWER」を選ぶ（`--viewer` でも直接入れる。`--viewer=boss:1` のように分類と番号も指定できる）。
本編と同じ世界で動かすので、見た目も動きも本編どおり。自機はその場に止まった標的として置かれる（当たらない）。

| 分類 | 中身 |
|---|---|
| SHIP | 自機の 3 形態、並べた比較、形態ごとの武器（連射・スピア・ホーミング 8 発） |
| SMALL | 小型機の編隊（`INFO.demos` の数だけ） |
| MEDIUM | 中型機・コンテナ・小惑星・砲台 |
| BOSS | 中ボス・ボス（STAR CORTEX は第 2 段階からも） |
| WAVES | 各ステージの全ウェーブを、そのエリアの地形と砲台つきで。最後にボス |
| TERRAIN | エリアごとの地形の流れ、全区画を 1 つずつ静止で、IslandGen の全種類 |
| SCENERY | 背景だけ（通常速度と 4 倍速） |
| FX | 爆発の大きさ別、ラザロ・ボスの最期、自機の爆発、シールド、タイル破壊、火花、衝撃波、得点表示、弾のエネルギー化、予兆 |
| BULLETS | 敵弾の種類と形 |
| ITEMS | エネルギー・パワーアップ・スター |
| MODELS | すべてのボクセルモデル（回転台）と、組み上げた状態 |

対象は繰り返し再生される（編隊は全機いなくなるとまた来る、ボスは倒されるか去るとまた出る）。

| キー | 動作 |
|---|---|
| ← → / ↑ ↓ | 分類 / 項目 |
| Z / Space / Enter | 最初から再生 |
| Esc / P | 停止・再開（世界ごと止まる。カメラは動かせる） |
| F | 1 フレーム進める |
| 1〜5、- / = | 速さ（×0.1 / ×0.25 / ×0.5 / ×1 / ×2） |
| マウス左ドラッグ / 右ドラッグ / ホイール | 回り込み / 平行移動 / 寄り引き（Shift+矢印、PageUp/PageDown でも） |
| C | カメラを戻す |
| K | 対象を撃破（爆発や最期の演出を見る。地形ならタイルを全部壊す） |
| B | 自動操縦で戦わせる |
| Tab | 自機を自分で操縦（当たらない）。もう一度 Tab で一覧に戻る |
| E | 敵の攻撃あり・なし |
| G | 背後に地形を流す |
| V | 背景の表示・非表示 |
| T | 回転台の回転 |
| H | パネルを隠す |
| Q | タイトルへ |
| F2 | 配色の切り替え（本編と同じ） |

パッド：LB/RB 分類、十字キー 項目、A 再生、START 停止、X 1 フレーム、Y 操縦、右スティック 回り込み、LT/RT 寄り引き、R3 カメラを戻す、BACK タイトルへ。

`--viewer-tour=秒` はすべての項目を順に表示し、`--capture=フォルダ` があれば 1 項目 1 枚ずつ保存して終わる（全項目の確認用）。

## 動作確認

自動操縦のログは毎回同じになる（`--fixed-fps 60` で決定的）。構成を変えたときは、変更前後で次のログを比べると「遊びが変わっていない」ことを確かめられる。

```
Godot_console.exe --headless --path . --fixed-fps 60 -- --autoplay --god --log --capture-every=1 --quit-on-clear --mute
```

`fps=` の値だけは毎回変わるので除いて比べる。`--start=mid` / `--start=boss` / `--god` なしも合わせて見るとよい。
