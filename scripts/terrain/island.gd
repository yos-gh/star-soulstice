class_name Island
extends Node3D
## A floating island (rock or space-station deck) at Game.GROUND_Y, paved
## with destructible tiles on a grid. Tiles absorb your main shots,
## give score and energy (harder tiles hide more energy), and a few hide a
## score star. Cells are CELL x CELL units (like the NES 16 px blocks);
## cell (i, j) centre in local space: ((i - w/2 + .5) * CELL, 0, (j - h/2 + .5) * CELL).

const CELL := 2.0
const TILE_HP := [0.5, 1.0, 1.5]
const TILE_ENERGY := [2.0, 5.0, 10.0]
const TILE_SCORE := [50, 150, 400]
const TILE_TOP := [0.0, 0.125, 0.25]  # above the deck (tiles sit in sockets)

var game: Game
var w := 0
var h := 0
var types := PackedInt32Array()  # -1 = no tile
var hp := PackedFloat32Array()
var hidden := PackedByteArray()
var inst := PackedInt32Array()  # tile idx -> multimesh slot
var slot_tile: Array = [[], [], []]  # per type: slot -> tile idx (plain Arrays: packed ones are copied on access)
var mms: Array[MultiMesh] = []
var alive_tiles := 0


func setup(g: Game, lay: Dictionary) -> void:
	game = g
	w = lay["w"]
	h = lay["h"]
	types = (lay["types"] as PackedInt32Array).duplicate()
	hidden = lay["hidden"]
	hp.resize(w * h)
	inst.resize(w * h)
	var rock := MeshInstance3D.new()
	rock.mesh = lay["mesh"]
	add_child(rock)
	var counts := [0, 0, 0]
	for idx in w * h:
		var t := types[idx]
		if t >= 0:
			inst[idx] = counts[t]
			slot_tile[t].push_back(idx)
			counts[t] += 1
			hp[idx] = TILE_HP[t]
			alive_tiles += 1
	for k in 3:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = Vox.get_mesh("tile%d" % k)
		mm.instance_count = counts[k]
		mm.visible_instance_count = counts[k]
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		add_child(mi)
		mms.append(mm)
	for idx in w * h:
		var t := types[idx]
		if t >= 0:
			var c := cell_center(idx % w, idx / w)
			# slightly inset and raised so no face is coplanar with the deck
			# (coplanar tops flickered)
			mms[t].set_instance_transform(inst[idx], Transform3D(Basis.from_scale(Vector3(0.96, 1.0, 0.96)), c + Vector3(0, -IslandGen.R * 0.5 + 0.06, 0)))
			mms[t].set_instance_color(inst[idx], Color(1, 1, 1))


func cell_center(i: int, j: int) -> Vector3:
	return Vector3((i - w * 0.5 + 0.5) * CELL, 0.0, (j - h * 0.5 + 0.5) * CELL)


## Tile index under a ground-level world point, or -1.
func tile_at(g: Vector3) -> int:
	var l := g - position
	var i := int(floor(l.x / CELL + w * 0.5))
	var j := int(floor(l.z / CELL + h * 0.5))
	if i < 0 or j < 0 or i >= w or j >= h:
		return -1
	var idx := j * w + i
	return idx if types[idx] >= 0 else -1


## Point on the play plane where tile idx appears.
func tile_plane_pos(idx: int) -> Vector3:
	var t := maxi(types[idx], 0)
	return game.to_plane(position + cell_center(idx % w, idx / w) + Vector3(0, TILE_TOP[t], 0))


## Damages tile idx; returns the damage left over after breaking it (a
## strong shot punches through soft tiles).
func damage(idx: int, dmg: float) -> float:
	var t := types[idx]
	if t < 0:
		return dmg
	var before := hp[idx]
	hp[idx] -= dmg
	if hp[idx] <= 0.0:
		_destroy(idx)
		return dmg - before
	else:
		var f: float = 0.5 + 0.5 * hp[idx] / TILE_HP[t]
		mms[t].set_instance_color(inst[idx], Color(f * 1.25, f * 1.15, f * 1.1))
	return 0.0


func _destroy(idx: int) -> void:
	var t := types[idx]
	var at := tile_plane_pos(idx)
	var world := position + cell_center(idx % w, idx / w)
	types[idx] = -1
	alive_tiles -= 1
	_drop_slot(t, idx)
	game.on_tile_broken(at, world, t, hidden[idx] == 1)


## Removes a tile from its MultiMesh by moving the last visible slot into
## its place and shrinking the visible count.
func _drop_slot(t: int, idx: int) -> void:
	var mm := mms[t]
	var s := inst[idx]
	var last := mm.visible_instance_count - 1
	if last < 0:
		last = mm.instance_count - 1
	if s != last:
		var moved: int = slot_tile[t][last]
		mm.set_instance_transform(s, mm.get_instance_transform(last))
		mm.set_instance_color(s, mm.get_instance_color(last))
		slot_tile[t][s] = moved
		inst[moved] = s
	mm.visible_instance_count = last
