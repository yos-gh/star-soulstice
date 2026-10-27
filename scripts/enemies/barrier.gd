class_name Barrier
extends Enemy
## A barrier across the stage 4 base's tunnel (the blast door, bulkheads):
## a wall from the tunnel floor up to the play plane, the screen's whole
## width. It is hit as a box (Enemy.half_ext): shots, the Spear and homing
## lasers break it, and the ship that meets it crashes. While it is on the
## screen (or about to be) the scroll brakes to `brake` (Game._tick_play),
## which gives the time to shoot it down; broken, it lets the scroll pick up
## again. It comes with the scroll: on the tunnel's mouth (params gate: the
## blast door in the gate's frame) or on its own from above the screen,
## placed in a gap between the ground sections (they would run through it;
## Terrain holds back new ones until it is on the screen).
## params: gate, z

const HALF_W := 18.0  # out past the screen's edges
const COME_IN := 12.0  # how far above the screen it comes in on its own

var placed := false


func _init_kind() -> void:
	radius = HALF_W
	half_ext = Vector2(HALF_W, 0.6)
	counts = true
	ram = true
	leaves = false
	blast = 2.6
	energy_drop = 8.0


func _behave(dt: float) -> void:
	var seg := _mouth()
	if seg != null:
		position.z = seg.global_position.z
		visible = true
		placed = true
	elif not placed and p.get("gate", false) and _tunnel() != null:
		# its frame has not come in yet
		position.z = -200.0
		visible = false
	else:
		if not placed and not p.has("z"):
			position.z = _clear_z(game.field_top - COME_IN)
		placed = true
		position.z += game.scroll_speed * dt
	if position.z > game.field_bottom + 3.0:
		game.remove_enemy(self)


func _tunnel() -> Tunnel:
	return game.backdrop.tunnel if game.backdrop != null else null


## The gate it stands in (the tunnel's mouth), once that has come in.
func _mouth() -> MeshInstance3D:
	if not p.get("gate", false):
		return null
	var tn := _tunnel()
	if tn == null or not is_instance_valid(tn.mouth_seg):
		return null
	return tn.mouth_seg


## The nearest point from z on up that no ground section runs through.
func _clear_z(z: float) -> float:
	var moved := true
	while moved:
		moved = false
		for isl in game.terrain.islands:
			var half := isl.h * Island.CELL * 0.5
			if z > isl.position.z - half - 1.5 and z < isl.position.z + half + 1.5:
				z = isl.position.z - half - 1.5
				moved = true
	return z
