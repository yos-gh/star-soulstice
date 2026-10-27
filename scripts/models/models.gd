class_name Models
extends RefCounted
## Every voxel model in the game, built in code. Art direction: Star
## Soldier-style space opera. Model space: x right, y up, -z forward.
##   player   white hull, red stripes, blue canopy and fins (after Caesar)
##   enemies  each family in its own livery, warm, cool, black and white
##            spread across the cast (white-and-blue is the player's, so
##            enemies don't pair them), and no near-black bodies against the
##            black of space (mid grey at the darkest): crimson fighters, jade
##            drones, yellow-and-grey racers, a grey interceptor with pink and
##            red wings, sky-blue blades, gold mines, a blue carrier like its
##            power-up, a grey cruiser in gold; bosses after their concept (Lazaro
##            gold and bronze,
##            STAR CORTEX mechanical grey with a glowing eye after Star
##            Brain, OUROBOROS a jade train, VULCAN PRESS grey and
##            construction-machine orange round its molten core;
##            stage 3: an olive mining tug, LODESTAR copper on steel,
##            TITAN DREDGE mining yellow on steel, rocks in browns;
##            stage 4: the KESTREL gunship in sand on dark grey, TEMPEST
##            slate with brown glazed insulators and a lilac glow, BEHEMOTH
##            gunmetal with sand armour and a hazard-striped blade)
##   ground   teal-grey fortress steel (see IslandGen); its tiles are
##            coloured storehouses (GroundModels)
## Ships are built from stacked, bevelled plates so the baked AO and the
## sun pick out panel edges; glow voxels mark engines, sensors and lights.
##
## The models live in one script per group (each extends this one, so the
## colours below are at hand): ShipModels, EnemyModels, BossModels,
## ItemModels, GroundModels, TunnelModels, BeltModels, PlanetModels. To add a model, add its name to the group's
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
const PEARL := Color(0.82, 0.85, 0.9)
const PEARL_D := Color(0.56, 0.6, 0.68)
const COBALT := Color(0.16, 0.32, 0.74)
const COBALT_L := Color(0.36, 0.56, 0.92)
const COBALT_D := Color(0.08, 0.13, 0.34)
const JADE := Color(0.1, 0.54, 0.46)
const JADE_L := Color(0.32, 0.76, 0.62)
const JADE_D := Color(0.05, 0.25, 0.22)
const VIOLET := Color(0.42, 0.24, 0.68)
const VIOLET_L := Color(0.64, 0.48, 0.9)
const LAMP := Color(0.8, 0.95, 1.0)  # a cool white lamp (ground units: never orange)
const BLACK := Color(0.1, 0.1, 0.12)
const STEEL_L := Color(0.52, 0.55, 0.58)  # light machine grey
const STEEL_M := Color(0.4, 0.43, 0.46)
const ORANGE := Color(0.88, 0.42, 0.1)  # construction-machine paint (matte, not a glow)
const HAZARD := Color(0.86, 0.68, 0.16)  # hazard-stripe yellow
# dark greys for what was near-black on small enemies: between black and
# the machine greys, so they read against space without going pale (yos)
const DUSK_D := Color(0.22, 0.225, 0.26)
const DUSK := Color(0.26, 0.27, 0.3)
const DUSK_L := Color(0.31, 0.32, 0.35)
const SKY := Color(0.48, 0.7, 0.86)  # light blue (softer than cobalt)
const SKY_L := Color(0.74, 0.86, 0.94)
const PINK := Color(0.92, 0.4, 0.64)
# kept for callers
const STEEL := GUN
const CRIMSON := CRIM
const PLUM := BRONZE
const GREEN := Color(0.35, 1.0, 0.5)
const YELLOW := Color(1.0, 0.85, 0.3)

const U := 0.09  # voxel size of small units


## Main armour colour of a model: its wreckage when it blows up.
const BODY := {
	"dart": CRIM, "swirl": JADE, "racer": GOLD, "chaser": STEEL_L, "flanker": SKY, "rammer": GOLD,
	"container": COBALT, "turret_base": CRIM, "bulwark": GUN, "railjack": JADE,
	"rock_s": Color(0.33, 0.3, 0.27), "rock_l": Color(0.33, 0.3, 0.27),
	"lazaro_piece": GOLD, "boss_pod": STEEL_M, "boss_shutter": STEEL_L, "boss_eye": STEEL_M,
	"ouro_head": JADE, "ouro_car": JADE, "press_core": GUN, "press_plate": STEEL_L,
	"press_hammer": ORANGE, "press_vent": ORANGE,
	"giant_rock_a": Color(0.34, 0.31, 0.28), "giant_rock_b": Color(0.34, 0.31, 0.28), "grappler": Color(0.42, 0.45, 0.24),
	"lode_core": Color(0.7, 0.42, 0.24), "lode_pylon": Color(0.7, 0.42, 0.24), "dredge_core": GUN, "dredge_wheel": Color(0.84, 0.64, 0.14), "dredge_driver": Color(0.84, 0.64, 0.14), "meteor_a": Color(0.34, 0.31, 0.28), "meteor_b": Color(0.34, 0.31, 0.28),
	"kestrel": Color(0.52, 0.46, 0.33), "tempest_core": Color(0.3, 0.335, 0.37), "tempest_coil": Color(0.44, 0.27, 0.17), "behemoth_turret": Color(0.33, 0.34, 0.38), "behemoth_sponson": Color(0.52, 0.46, 0.33), "behemoth_louvre": Color(0.4, 0.43, 0.46), "behemoth_core": Color(0.33, 0.34, 0.38),
	"blast_door": GUN, "bulkhead": Color(0.3, 0.335, 0.37),
}


static func body_col(name: String, fallback: Color) -> Color:
	return BODY.get(name, fallback)


## [group label, script] in viewer order.
static func groups() -> Array:
	return [["SHIP", ShipModels], ["ENEMIES", EnemyModels], ["BOSSES", BossModels], ["ITEMS", ItemModels], ["GROUND", GroundModels], ["TUNNEL", TunnelModels], ["BELT", BeltModels], ["PLANET", PlanetModels], ["SURFACE", SurfaceModels]]


static func build(name: String) -> ArrayMesh:
	for g: Array in groups():
		if (g[1].NAMES as Array).has(name):
			return g[1].make(name)
	push_error("unknown model " + name)
	return ArrayMesh.new()
