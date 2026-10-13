class_name Island
extends Node3D
## A floating island (rock or space-station deck) at Game.GROUND_Y, paved
## with destructible tiles on a 1 x 1 grid. Tiles absorb your main shots,
## give score and energy (harder tiles hide more energy), and a few hide a
## score star. Cell (i, j) centre in local space: (i - w/2 + .5, 0, j - h/2 + .5).

const TILE_HP := [1.0, 5.0, 12.0]
const TILE_ENERGY := [1.5, 4.0, 10.0]
const TILE_SCORE := [30, 100, 300]
const TILE_TOP := [0.125, 0.25, 0.375]

var game: Game
var w := 0
var h := 0
var types := PackedInt32Array()  # -1 = no tile
var hp := PackedFloat32Array()
var hidden := PackedByteArray()
var inst := PackedInt32Array()
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
			counts[t] += 1
			hp[idx] = TILE_HP[t]
			alive_tiles += 1
	for k in 3:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = Vox.get_mesh("tile%d" % k)
		mm.instance_count = counts[k]
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		add_child(mi)
		mms.append(mm)
	for idx in w * h:
		var t := types[idx]
		if t >= 0:
			var c := cell_center(idx % w, idx / w)
			mms[t].set_instance_transform(inst[idx], Transform3D(Basis.IDENTITY, c))
			mms[t].set_instance_color(inst[idx], Color(1, 1, 1))


func cell_center(i: int, j: int) -> Vector3:
	return Vector3(i - w * 0.5 + 0.5, 0.0, j - h * 0.5 + 0.5)


## Tile index under a ground-level world point, or -1.
func tile_at(g: Vector3) -> int:
	var l := g - position
	var i := int(floor(l.x + w * 0.5))
	var j := int(floor(l.z + h * 0.5))
	if i < 0 or j < 0 or i >= w or j >= h:
		return -1
	var idx := j * w + i
	return idx if types[idx] >= 0 else -1


## Point on the play plane where tile idx appears.
func tile_plane_pos(idx: int) -> Vector3:
	var t := maxi(types[idx], 0)
	return game.to_plane(position + cell_center(idx % w, idx / w) + Vector3(0, TILE_TOP[t], 0))


func damage(idx: int, dmg: float) -> void:
	var t := types[idx]
	if t < 0:
		return
	hp[idx] -= dmg
	if hp[idx] <= 0.0:
		_destroy(idx)
	else:
		var f: float = 0.5 + 0.5 * hp[idx] / TILE_HP[t]
		mms[t].set_instance_color(inst[idx], Color(f * 1.25, f * 1.15, f * 1.1))


func _destroy(idx: int) -> void:
	var t := types[idx]
	var at := tile_plane_pos(idx)
	var world := position + cell_center(idx % w, idx / w)
	types[idx] = -1
	alive_tiles -= 1
	# park it far away (a zero-scale basis makes NaN normals that bloom)
	mms[t].set_instance_transform(inst[idx], Transform3D(Basis.IDENTITY, Vector3(0, -400, 0)))
	game.on_tile_broken(at, world, t, hidden[idx] == 1)
