# コードの構成と拡張のしかた

ステージ・敵・ボス・地形・背景・モデルを増やしていくための設計メモ。
「何があるか」はデータ（登録表とステージ定義）に書き、「どう動くか」は種類ごとのスクリプトに書く。
登録表に足したものは、ゲーム本編と閲覧モード（VIEWER）の両方に自動で出てくる。

## フォルダ

| 場所 | 中身 |
|---|---|
| `scripts/game.gd` | 世界（カメラ・地形・ユニット・弾・エフェクト）とルール（スコア・当たり・残機・状態遷移）。ステージの中身は持たない |
| `scripts/stage/` | `stage_def.gd`（ステージ定義の基底）、`stage1.gd` / `stage2.gd` / `stage3.gd`（各ステージの中身）、`stages.gd`（ステージの並び）、`stage.gd`（定義を実行する：ウェーブ・エリア・ボス戦）、`formations.gd`（編隊の雛形） |
| `scripts/enemies/` | `enemy.gd`（敵の共通部分）、種類ごとのスクリプト（`dart.gd` など）、`enemy_kinds.gd`（種類の登録表） |
| `scripts/bosses/` | `boss_base.gd`（中ボス・ボスの共通部分）、`lazaro.gd` / `star_cortex.gd`（ステージ 1）、`ouroboros.gd` / `vulcan_press.gd`（ステージ 2）、`lodestar.gd` / `titan_dredge.gd`（ステージ 3）、`bosses.gd`（登録表） |
| `scripts/terrain/` | `terrain.gd`（地上の区画を流す）、`backdrop.gd`（星雲・惑星・星・深層の構造物・トンネル）、`tunnel.gd`（トンネルの区間を流す）、`islandgen.gd`（区画の生成）、`island.gd`（区画とタイル） |
| `scripts/models/` | `models.gd`（共通の色と振り分け）、`ship_models.gd` / `enemy_models.gd` / `boss_models.gd` / `item_models.gd` / `ground_models.gd` / `tunnel_models.gd`（トンネルの区間） / `belt_models.gd`（ステージ 3 の巨大岩・敵・ボス・背景の岩） |
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
   - `scroll` / `boss_scroll` でスクロールの速さ（ステージ 2 は 18 / 10 と速い。ステージ 1 は 12 / 7、ステージ 3 は 15 / 8）。
   - `zako_fire` / `zako_early` で難しさ：小型機と砲台が `zako_fire` 倍の頻度で撃ち、`zako_early` なら撃ち始めの遅い敵（周回円盤・砲台）が早く撃ち始める（ステージ 3 から 2 / true。ステージ 1・2 は 1 / false）。ダートは 2 発目を 0.6 秒後に、円盤はループの半周先で、後方強襲機は続けてもう 1 発、周回円盤はループに乗るところでも、砲台は撃つ間隔が半分（どれも予兆つき）。敵のスクリプトは `game.zako_fire()` / `game.zako_early()` で読む。
   - 何度か目に 1 つ巨大岩を出すように、`stream` の `spawn` は `StageDef` のメソッドで書ける（`stage3.gd`）。最初に重いモデルを使う時に一瞬止まらないよう、`build_waves` で `Vox.get_mesh` を先に呼んでおける。
3. `build_waves(f)` で `wave(エリア名, 出現リスト, 制限時間, 中ボスか)` を並べる。出現リストは `f.col(...) + f.vform(...)` のように `Formations` の雛形を足し合わせる。中ボスは `[[0.0, "lazaro", {}]]`。
4. `scripts/stage/stages.gd` の `LIST` に足す。ステージをクリアすると次へ進む（形態・シールド・エネルギー・スコアは持ち越し）。タイトルの GAME START で ← → を押すと始めるステージを選べる（`--stage=2` でも直接始められる）。

## 敵の種類を足す

