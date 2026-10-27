# スコア一覧（基本値）

スコア調整用の一覧。値を変えたら、このファイルとコードの両方を更新すること。
「場所」はその値が定義されているファイルと定数・行。

## 敵の撃破

| 対象 | スコア | 耐久 | 場所 |
|---|---:|---:|---|
| 編隊機（dart） | 100 | 1 | `scripts/enemies/dart.gd` `_init_kind` |
| 円盤（swirl） | 200 | 2 | `scripts/enemies/swirl.gd` 〃 |
| 突進機雷（rammer） | 300 | 3 | `scripts/enemies/rammer.gd` 〃 |
| 後方強襲機（chaser） | 200 | 1 | `scripts/enemies/chaser.gd` 〃 |
| 側面強襲機（flanker） | 200 | 1 | `scripts/enemies/flanker.gd` 〃 |
| 周回円盤（racer） | 150 | 1 | `scripts/enemies/racer.gd` 〃 |
| 砲台（turret） | 400 | 5 | `scripts/enemies/turret.gd` 〃 |
| 小惑星・小（rock） | 150 | 3 | `scripts/enemies/rock.gd` 〃 |
| 小惑星・大（rock big） | 500 | 8 | 〃 |
| コンテナ（container） | 1,000 | 14 | `scripts/enemies/container.gd` 〃 |
| 中型機（bulwark） | 3,000 | 120 | `scripts/enemies/bulwark.gd` 〃 |
| 中型機（railjack、ステージ 2） | 2,500 | 100 | `scripts/enemies/railjack.gd` 〃 |
| 中ボス ラザロ（撃破ボーナス） | 20,000 | 240 | `scripts/bosses/lazaro.gd` `SCORE` / `HP` |
| ボスのポッド（4基） | 5,000 | 90 | `scripts/bosses/star_cortex.gd` `POD_SCORE` / `POD_HP` |
| ボス STAR CORTEX のシャッター（2 枚） | 5,000 | 220 | `scripts/bosses/star_cortex.gd` `SHUTTER_SCORE` / `SHUTTER_HP` |
| ボス STAR CORTEX の目 | 50,000 | 1,000 | `scripts/bosses/star_cortex.gd` `EYE_SCORE` / `EYE_HP` |
| 中ボス OUROBOROS の車両（8 両） | 1,500 | 30 | `scripts/bosses/ouroboros.gd` `CAR_SCORE` / `CAR_HP` |
| 中ボス OUROBOROS の頭（撃破） | 25,000 | 560 | `scripts/bosses/ouroboros.gd` `SCORE` / `HEAD_HP` |
| ボス VULCAN PRESS の砲塔（2 基） | 3,000 | 70 | `scripts/bosses/vulcan_press.gd` `VENT_SCORE` / `VENT_HP` |
| ボス VULCAN PRESS の装甲板（3 枚） | 2,500 | 160 | `scripts/bosses/vulcan_press.gd` `PLATE_SCORE` / `PLATE_HP` |
| ボス VULCAN PRESS のハンマー（2 基） | 8,000 | 560 | `scripts/bosses/vulcan_press.gd` `HAMMER_SCORE` / `HAMMER_HP` |
| ボス VULCAN PRESS の核 | 60,000 | 1,400 | `scripts/bosses/vulcan_press.gd` `CORE_SCORE` / `CORE_HP` |
| 中型機（grappler、ステージ 3） | 2,500 | 110 | `scripts/enemies/grappler.gd` `_init_kind` |
| 岩塊（boulder：GRAPPLER が投げる・TITAN DREDGE が撃ち出す） | 300 | 30 | `scripts/enemies/boulder.gd` 〃 |
| 巨大岩（giant rock、ステージ 3） | 3,000 | 300 | `scripts/enemies/giant_rock.gd` 〃 |
| 巨大岩・大 | 5,000 | 450 | 〃 |
| 中ボス LODESTAR の岩塊（6 個、引き寄せて補充） | 300 | 24 | `scripts/bosses/lodestar.gd` `ROCK_SCORE` / `ROCK_HP` |
| 中ボス LODESTAR の磁石の柱（3 本） | 3,000 | 150 | `scripts/bosses/lodestar.gd` `PYLON_SCORE` / `PYLON_HP` |
| 中ボス LODESTAR の核（撃破） | 25,000 | 620 | `scripts/bosses/lodestar.gd` `SCORE` / `CORE_HP` |
| ボス TITAN DREDGE の鉱石トロッコ | なし | 壊せない（装甲：ショットを弾く） | `scripts/bosses/titan_dredge.gd` `_add_skip` |
| ボス TITAN DREDGE のカッターホイール（2 基） | 8,000 | 360 | `scripts/bosses/titan_dredge.gd` `WHEEL_SCORE` / `WHEEL_HP` |
| ボス TITAN DREDGE の核 | 60,000 | 1,200 | `scripts/bosses/titan_dredge.gd` `CORE_SCORE` / `CORE_HP` |
| 中型機（kestrel、ステージ 4） | 2,500 | 120 | `scripts/enemies/kestrel.gd` `_init_kind` |
| 大型の中型機（halberd、ステージ 5） | 6,000 | 260 | `scripts/enemies/halberd.gd` `_init_kind` |
| 基地の扉（blast door、ステージ 4：壊さないとぶつかってミス） | 3,000 | 60（スピア 1 発ほど） | `scripts/enemies/blast_door.gd` `_init_kind` |
| 隔壁（bulkhead、ステージ 4：同じく） | 1,500 | 30（スピア半分ほど） | `scripts/enemies/bulkhead.gd` 〃 |
| 中ボス TEMPEST の避雷塔（3 本） | 3,000 | 120 | `scripts/bosses/tempest.gd` `COIL_SCORE` / `COIL_HP` |
| 中ボス TEMPEST の嵐の発生機（撃破） | 25,000 | 470 | `scripts/bosses/tempest.gd` `SCORE` / `CORE_HP` |
| ボス BEHEMOTH の副砲（2 基） | 4,000 | 180 | `scripts/bosses/behemoth.gd` `SPONSON_SCORE` / `SPONSON_HP` |
| ボス BEHEMOTH の主砲塔（反応炉を封じている） | 10,000 | 520 | `scripts/bosses/behemoth.gd` `TURRET_SCORE` / `TURRET_HP` |
| ボス BEHEMOTH の反応炉（主砲塔を壊すか OVERRUN で撃てる） | 60,000 | 540 | `scripts/bosses/behemoth.gd` `CORE_SCORE` / `CORE_HP` |
| 中ボス GORGON のトーチカの砲台（8 基、せり上がっている間だけ撃てる） | 2,000 | 36 | `scripts/bosses/gorgon.gd` `GUN_SCORE` / `GUN_HP` |
| 中ボス GORGON の中央砲台（鉄球弾を撃つ。壊すと鉄球が止まる） | 8,000 | 420 | `scripts/bosses/gorgon.gd` `CANNON_SCORE` / `CANNON_HP` |
| 中ボス GORGON の目（2 つ、それぞれ別の耐久） | 10,000 | 620 | `scripts/bosses/gorgon.gd` `EYE_SCORE` / `EYE_HP` |
| 中ボス GORGON の撃破（両目を壊す） | 20,000 | | `scripts/bosses/gorgon.gd` `SCORE` |
| 中ボス GORGON の TWIN BREAK（2 つ目の目を 1 つ目から 1.5 秒以内に壊す） | 50,000 | | `scripts/bosses/gorgon.gd` `TWIN_BONUS` / `TWIN_WINDOW` |

