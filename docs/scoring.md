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
| 中ボス ラザロ（撃破ボーナス） | 20,000 | 240 | `scripts/bosses/lazaro.gd` `SCORE` / `HP` |
| ボスのポッド（4基） | 5,000 | 90 | `scripts/bosses/star_cortex.gd` `POD_SCORE` / `POD_HP` |
| ボス STAR CORTEX の目 | 50,000 | 800 | `scripts/bosses/star_cortex.gd` `EYE_SCORE` / `EYE_HP` |

撃破した敵の弾は消えてエネルギーになる（スコアはエネルギー取得分のみ）。

## 地上物・弾

| 対象 | スコア | 耐久 | 場所 |
|---|---:|---:|---|
| タイル（薄いハッチ） | 50 | 0.5 | `scripts/terrain/island.gd` `TILE_SCORE` / `TILE_HP` |
| タイル（十字ハッチ） | 150 | 1 | 〃 |
| タイル（防爆扉） | 400 | 1.5 | 〃 |
| 物理弾（撃ち落とし） | 10 | 1 | `scripts/game.gd` `_collide` |

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
| 中型機 | 14 | 〃 |
| ボスのポッド | 12 | `scripts/bosses/star_cortex.gd` |
| ラザロ撃破 | 40 | `scripts/bosses/lazaro.gd` |
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

| 破壊 | アイテム | タイムボーナス | クリアタイム |
|---:|---:|---:|---:|
| 約 42 万 | 約 42 万（うちスター 43 個で約 33 万、パワーアップ 6 個） | 約 17 万 | 約 127 秒 |
