class_name Models
extends RefCounted
## Every voxel model in the game, built in code. Art direction: Star
## Soldier-style space opera. Model space: x right, y up, -z forward.
##   player   white hull, red stripes, blue canopy and fins (after Caesar)
##   enemies  polished gold and bronze armour over gunmetal, red eyes
##   ground   teal-grey fortress steel (see IslandGen)
## Ships are built from stacked, bevelled plates so the baked AO and the
## sun pick out panel edges; glow voxels mark engines, sensors and lights.
##
## The models live in one script per group (each extends this one, so the
## colours below are at hand): ShipModels, EnemyModels, BossModels,
## ItemModels, GroundModels. To add a model, add its name to the group's
## NAMES and build it in the group's make(); Vox.get_mesh(name) finds it
## and the viewer's MODELS list shows it.

# player
const WHITE := Color(0.9, 0.91, 0.94)
const LGREY := Color(0.64, 0.67, 0.72)
const DGREY := Color(0.27, 0.29, 0.33)
const RED := Color(0.86, 0.13, 0.12)
const BLUE := Color(0.14, 0.32, 0.82)
const NAVY := Color(0.08, 0.12, 0.28)
const CANOPY := Color(0.3, 0.78, 1.0)
const THRUST := Color(1.0, 0.6, 0.25)
const CYAN := Color(0.4, 0.95, 1.0)
# enemies
const GOLD := Color(0.72, 0.56, 0.27)
const GOLD_L := Color(0.84, 0.72, 0.46)
const BRONZE := Color(0.46, 0.33, 0.17)
const BROWN := Color(0.28, 0.19, 0.11)
const GUN := Color(0.33, 0.34, 0.38)
const GUN_D := Color(0.16, 0.16, 0.19)
const CRIM := Color(0.66, 0.1, 0.1)
const EYE := Color(1.0, 0.2, 0.14)
const AMBER := Color(1.0, 0.6, 0.18)
const MAGENTA := Color(1.0, 0.3, 0.6)
# kept for callers
const STEEL := GUN
const CRIMSON := CRIM
const PLUM := BRONZE
const GREEN := Color(0.35, 1.0, 0.5)
const YELLOW := Color(1.0, 0.85, 0.3)

const U := 0.09  # voxel size of small units


## [group label, script] in viewer order.
static func groups() -> Array:
	return [["SHIP", ShipModels], ["ENEMIES", EnemyModels], ["BOSSES", BossModels], ["ITEMS", ItemModels], ["GROUND", GroundModels]]


static func build(name: String) -> ArrayMesh:
	for g: Array in groups():
		if (g[1].NAMES as Array).has(name):
			return g[1].make(name)
	push_error("unknown model " + name)
	return ArrayMesh.new()