撃破した敵の弾は消えてエネルギーになる（スコアはエネルギー取得分のみ）。

## 地上物・弾

| 対象 | スコア | 耐久 | 場所 |
|---|---:|---:|---|
| タイル（緑のコンテナ） | 50 | 0.5 | `scripts/terrain/island.gd` `TILE_SCORE` / `TILE_HP` |
| タイル（青灰色のタンク） | 150 | 1 | 〃 |
| タイル（紫の屋根の倉庫） | 400 | 1.5 | 〃 |
| 物理弾（撃ち落とし） | 10 | 1 | `scripts/game.gd` `_collide` |
| 鉄球弾（ボスの IRON 弾） | なし | 撃ち落とせない（ショットを遮る。スピアでも消えない） | `scripts/bullets.gd` |

## アイテム

| 対象 | スコア | 倍率 | 場所 |
|---|---:|---|---|
| エネルギー | 1 単位につき 2 | なし | `scripts/game.gd` `ENERGY_SCORE` |
| パワーアップ（初期・第1形態で取得） | 1,000 | なし | `POWER_UP_SCORE` |
| パワーアップ（第2形態で取得） | 5,000 | ×1 → ×2 → ×4 → ×8（上限）。ステージをまたいで持ち越し、ミスで ×1 に戻る | `POWER_SCORE` / `power_mul` |
| スター（タイルの下に隠れている） | 1,000 | ×1 → ×2 → ×4 → ×8（上限）。ステージごとに ×1 に戻る | `STAR_SCORE` / `star_mul` |