1. `scripts/enemies/<種類>.gd` を作り、`extends Enemy` にする。
   - `INFO`：`name`、`category`（`small` 小型 / `medium` 中型 / `ground` 地上 / `carrier` パワーアップ運搬 / `hazard` 漂流物）、`desc`、`demos`（閲覧モードでの見せ方：`[ラベル, Formations のメソッド名, 引数]`）、`stage`（任意：どのウェーブにも載らない種類（漂ってくる巨大岩など）を、閲覧モードでどのステージの背景の上に出すか）。
   - `_init_kind()` で耐久・半径・スコア・エネルギー・爆発の大きさなど。モデル名が種類名と違うときは `mesh_name`。
   - `_behave(dt)` で動きと攻撃。出現時の指定は `p` に入っている。危険な攻撃の前は `game.warn` / `game.warn_then` で予兆を出す。
   - 画面の外で待ってから来る敵（後ろの `chaser`、横の `flanker`）の予兆は、レティクルが画面の縁に出る。1 列の編隊で狙い（自機の位置）と予兆を 1 つにまとめるときは、`Formations.chasers` のように列の全員に同じ辞書（`group`）を渡し、先頭が書いて後続が読む。
   - 決まった道筋を列で飛ぶ編隊は、雛形で道筋（`Curve2D`、平面上の x と z）を作って全員に渡し、各機は先頭から一定の距離だけ後ろを飛ぶ（`Formations.racers` と `racer.gd`）。道筋は画面の割合で描いておき、反転・対角線での折り返しで 4 隅と 2 方向に使い回す。
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
   - 突進・打ち下ろしなどの大技は、`game.warn(部位, 秒, Game.Warn.MOVE, 半径, 狙う地点の Vector3)` で予兆を出すと、矢印がその地点へ流れ、自動操縦はその線から外れる（ボスの部位の予兆と、`marked` を立てた敵の予兆のみ）。弧を描く大技は、狙う地点の代わりに道筋の点の列（`PackedVector3Array`）を渡すと、矢印が道筋に沿って流れ、自動操縦は道筋全体から外れる（TITAN DREDGE の薙ぎ払い）。
   - 体力が尽きて最期の演出に入るときは `disarm()` を呼ぶ（全部位の当たり判定が消え、自機がぶつからず、弾も素通りする）。最後の大爆発は `game.big_blast(位置, 大きさ, 破片の色)`（1 = ボス、0.7 = 中ボス）。
   - ステージのボス（`final`）は、倒れきったら `game.boss_destroyed(self)` を呼ぶとステージクリアになる。中ボスは去るときに `finished = true` にして `game.remove_boss(self)`。
2. `scripts/bosses/bosses.gd` の `KINDS` に足す。
3. モデルを `scripts/models/boss_models.gd` に足す。
4. ステージ定義の `boss`、または中ボスのウェーブに名前を書く。

## 地形（区画）を足す

- 既存の種類（hull / trench / solar / reactor / fragment / asteroid / bridge / quarry）の組み合わせと大きさは、ステージ定義の `areas[*].sections` だけで変えられる。
- `bridge` はトンネルの壁から壁へ渡る足場（タイルの列と網目の通路、下はトラス）。幅 16 マスでトンネルの幅いっぱいになる。
- トンネルのあるステージでは、区画は壁の内側に置かれる。`sections` の 5 つ目に置き方を書ける：`"span"`（真ん中、壁から壁へ。`bridge` は書かなくてもこれ）、`"wall"`（左右どちらかの壁に寄せる）、なし（壁の内側のどこか）。例 `["hull", 6, 5, 2, "wall"]`。
- `quarry`（ステージ 3）は露天掘りの小惑星：真ん中へ段々に下がる採掘穴、底に鉱脈の光、穴のまわりの段にタイル（鉱石の箱）、穴を横切るコンベアの桟橋。
- 新しい種類は `scripts/terrain/islandgen.gd` に、外形（`make` の最初の match）・タイルの置き方（2 つ目の match）・表面（`_structure` か専用の関数）を足し、`KINDS` に加える。閲覧モードの TERRAIN に「KIND …」として標準サイズで出る。

## 背景を足す

ステージ定義の `backdrop` に `nebula` / `planet` / `stars` / `deep` / `rocks` / `tunnel` を書く（どれも省略可。中身は `scripts/terrain/backdrop.gd` の冒頭）。ステージが変わると作り直される。色合いは配色（`palette.gd`、F2）が決める。

### トンネル（ステージ 2）

`backdrop.tunnel = {styles: {エリア名: 様式}, first: 最初の様式, seed}` で、工場・基地の中のトンネルを近くに置く（床は y = −9、壁の上端は y = −1 で、プレイ面より下なので敵や弾を隠さない）。

- 中身は `scripts/terrain/tunnel.gd`：長さ 12 の区間（`TunnelModels` のモデル）を端から端へ並べて、スクロールと同じ速さで流す。1 つおきに仕切りのリブ、ときどき様式の目玉の区画（決まった種で並ぶので毎回同じ）。
- エリアが変わると、境目に防爆扉の枠（ゲート）が来て、その後ろから新しいエリアの様式になる（`Stage` が `Backdrop.set_area` を呼ぶ）。
- 様式は `scripts/models/tunnel_models.gd` の `STYLES`：`duct`（冷たい鋼・水色の灯・配管・床のファン）、`line`（ベルトコンベア・山形の通路・琥珀の灯・組立アーム）、`furnace`（暗い鉄板・溶けた鉄の溝・赤い熱の通気口・坩堝の穴）。新しい様式は `STYLES` と `NAMES`、`PALS` と様式の関数を足す。
- 区間の型は `plain` / `rib` / `feature` / `gate` の 4 つ。回る部品（ファン）は `props()` に書く。
- 背景の光は敵弾の色（橙のエネルギー弾・青の物理弾）とぶつからないよう、暗めに抑える。

