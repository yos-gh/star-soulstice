# STAR SOULSTICE

Break everything. A 3D vertical shooter about tapping fast and spending energy.

[Download for Windows](https://github.com/yos-gh/star-soulstice/releases) — run the single executable.

Fly through five stages, from an orbital fortress down to the surface of a dead world.
Almost everything on screen can be destroyed: enemies, their bullets, and the armoured
tiles of the terrain below. Tap the shot button fast to power it up, collect the energy
that destroyed things leave behind, and release it as homing lasers with the Spear.

## Controls

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Move | Arrow keys / `WASD` | D-pad / left stick |
| Shot (tap fast to power up, hold for auto fire) | `Z` / `Space` / `.` | A / Cross |
| Spear + homing lasers | `X` / `Enter` / `/` | B / Circle |
| Pause | `Esc` / `P` | Start |
| Return to title from pause | `Q` | Back |
| Fullscreen | `F11` | — |
| Switch color palette | `F2` | — |

On the title screen, choose GAME START or VIEWER with up / down. On GAME START, left / right
picks the stage to start from.

## How to Play

- **Shot and Concentration** — Every press fires at once, and holding the button fires 12
  shots a second. Tapping fast builds Concentration: at 7.5 presses a second your shots reach
  ×8 power and burn white. Auto fire does not build it.
- **Forms** — Power-ups change the ship. Form I fires two shots forward. Form II fires faster,
  moves faster, and adds a rear shot. Form III fires a 3-way spread forward and 2-way behind,
  and carries a shield that takes one hit before dropping back to Form II.
- **Spear** — A short, powerful blade in front of the ship, with an aura that erases nearby
  bullets. It has a 4 second cooldown, and it also launches homing lasers from behind: one
  for every 10 energy, up to 8.
- **Energy** — Destroyed enemies, erased bullets, and broken tiles drop energy. Harder tiles
  drop more.
- **Enemy bullets** — Cool-colored physical bullets can be shot down, and they block your shots.
  Warm, white-centered energy bullets only disappear when the Spear erases them or their
  shooter is destroyed. Bosses also throw purple iron balls that nothing can stop.
- **Warnings** — Before a dangerous attack, a white lock-on reticle closes on the attacker and
  a short alarm sounds.

## Stages

Each stage has a mid-boss halfway through and a boss at the end. Breaking a boss's main
weapons drives it into a fiercer attack. Clearing a stage carries your form, shield, energy, and score into the next.

| Stage | Setting | Mid-boss | Boss |
| --- | --- | --- | --- |
| 1 | ORBITAL FORTRESS | LAZARO | STAR CORTEX |
| 2 | ARMS FOUNDRY | OUROBOROS | VULCAN PRESS |
| 3 | ASTEROID BELT | LODESTAR | TITAN DREDGE |
| 4 | PLANETFALL | TEMPEST | BEHEMOTH |
| 5 | DEAD WORLD | GORGON | OMEGA CORTEX, then STAR SOUL |

## Scoring

Destroying enemies and tiles and collecting items scores points, and each stage ends with a
time bonus for a fast clear. Stars hidden under tiles score ×1, ×2, ×4, then ×8 as you
collect more in a stage. Power-ups collected in Form III chain the same way across stages
until you lose a life. Extra lives are awarded at 200,000, 600,000, and 1,200,000 points.

## Viewer

Choose VIEWER on the title screen to look at the ship, every enemy and boss, each wave, the
terrain sections, backgrounds, effects, bullets, and models one at a time. They run in the
same world as the game, so they look and move exactly as they do in play. Press `Esc` to
freeze the world and orbit the camera, `F` to step one frame, and `1`–`5` to change speed.
The full key list is on the panel at the left of the screen.

## Run and build

Open `project.godot` in **Godot 4.7** and press **F5**. Models, terrain, and sound effects are
all generated in code, so the project has no asset files.

To build the Windows executable, install the matching export templates and run:

```powershell
Godot_console.exe --headless --path . --export-release "Windows Desktop" build/STAR-SOULSTICE.exe
```

The game is packaged as one executable. `build/` is ignored by Git.

Options for testing go after `--`:

```powershell
Godot_console.exe --path . --fixed-fps 60 -- --autoplay --god --stage=1 --start=6|mid|boss --log --quit-on-clear --mute
```

[Code structure and how to add content](docs/architecture.md) · [Score table](docs/scoring.md) (both in Japanese)

## Inspiration

STAR SOULSTICE is an original shooter inspired by Hudson's Star Soldier series.