倍率の上限は `CHAIN_MAX`（8）。

エネルギー 1 単位で得られるホーミング用エネルギーは `ENERGY_GAIN`（0.5）。
ホーミング 1 発 = エネルギー 10（`scripts/player.gd` `ENERGY_PER_HOMING`）。

エネルギーの出る量：

| 発生元 | 量 | 場所 |
|---|---:|---|
| 編隊機 / 円盤 / 突進機雷 / 後方強襲機 / 側面強襲機 / 周回機 | 2 / 3 / 3 / 2 / 2 / 2 | `scripts/enemies/<種類>.gd` `energy_drop` |
| 砲台 / コンテナ | 4 / 4 | 〃 |
| 小惑星 小 / 大 | 3 / 8 | 〃 |
| 中型機 bulwark / railjack / grappler / kestrel / halberd | 14 / 12 / 12 / 12 / 20 | 〃 |
| 基地の扉 / 隔壁 | 10 / 6 | `scripts/enemies/blast_door.gd` `bulkhead.gd` |
| 岩塊 / 巨大岩 / 巨大岩・大 | 4 / 16 / 24 | 〃 |
| ボスのポッド / シャッター | 12 / 10 | `scripts/bosses/star_cortex.gd` |
| ラザロ撃破 | 40 | `scripts/bosses/lazaro.gd` |
| OUROBOROS 車両 / 頭 / 最期 | 6 / 30 / 24 ＋車両ごとに 4 | `scripts/bosses/ouroboros.gd` |
| VULCAN PRESS 砲塔 / ハンマー / 装甲板 | 8 / 14 / 6 | `scripts/bosses/vulcan_press.gd` |
| LODESTAR 岩塊 / 柱 / 核 / 最期 | 3 / 10 / 30 / 24 ＋岩塊ごとに 3 | `scripts/bosses/lodestar.gd` |
| TITAN DREDGE ホイール | 14 | `scripts/bosses/titan_dredge.gd` |
| TEMPEST 避雷塔 / 発生機 / 最期 | 10 / 30 / 24 | `scripts/bosses/tempest.gd` |
| BEHEMOTH 副砲 / 主砲塔 | 10 / 16 | `scripts/bosses/behemoth.gd` |
| GORGON トーチカの砲台 / 中央砲台 / 目 / 最期 | 5 / 14 / 20 / 30 | `scripts/bosses/gorgon.gd` |
| タイル コンテナ / タンク / 倉庫 | 2 / 5 / 10 | `scripts/terrain/island.gd` `TILE_ENERGY` |
| 消した弾（撃破・スピア） | 1 発につき 1 | `scripts/game.gd` |

## クリアボーナス

| 項目 | 値 | 場所 |
|---|---|---|
| タイムボーナス | (260 秒 − クリアタイム) × 1,300（100 点単位、負なら 0） | ステージごと：`scripts/stage/stage_def.gd` `bonus_t` / `bonus_rate`（各ステージの `stageN.gd` で上書きできる） |

## エクステンド

| 到達スコア | 場所 |
|---|---|
| 200,000 / 600,000 / 1,200,000 | `scripts/game.gd` `EXTENDS` |

## 参考：自動操縦（無敵）での配分

ショット・スピアだけで取れる配分の目安。人が稼ぐと変わる。

