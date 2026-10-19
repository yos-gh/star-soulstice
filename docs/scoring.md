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

撃破した敵の弾は消えてエネルギーになる（スコアはエネルギー取得分のみ）。

## 地上物・弾

| 対象 | スコア | 耐久 | 場所 |
|---|---:|---:|---|
| タイル（薄いハッチ） | 50 | 0.5 | `scripts/terrain/island.gd` `TILE_SCORE` / `TILE_HP` |
| タイル（十字ハッチ） | 150 | 1 | 〃 |
| タイル（防爆扉） | 400 | 1.5 | 〃 |
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
| 中型機 bulwark / railjack | 14 / 12 | 〃 |
| ボスのポッド / シャッター | 12 / 10 | `scripts/bosses/star_cortex.gd` |
| ラザロ撃破 | 40 | `scripts/bosses/lazaro.gd` |
| OUROBOROS 車両 / 頭 / 最期 | 6 / 30 / 24 ＋車両ごとに 4 | `scripts/bosses/ouroboros.gd` |
| VULCAN PRESS 砲塔 / ハンマー / 装甲板 | 8 / 14 / 6 | `scripts/bosses/vulcan_press.gd` |
| タイル 薄 / 十字 / 防爆扉 | 2 / 5 / 10 | `scripts/terrain/island.gd` `TILE_ENERGY` |
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

自動操縦はほぼ秒間 7.5 回連打するので、ショットはおおむね ×8（最大）。

## タイルの密度（1 秒あたりに流れてくるタイルの数）

スターの数の目安。`--log` でクリアすると `TILES` の行に出る。値は上の自動操縦（ステージ 1 から続けて）のもの。

| ステージ | 全体 | エリアごと |
|---|---:|---|
| 1 | 18.6 | DEBRIS 10.5、HULL 30.5、（ラザロ）13.0、CORE 28.1、ボス戦 9.6 |
| 2 | 13.9 | INTAKE DUCT 14.9、ASSEMBLY LINE 19.2、（OUROBOROS）14.1、FURNACE ROW 17.3、ボス戦 8.1 |

ステージ 2 はスクロールが 1.5 倍なので、区画の間隔（`stage2.gd` の `gap`）を広げて密度を下げている。区画に硬いタイル（防爆扉：スターが隠れている率 6%、ほかは 2%）が多いので、密度が同じならスターはステージ 1 より多めに出る。