### 小惑星帯（ステージ 3）

`backdrop.rocks = {y: [近い, 遠い], count, meshes, size: [最小, 最大], seed}` で、地上の区画と深層のあいだに小惑星帯の岩を浮かべる（近いものから遠いものへ高さを散らし、ゆっくり転がりながら流れる）。地上と同じ沈んだ材質で暗く作り、プレイ面の岩（当たる岩）と見分けがつくようにする。`deep` にも遠くの巨大な岩（`deep_rock_a` / `deep_rock_b`）を置いている。

### プレイ面の岩

- 漂う岩（`rock`）：体当たりあり、撃てば壊れる。ステージ 3 では上からに加えて、横の縁から画面の上半分をゆっくり斜めに横切るものも出る。
- 巨大岩（`giant_rock`、ステージ 3 の AREA 2 から）：`Enemy.solid` の壁。敵弾は種類を問わず中に入ると消える（`Game._solids`、`Bullets.cancel_in`：盾になる）。自機はぶつかっても壊れず押しのけられ（`Player.push_out`）、画面の端に押しつけられると端に沿って横へ抜け、隅で挟まれてもそのまま（潰されない）。ショットは吸うが硬い岩として壊せる（`lock = false` なのでホーミングは狙わない）。
- 岩塊（`boulder`）：歪んだ隕石の形（`meteor_a` / `meteor_b`）。GRAPPLER が爪で抱えて盾にし、投げつける岩（画面に入るとすぐ 1 つ目を投げる）。LODESTAR が回して盾にし投げる岩、TITAN DREDGE のベルトの岩も同じ形。TITAN DREDGE の投射機と岩崩れもこれを撃ち出す。体当たりあり、撃てば壊れる。

## モデルを足す

各グループのスクリプト（`scripts/models/*_models.gd`）の `NAMES` に名前を足し、`make()` で作る。`Vox.get_mesh(名前)` で使え、閲覧モードの MODELS に並ぶ。

## 閲覧モード（VIEWER）

タイトルで「VIEWER」を選ぶ（`--viewer` でも直接入れる。`--viewer=boss:1` のように分類と番号も指定できる）。
本編と同じ世界で動かすので、見た目も動きも本編どおり。自機はその場に止まった標的として置かれる（当たらない）。

| 分類 | 中身 |
|---|---|
| SHIP | 自機の 3 形態、並べた比較、形態ごとの武器（連射・スピア・ホーミング 8 発） |
| SMALL | 小型機の編隊（`INFO.demos` の数だけ） |
| MEDIUM | 中型機・コンテナ・小惑星・砲台（その敵が最初に出るステージの地形・背景の上で） |
| BOSS | 中ボス・ボス（STAR CORTEX は発狂から、OUROBOROS は突進から、VULCAN PRESS は暴走・発狂から、LODESTAR は暴走から、TITAN DREDGE は薙ぎ払いと発狂から、も。そのボスのステージの背景の上で） |
| WAVES | 各ステージの全ウェーブを、そのエリアの地形と砲台つきで。最後にボス |
| TERRAIN | エリアごとの地形の流れ、全区画を 1 つずつ静止で、IslandGen の全種類 |
| SCENERY | 背景だけ（ステージ 1 は通常速度と 4 倍速、トンネルのあるステージは様式ごとに本編の速さと 1/4 の速さ） |
| FX | 爆発の大きさ別、ラザロ・ボスの最期（画面いっぱいの大爆発 `Fx.finale`、`Game.big_blast`）、自機の爆発、シールド、タイル破壊、火花、衝撃波、得点表示、弾のエネルギー化、予兆 |
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

`--log` でステージをクリアすると、調整用に次の行も出る（これも毎回同じになる）。

- `TILES area=… in=… t=… per_s=…`：エリアごとに流れてきたタイルの数と、そのエリアが流れていた秒数、1 秒あたりのタイル数（タイルの密度。スターの数はこれと、硬いタイル（スターが隠れている率が高い）の割合で決まる。`Terrain.tally`）。最後の `TILES stage=…` がステージ全体。
- `DMG boss=… shot=…% spear=…% homing=…%`：中ボス・ボスの部位に入ったダメージの、武器ごとの割合（`Game.boss_dmg`）。

タイルの密度はエリアの `sections`（区画の大きさ）と `gap`（間隔）で決まる。スクロールが速いステージは、同じ間隔でも 1 秒あたりのタイルが増えるので、間隔を広げて合わせる。
