class_name StageDef
extends RefCounted
## One stage as data. Each stage is a script in scripts/stage/ that extends
## this one, fills the fields in _init() and builds its waves in
## build_waves(); Stages lists the stages in play order. Stage runs the
## waves and the boss sequence, Terrain builds the ground sections of each
## area, Backdrop the scenery, and the viewer lists all of it.

## set by Stages.create (1 = first stage)
var number := 0
var title := "STAGE"
var subtitle := ""
## scroll speed (units/s) during the waves, and from the boss warning on
var scroll := Game.SCROLL
var boss_scroll := Game.BOSS_SCROLL
## difficulty: small fighters and turrets fire `zako_fire` times as often
## (2 from stage 3 on), and with `zako_early` those slow to open fire (the
## racers, the turrets) start sooner
var zako_fire := 1
var zako_early := false
## time bonus: bonus_rate points for every second the stage took under bonus_t
var bonus_t := 260.0
var bonus_rate := 1300
## a power-up carrier drifts in every carrier_every seconds (the first after
## carrier_first), except during the mid-boss; "" = none
var carrier := "container"
var carrier_every := 12.0
var carrier_first := 6.0
## the boss (a Bosses kind), the area flown over during the fight and the
## warning shown before it
var boss := ""
var boss_area := "boss"
var boss_warning := ["WARNING", ""]
var boss_warn_time := 5.5
## The areas of the stage, in order: name -> {
##   label     [title, subtitle] shown when the area begins (optional)
##   sections  [[kind, w, h, turrets], ...]  ground layouts (IslandGen kinds,
##             size in cells); a random one follows another
##             (a 5th entry anchors it in a tunnel: "wall", "span")
##   gap       [min, max] distance between sections
##   lead      how far the scroll runs before its first section (optional)
##   stream    {every, first, spawn: Callable(game)} things drifting in on
##             their own timer while the area lasts (optional)
## }
## Waves name the area they fly over.
var areas := {}
## the first area, and the one scrolling behind the title screen
var first_area := ""
var title_area := ""
## seed of the first section layout; each next one adds layout_seed_step
var layout_seed := 100
var layout_seed_step := 17
## the scenery (see Backdrop.build)
var backdrop := {}
## [{spawns: [[delay, kind, params], ...], timeout, mid, area}], see wave()
var waves: Array = []


## Builds `waves` with wave(); `f` has the formation helpers.
func build_waves(_f: Formations) -> void:
	pass


## Adds a wave over `area`. spawns = [[delay, kind, params], ...] where
## kind is an EnemyKinds or Bosses name. The next wave starts once this one
## is wiped out (or has left) or after `timeout` seconds. `mid` marks the
## mid-boss wave: no carriers, a CAUTION message.
func wave(area: String, spawns: Array, timeout := 7.0, mid := false) -> void:
	waves.append({"spawns": spawns, "timeout": timeout, "mid": mid, "area": area})


## Index of the mid-boss wave (or the wave count if there is none).
func mid_index() -> int:
	for i in waves.size():
		if waves[i].get("mid", false):
			return i
	return waves.size()


func area_label(a: String) -> Array:
	return (areas.get(a, {}) as Dictionary).get("label", [])
