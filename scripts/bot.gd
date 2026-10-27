class_name Bot
extends RefCounted
## A simple autopilot (--autoplay, and the viewer's B key): lines up under
## the nearest enemy, dodges bullets, picks up items, taps fast for
## Concentration and uses the Spear when bullets crowd in or a big target
## is close.

var game: Game
var frame := 0


func _init(g: Game) -> void:
	game = g


## Returns [move: Vector2, tap: bool, hold: bool, side: bool].
func think() -> Array:
	frame += 1
	var player := game.player
	var enemies := game.enemies
	var items := game.items
	var bullets := game.bullets
	var pp := player.position
	var goal := Vector3(pp.x, 0, game.field_bottom - 5.5)
	var best: Enemy = null
	var bd := INF
	for e in enemies:
		if e.dead or e.intangible or e.armored or not e.visible or not game.on_field(e.hit_pos, -1.0):
			continue
		var d := absf(e.hit_pos.x - pp.x) + maxf(0.0, e.hit_pos.z - pp.z) * 2.0
		if e.drops_power:
			d -= 6.0
		if d < bd:
			bd = d
			best = e
	if best != null:
		goal.x = best.hit_pos.x
		if best.category == "medium" or best.controller != null:
			goal.z = clampf(best.hit_pos.z + 7.0, game.field_top + 6.0, game.field_bottom - 3.0)
	# items
	for k in items.n:
		if items.kind[k] != Items.ENERGY or items.pos[k].distance_to(pp) < 5.0:
			if items.pos[k].z < pp.z + 1.0 and items.pos[k].z > game.field_top + 3.0:
				goal = items.pos[k]
				break
	var steer := goal - pp
	steer.y = 0.0
	if steer.length() > 1.0:
		steer = steer.normalized()
	# dodge
	var push := Vector3.ZERO
	for b in bullets.n:
		var d := pp - bullets.pos[b]
		d.y = 0.0
		var dist := d.length()
		if dist < 3.2 and dist > 0.01:
			var v := bullets.vel[b]
			var closing := -d.normalized().dot(v.normalized())
			if closing > 0.2:
				var side := Vector3(-v.z, 0, v.x).normalized()
				if side.dot(d) < 0.0:
					side = -side
				push += side * (3.2 - dist) * 1.4 + d.normalized() * (3.2 - dist) * 0.4
	# get out of a boss's marked strike line (a big move telegraphed toward
	# a point: a press hammer, a train's strike)
	# (or a path of points: a boom's sweep; or a thrown rock's line)
	for w: Dictionary in game.warnings:
		if w["kind"] != Game.Warn.MOVE or not (w["to"] is Vector3 or w["to"] is PackedVector3Array or w["to"] is Dictionary) or not is_instance_valid(w["node"]):
			continue
		if not w.get("bot", true):
			continue
		if not (w["node"] is Enemy) or ((w["node"] as Enemy).controller == null and not (w["node"] as Enemy).marked):
			continue
		var nd: Enemy = w["node"]
		# (or a corridor something big drives down: out of it sideways)
		if w["to"] is Dictionary and (w["to"] as Dictionary).has("lane"):
			var lane: PackedVector3Array = w["to"]["lane"]
			var ab := lane[1] - lane[0]
			ab.y = 0.0
			var f := (pp - lane[0]).dot(ab) / maxf(ab.length_squared(), 0.01)
			var nrm := Vector3(-ab.z, 0, ab.x).normalized()
			var off := (pp - lane[0]).dot(nrm)
			var band := float(w["to"].get("hw", 1.0)) + 1.6
			if f > -0.3 and f < 1.1 and absf(off) < band:
				# the nearer side, or toward the middle of the screen
				var s := signf(off) if absf(off) > 0.3 else (-signf(pp.x) if absf(pp.x) > 0.5 else 1.0)
				push += nrm * s * (band - absf(off) + 1.0) * 1.5
			continue
		# (or a circle where something lands: out of it)
		if w["to"] is Dictionary and not (w["to"] as Dictionary).has("laser"):
			var off := pp - nd.hit_pos
			off.y = 0.0
			var reach := float(w["to"].get("r", 1.0)) + 1.8
			var od := off.length()
			if od < reach:
				# sideways first: circles marching down a column must not pin
				# it between them
				var side := signf(off.x) if absf(off.x) > 0.3 else (-signf(pp.x) if absf(pp.x) > 0.5 else 1.0)
				var away := (off / od if od > 0.05 else Vector3.ZERO) + Vector3(side, 0, 0)
				push += away.normalized() * (reach - od) * 1.8
			continue
		# (a laser sight down a path: the same)
		var to = w["to"]["laser"] if w["to"] is Dictionary else w["to"]
		var path := PackedVector3Array([nd.hit_pos, to]) if to is Vector3 else (to as PackedVector3Array)
		for k in path.size() - 1:
			var a: Vector3 = path[k]
			var ab: Vector3 = path[k + 1] - a
			ab.y = 0.0
			var f := clampf((pp - a).dot(ab) / maxf(ab.length_squared(), 0.01), 0.0, 1.0)
			var d := pp - (a + ab * f)
			d.y = 0.0
			var dist := d.length()
			if dist < 3.6:
				var away := d / dist if dist > 0.05 else Vector3(-ab.z, 0, ab.x).normalized()
				push += away * (3.6 - dist) * 1.6
	for e in enemies:
		if e.dead or not e.ram or e.intangible:
			continue
		if e.half_ext != Vector2.ZERO:
			# a wall across the way: back off from it (it is shot down
			# by just firing ahead)
			var gap := e.gap_to(pp)
			if gap < 4.0 and pp.z > e.hit_pos.z:
				push += Vector3(0, 0, 1) * (4.0 - gap) * 1.5
			continue
		var d := pp - e.hit_pos
		d.y = 0.0
		var dist := d.length()
		var safe := e.radius + 2.2
		if dist < safe and dist > 0.01:
			push += d.normalized() * (safe - dist) * 1.5
	var mv := steer + push * 1.2
	var m2 := Vector2(mv.x, mv.z)
	if m2.length() > 1.0:
		m2 = m2.normalized()
	var tap := frame % 8 == 0
	var hold := true
	var near := bullets.count_near(pp, 3.0)
	var side := false
	if player.spear_cd <= 0.0:
		if near >= 4 or (best != null and best.radius >= 1.4 and absf(best.hit_pos.x - pp.x) < 2.5 and best.hit_pos.z > pp.z - Player.SPEAR_LEN) or player.energy >= 60.0:
			side = true
	return [m2, tap, hold, side]