| ステージ | 破壊 | アイテム | タイムボーナス | クリアタイム |
|---|---:|---:|---:|---:|
| 1 | 約 41 万 | 約 38 万（うちスター 39 個、パワーアップ 6 個） | 約 18 万 | 約 118 秒 |
| 2（ステージ 1 から続けて） | 約 41 万 | 約 64 万（うちスター 51 個） | 約 18 万 | 約 125 秒 |
| 2（ステージ 2 から始めて、第 1 形態から） | 約 39 万 | 約 51 万（うちスター 55 個） | 約 18 万 | 約 119 秒 |
| 3（ステージ 2 から続けて） | 約 49 万 | 約 54 万（うちスター 38 個） | 約 18 万 | 約 118 秒 |
| 3（ステージ 3 から始めて、第 1 形態から） | 約 47 万 | 約 42 万（うちスター 44 個） | 約 18 万 | 約 120 秒 |
| 4（ステージ 3 から続けて） | 約 46 万 | 約 72 万（うちスター 50 個） | 約 12 万 | 約 169 秒（ボス戦が長引いた回。ボス戦は 40〜60 秒とぶれる） |
| 4（ステージ 4 から始めて、第 1 形態から） | 約 47 万 | 約 64 万（うちスター 61 個） | 約 13 万 | 約 157 秒 |
| 5（ステージ 5 から始めて、第 1 形態から。中ボスまで） | 約 46 万 | 約 44 万（うちスター 41 個） | 約 20 万 | 約 108 秒（中ボスの撃破でクリア）|

自動操縦はほぼ秒間 7.5 回連打するので、ショットはおおむね ×8（最大）。

## タイルの密度（1 秒あたりに流れてくるタイルの数）

スターの数の目安。`--log` でクリアすると `TILES` の行に出る。値は上の自動操縦（ステージ 1 から続けて）のもの。

| ステージ | 全体 | エリアごと |
|---|---:|---|
| 1 | 18.6 | DEBRIS 10.5、HULL 30.5、（ラザロ）13.0、CORE 28.1、ボス戦 9.6 |
| 2 | 13.9 | INTAKE DUCT 14.9、ASSEMBLY LINE 19.2、（OUROBOROS）14.1、FURNACE ROW 17.3、ボス戦 8.1 |
| 3 | 13.9 | DRIFT FIELD 15.7、QUARRY ROCKS 17.6、（LODESTAR）10.3、CRUSH ZONE 16.5、ボス戦 6.9（ステージ 3 から始めた値） |
| 4 | 11.7 | UPPER ATMOSPHERE 15.1、STORM LAYER 13.8、（TEMPEST）15.3、HANGAR SHAFT 13.2、CORE ACCESS 16.9、ボス戦 3.4（壁際の貨物）（ステージ 4 から始めた値） |
| 5 | 17.8 | EXIT SHAFT 23.6（6 秒だけ）、CRATER PLAINS 17.6、RED RIFT 17.1（ステージ 5 から始めた値。GORGON のクレーターは区画なし） |

ステージ 2 はスクロールが 1.5 倍なので、区画の間隔（`stage2.gd` の `gap`）を広げて密度を下げている。区画に硬いタイル（倉庫：スターが隠れている率 6%、ほかは 2%）が多いので、密度が同じならスターはステージ 1 より多めに出る。

ステージ 3 はスクロールが 1.25 倍（15）。小惑星（`asteroid`）と露天掘りの小惑星（`quarry`）の区画が主で、タイルの割合が低めなので、区画を大きめ・間隔を狭めにしている。

ステージ 4 はスクロールが 16。前半の空の区画（浮遊プラットフォーム `aerostat`）は大きくタイルが多いので、間隔を広めにしている。敵が多いぶん、密度はステージ 3 より少しだけ高い。ボス戦は闘技場の床が区画の高さまで上がっているので、区画の代わりに壁際に貨物（`cargo`）が流れてくる（ホーミングのエネルギーの補給。戦車が轢くと潰れる）。基地の中は扉と隔壁が来る間は区画を出さないので、HANGAR SHAFT の密度が少し下がった。扉と隔壁が来てもスクロールは落ちない（自動操縦は来たところをすぐ壊す：扉は門ごと来るまで含めて約 3 秒、隔壁は約 1 秒）。
