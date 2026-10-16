class_name Terrain
extends Node3D
## The ground below the play plane: sections of the structures the stage
## flies over (Islands built by IslandGen), one random section after
## another from the current area's list. The layouts of a stage's areas are
## built once from its StageDef (`areas[*].sections`) and kept. The
## scenery further down is Backdrop.

var game: Game
var layouts := {}  # area -> Array[Dictionary] (IslandGen.make results)
var gaps := {}  # area -> [min, max]
var _stage_layouts := {}  # stage number -> {layouts, gaps}
var first_area := ""
var title_area := ""
var islands: Array[Island] = []
var spawning := false
var turrets := true
var area := ""
var next_in := 0.0
var rng := RandomNumberGenerator.new()
var last_layout := -1


## Switches to the areas of `def`, building their layouts the first time.
func use_stage(def: StageDef) -> void:
	if not _stage_layouts.has(def.number):
		var ls := {}
		var gs := {}
		var s := def.layout_seed
		for a: String in def.areas:
			var list: Array[Dictionary] = []
			for l: Array in def.areas[a].get("sections", []):
				list.append(IslandGen.make(s, l[0], l[1], l[2], l[3]))
				s += def.layout_seed_step
			ls[a] = list
			gs[a] = def.areas[a].get("gap", [2.0, 6.0])
		_stage_layouts[def.number] = {"layouts": ls, "gaps": gs}
	var e: Dictionary = _stage_layouts[def.number]
	layouts = e["layouts"]
	gaps = e["gaps"]
	first_area = def.first_area
	title_area = def.title_area


func reset(spawn: bool) -> void:
	clear()
	spawning = spawn
	turrets = spawn
	area = first_area if spawn else title_area
	next_in = 4.0
	rng.seed = 7


func clear() -> void:
	for isl in islands:
		for c in isl.get_children():
			if c is Enemy:
				game.remove_enemy(c as Enemy)
		isl.queue_free()
	islands.clear()


func set_area(a: String) -> void:
	if layouts.has(a):
		area = a


# ------------------------------------------------------------ tick

func tick(dt: float, speed: float) -> void:
	var i := 0
	while i < islands.size():
		var isl := islands[i]
		isl.position.z += speed * dt
		if isl.position.z - isl.h * Island.CELL * 0.5 > game.ground_bottom + 1.0:
			for c in isl.get_children():
				if c is Enemy:
					game.remove_enemy(c as Enemy)
			isl.queue_free()
			islands.remove_at(i)
			continue
		i += 1
	if spawning and layouts.has(area) and not (layouts[area] as Array).is_empty():
		next_in -= speed * dt
		if next_in <= 0.0:
			_spawn_island()


func _spawn_island() -> void:
	var list: Array[Dictionary] = layouts[area]
	var li := rng.randi_range(0, list.size() - 1)
	if list.size() > 1 and li == last_layout:
		li = (li + 1) % list.size()
	last_layout = li
	var lay := list[li]
	var hw := game.ground_hw
	var w: int = lay["w"]
	var h: int = lay["h"]
	var half := w * Island.CELL * 0.5
	var x := 0.0
	if half < hw:
		x = rng.randf_range(-hw + half * 0.6, hw - half * 0.6)
	else:
		x = rng.randf_range(-2.0, 2.0)
	place(lay, Vector3(x, Game.GROUND_Y, game.ground_top - h * Island.CELL * 0.5 - 2.0), turrets)
	var gap: Array = gaps[area]
	next_in = h * Island.CELL + rng.randf_range(gap[0], gap[1]) + IslandGen.MARGIN * IslandGen.R * 2.0


## Puts a section (an IslandGen layout) at `at`, with its turrets if asked.
func place(lay: Dictionary, at: Vector3, with_turrets: bool) -> Island:
	var isl := Island.new()
	add_child(isl)
	isl.setup(game, lay)
	isl.position = at
	islands.append(isl)
	if with_turrets:
		for c: Vector2i in lay["turrets"]:
			game.spawn_enemy("turret", {"island": isl, "cell": c})
	return isl


# ------------------------------------------------------------ hits

## A main shot at plane point p hits the tile under it: returns the damage
## left to carry on with (0 = the shot is spent), or -1 if no tile is there.
func hit(p: Vector3, dmg: float) -> float:
	if islands.is_empty():
		return -1.0
	var g := game.from_plane(p, Game.GROUND_Y + 0.4)
	for isl in islands:
		var idx := isl.tile_at(g)
		if idx >= 0:
			return isl.damage(idx, dmg)
	return -1.0


## Spear: damages tiles inside the aura circle and the lance rectangle.
func spear(pp: Vector3, r: float, hw: float, length: float, dmg: float) -> void:
	for isl in islands:
		if absf(isl.position.z - pp.z) > isl.h * Island.CELL * 0.5 + length + 4.0:
			continue
		for idx in isl.w * isl.h:
			if isl.types[idx] < 0:
				continue
			var q := isl.tile_plane_pos(idx)
			var d := q - pp
			if d.x * d.x + d.z * d.z < r * r or (absf(d.x) < hw and d.z < 0.0 and d.z > -length):
				isl.damage(idx, dmg)


func tiles_alive() -> int:
	var c := 0
	for isl in islands:
		c += isl.alive_tiles
	return c
