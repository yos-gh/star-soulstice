class_name Items
extends Node3D
## Pick-ups on the play plane. All are collected automatically when the ship
## comes near; missed ones flow off with the scroll.
##   ENERGY  homing ammo (from kills, cancelled bullets and broken tiles)
##   POWER   next ship form (from containers); falls slowly
##   STAR    score bonus hidden under some tiles

enum { ENERGY, POWER, STAR }

const MAX := 700
const MAGNET := [3.4, 2.8, 2.8]
const DRIFT := [2.4, 1.5, 1.8]

var game: Game
var pos := PackedVector3Array()
var vel := PackedVector3Array()
var kind := PackedInt32Array()
var val := PackedFloat32Array()
var age := PackedFloat32Array()
var pulled := PackedByteArray()
var n := 0
var vacuum := false  # pull everything (after the boss)
var mms: Array[MultiMeshInstance3D] = []


func _ready() -> void:
	pos.resize(MAX)
	vel.resize(MAX)
	kind.resize(MAX)
	val.resize(MAX)
	age.resize(MAX)
	pulled.resize(MAX)
	for name in ["energy", "power", "star"]:
		var mi := MultiMeshInstance3D.new()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = Vox.get_mesh(name)
		mm.instance_count = MAX if name == "energy" else 32
		mm.visible_instance_count = 0
		mi.multimesh = mm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.custom_aabb = AABB(Vector3(-60, -10, -60), Vector3(120, 20, 120))
		add_child(mi)
		mms.append(mi)


func spawn(p: Vector3, k: int, value := 1.0, v := Vector3.ZERO) -> void:
	if n >= MAX:
		return
	pos[n] = Vector3(p.x, 0.0, p.z)
	vel[n] = v
	kind[n] = k
	val[n] = value
	age[n] = 0.0
	pulled[n] = 0
	n += 1


## Scatters `total` energy as a few crystals around p.
func burst_energy(p: Vector3, total: float, spread := 5.0) -> void:
	if total <= 0.0:
		return
	var count := clampi(int(ceil(total / 2.0)), 1, 8)
	for i in count:
		var a := randf() * TAU
		var s := randf_range(0.4, 1.0) * spread
		spawn(p, ENERGY, total / count, Vector3(cos(a) * s, 0, sin(a) * s - 2.0))


func clear() -> void:
	n = 0


func _remove(i: int) -> void:
	n -= 1
	pos[i] = pos[n]
	vel[i] = vel[n]
	kind[i] = kind[n]
	val[i] = val[n]
	age[i] = age[n]
	pulled[i] = pulled[n]


func tick(dt: float) -> void:
	var pl := game.player
	var i := 0
	while i < n:
		age[i] += dt
		var k := kind[i]
		var p := pos[i]
		var v := vel[i]
		var drift := Vector3(0, 0, DRIFT[k] * (game.scroll_speed / Game.SCROLL))
		if pl.alive and pl.entering <= 0.0:
			var d := pl.position - p
			d.y = 0.0
			var dist := d.length()
			if dist < 0.8:
				game.collect(k, val[i], p)
				_remove(i)
				continue
			if vacuum or pulled[i] == 1 or dist < MAGNET[k]:
				pulled[i] = 1
				var spd := maxf(v.length(), 16.0) + 40.0 * dt
				v = d / dist * minf(spd, 40.0)
			else:
				v = v.lerp(drift, clampf(2.5 * dt, 0.0, 1.0))
		else:
			v = v.lerp(drift, clampf(2.5 * dt, 0.0, 1.0))
		p += v * dt
		pos[i] = p
		vel[i] = v
		if not game.on_field(p, 2.0) and age[i] > 0.5:
			_remove(i)
			continue
		i += 1


func draw() -> void:
	var counts := [0, 0, 0]
	var t := Time.get_ticks_msec() * 0.001
	for i in n:
		var k := kind[i]
		var mm := mms[k].multimesh
		var c: int = counts[k]
		if c >= mm.instance_count:
			continue
		var s := 1.0
		var b: Basis
		match k:
			ENERGY:
				s = 0.8 + minf(val[i], 8.0) * 0.12
				b = Basis(Vector3.UP, t * 4.0 + i).scaled(Vector3.ONE * s)
			POWER:
				b = Basis(Vector3.UP, sin(t * 2.0) * 0.4).scaled(Vector3.ONE * (1.0 + 0.08 * sin(t * 8.0)))
			_:
				b = Basis(Vector3.UP, t * 2.0).scaled(Vector3.ONE * 1.1)
		mm.set_instance_transform(c, Transform3D(b, pos[i] + Vector3(0, 0.6, 0)))
		counts[k] = c + 1
	for k in 3:
		mms[k].multimesh.visible_instance_count = counts[k]
