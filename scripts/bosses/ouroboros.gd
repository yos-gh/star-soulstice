extends BossBase
## Mid-boss of stage 2, the foundry's armoured freight train: a locomotive
## head and a train of armoured cars that follows it exactly (each car rides
## the head's trail a fixed distance back, so wherever the head went, the
## train goes). It comes in from the top and coils into a ring in front of
## the ship; while it turns, the cars spray shells out of the ring
## (breakable: the low-threat curtain) and the head fires telegraphed
## needle bursts. Then it stops and winds up: a lock-on marks the line,
## and the head strikes straight down it, brakes to a stop short of the
## bottom edge, swings round away from the ship and climbs back to coil
## again, the train behind it running the same line. Cars can be shot off
## one by one (the train closes up); destroying the head ends it. With all
## its cars gone it goes berserk: faster, a tighter coil, rings of shells
## from the head and quicker strikes. It leaves after a while.

const INFO := {
	"name": "OUROBOROS", "role": "mid",
	"desc": "装甲列車：自機の前でとぐろを巻いて回り、車両が輪の外へ物理弾をまく。止まって予兆（線を示す）のあと、頭が一直線に突っ込み、下端の手前で止まって自機と反対側へ回り込み戻る。車両は 1 両ずつ壊せる。車両を全部失うと発狂：速く小さくとぐろを巻き、頭から物理弾の輪、突進も早まる。頭を壊すと撃破",
	"demos": [["FULL", ""], ["STRIKE", "strike"]],
}
const HEAD_HP := 560.0
const SCORE := 25000
const CAR_HP := 30.0
const CAR_SCORE := 1500
const CARS := 8
const SPACING := 2.3
const SPEED := 11.0  # coiling
const STRIKE_SPEED := 27.0
const BRAKE := 60.0  # the strike ends in a stop at the marked point
const RING_R := 7.0
const COIL_TURN := 3.2  # rad/s
const COIL_TIME := 5.0  # coiling before the wind-up (the first time: FIRST_COIL)
const FIRST_COIL := 3.6
const AIM_TIME := 0.9  # wind-up (the telegraph)
const STEP := 0.2  # trail point spacing
const LIFE := 50.0

var head: Enemy
var cars: Array[Enemy] = []
var slots: Array[float] = []  # each car's place along the trail, in SPACINGs
var car_t: Array[float] = []  # each car's time to its next shell
var trail := PackedVector3Array()  # the head's path, newest first
var hpos := Vector3.ZERO
var hd := PI / 2.0  # heading (0 = +x, PI/2 = down-screen)
var spd := SPEED
var state := "enter"
var st := 0.0
var life_t := 0.0
var center := Vector3.ZERO
var lock := Vector3.ZERO
var turn_sign := 1.0
var cycle := 0
var fired := {}
var boom_t := 0.0
var berserk := false  # all cars gone
var ring_t := 0.0


func setup(g: Game) -> void:
	game = g
	center = Vector3(0, 0, game.field_top + 9.0)
	hpos = Vector3(-0.45 * game.field_hw, 0, game.field_top - 6.0)
	head = game.spawn_part(self, "ouro_head", 1.6)
	head.hp = HEAD_HP
	head.max_hp = HEAD_HP
	head.score = SCORE
	head.energy_drop = 30.0
	head.blast = 4.0
	for i in CARS:
		var c := game.spawn_part(self, "ouro_car", 1.15)
		c.hp = CAR_HP
		c.max_hp = CAR_HP
		c.score = CAR_SCORE
		c.energy_drop = 6.0
		c.blast = 1.8
		cars.append(c)
		slots.append(float(i + 1))
		car_t.append(0.4 + i * 0.17)
	# the train comes in straight from above
	for k in int((CARS + 2) * SPACING / STEP):
		trail.append(hpos + Vector3(0, 0, -(k + 1) * STEP))
	_place(0.0)


func on_hit(_e: Enemy, dmg: float) -> float:
	return 0.0 if defeated else dmg


func on_part_killed(e: Enemy) -> void:
	if e == head:
		_defeat()
		return
	var i := cars.find(e)
	if i >= 0:
		cars.remove_at(i)
		slots.remove_at(i)
		car_t.remove_at(i)
		game.shake(0.4)
		if cars.is_empty() and not berserk:
			berserk = true
			game.show_msg("OUROBOROS BERSERK", "", 1.2, true)


func _defeat() -> void:
	defeated = true
	state = "dying"
	st = 0.0
	boom_t = 0.25
	for b in game.bullets.cancel_owner(self):
		game.items.spawn(b, Items.ENERGY, 1.0)


func gauge() -> Dictionary:
	if defeated or state == "enter" and st < 1.0:
		return {}
	return {"frac": head.hp / HEAD_HP, "color": Hud.GOLD, "name": INFO["name"], "name_color": Color(1, 0.9, 0.6), "x": 0.25, "w": 0.5, "h": 7.0, "name_y": 70.0}


func force_defeat() -> void:
	if not defeated and not finished:
		game.kill(head)


## "strike": straight to the wind-up, the train already coiled.
func viewer_skip(to: String) -> void:
	if to != "strike":
		return
	var a0 := 0.0
	hpos = center + Vector3(cos(a0), 0, sin(a0)) * RING_R
	hd = a0 + PI / 2.0
	trail.clear()
	for k in int((CARS + 2) * SPACING / STEP):
		var a := a0 - (k + 1) * STEP / RING_R
		trail.append(center + Vector3(cos(a), 0, sin(a)) * RING_R)
	state = "coil"
	st = COIL_TIME - 0.3
	fired = {"n1.2": true, "n3.4": true}
	_place(0.0)


func debug_state() -> String:
	return "%s %.1fs  head %d/%d  cars %d  cycle %d" % [state, st, int(maxf(head.hp, 0.0)), int(HEAD_HP), cars.size(), cycle]


func tick(dt: float) -> void:
	if finished:
		return
	st += dt
	life_t += dt
	center.x = move_toward(center.x, clampf(game.player.position.x * 0.35, -5.0, 5.0), 1.5 * dt)
	match state:
		"enter":
			_coil_steer(dt)
			if absf(_flat(hpos - center).length() - RING_R) < 1.5 and st > 1.0:
				_go("coil")
		"coil":
			_coil_steer(dt)
			_spray(dt)
			_needles(1.2)
			_needles(3.4)
			if life_t > LIFE:
				_go("escape")
			elif st > (FIRST_COIL if cycle == 0 or berserk else COIL_TIME):
				_begin_aim()
		"aim":
			# stop and turn to the marked line
			spd = move_toward(spd, 0.0, 25.0 * dt)
			hd = _turn(hd, _ang(lock - hpos), 4.0 * dt)
			_move(dt)
			if st > AIM_TIME * (0.8 if berserk else 1.0):
				hd = _ang(lock - hpos)
				_go("strike")
		"strike":
			var left := _flat(lock - hpos).length()
			spd = minf(minf(spd + 80.0 * dt, STRIKE_SPEED), sqrt(2.0 * BRAKE * left))
			_move(dt)
			if left < 0.15 or (st > 0.3 and spd < 0.5):
				spd = 0.0
				# swing round away from the ship: clockwise (through -x)
				# when the ship is on the right
				turn_sign = 1.0 if game.player.position.x >= hpos.x else -1.0
				_go("turn")
		"turn":
			spd = move_toward(spd, 6.0, 20.0 * dt)
			hd = _turn(hd, -PI / 2.0, 2.2 * dt, turn_sign)
			_move(dt)
			if absf(wrapf(hd + PI / 2.0, -PI, PI)) < 0.3:
				_go("climb")
		"climb":
			spd = move_toward(spd, SPEED, 10.0 * dt)
			_coil_steer(dt)
			if absf(_flat(hpos - center).length() - RING_R) < 1.5:
				cycle += 1
				fired.clear()
				_go("coil")
		"escape":
			spd = move_toward(spd, 16.0, 8.0 * dt)
			hd = _turn(hd, -PI / 2.0, 2.5 * dt)
			_move(dt)
			var gone := hpos.z < game.field_top - 4.0
			for c in cars:
				gone = gone and c.position.z < game.field_top - 3.0
			if gone:
				_finish()
		"dying":
			# the cars go one after another, from the head back
			boom_t -= dt
			if boom_t <= 0.0:
				boom_t = 0.13
				if cars.is_empty():
					game.fx.explode(hpos + Vector3(0, 0.4, 0), 5.0, Vector3.ZERO, Models.CRIMSON)
					game.items.burst_energy(hpos, 24.0, 8.0)
					game.sfx.play("exp_l")
					game.shake(1.2)
					_finish()
					return
				var c: Enemy = cars.pop_front()
				slots.pop_front()
				car_t.pop_front()
				game.fx.explode(c.position + Vector3(0, 0.4, 0), 2.0, Vector3.ZERO, Models.CRIMSON)
				game.items.burst_energy(c.position, 4.0)
				game.sfx.play("exp_m")
				game.remove_enemy(c)
				c.queue_free()
	_place(dt)


func _go(s: String) -> void:
	state = s
	st = 0.0


func _begin_aim() -> void:
	var pp := game.player.position
	lock = Vector3(clampf(pp.x, -game.field_hw + 3.0, game.field_hw - 3.0), 0, minf(pp.z, game.field_bottom - 5.0))
	game.warn(head, AIM_TIME * (0.8 if berserk else 1.0), Game.Warn.MOVE, head.radius, lock)
	game.sfx.play("slam")
	_go("aim")


## Heading round the ring (clockwise on screen), pulled in or out onto it.
func _coil_steer(dt: float) -> void:
	var d := _flat(hpos - center)
	var dist := maxf(d.length(), 0.01)
	var tangent := Vector3(-d.z, 0, d.x) / dist
	var radial := -d / dist * clampf((dist - (RING_R * 0.7 if berserk else RING_R)) / 2.5, -1.0, 1.0)
	hd = _turn(hd, _ang(tangent + radial * 1.3), COIL_TURN * (1.6 if berserk else 1.0) * dt)
	spd = move_toward(spd, SPEED, 10.0 * dt) if not berserk else move_toward(spd, SPEED * 1.4, 10.0 * dt)
	_move(dt)


func _move(dt: float) -> void:
	hpos += Vector3(cos(hd), 0, sin(hd)) * spd * dt
	if trail.is_empty() or hpos.distance_to(trail[0]) >= STEP:
		trail.insert(0, hpos)
		var keep := int((CARS + 3) * SPACING / STEP) + 8
		if trail.size() > keep:
			trail.resize(keep)


## The cars spray shells out of the ring as it turns, big and small by turns.
func _spray(dt: float) -> void:
	if berserk:
		# the head alone: rings of shells, big and small by turns
		ring_t -= dt
		if ring_t <= 0.0 and game.can_fire(hpos):
			ring_t = 0.9
			game.bullets.ring(hpos, 14, 4.6, Bullets.SHELL, self, life_t * 1.3)
		return
	for i in cars.size():
		car_t[i] -= dt
		if car_t[i] > 0.0:
			continue
		car_t[i] = 1.4
		var c := cars[i]
		if not game.on_field(c.position, -0.5) or not game.can_fire(c.position):
			continue
		var out := _flat(c.position - center)
		game.bullets.fire(c.position, _ang(out), 4.2, Bullets.SHELL, self, Bullets.ROUND, 0.0, 0.0, Bullets.BIG if i % 2 == 0 else Bullets.SMALL)


## A telegraphed 3-way needle burst from the head at `at` seconds into the
## coil.
func _needles(at: float) -> void:
	var k := "n%.1f" % at
	if st >= at - Enemy.WINDUP_SHOT and not fired.has(k) and game.can_fire(hpos):
		fired[k] = true
		game.warn_then(head, Enemy.WINDUP_SHOT, Game.Warn.SHOT, func() -> void:
			if game.can_fire(head.position):
				game.bullets.fan(head.position, game.bullets.aim(head.position), 3, 14.0, 8.5, Bullets.ORB, self, Bullets.NEEDLE))


func _place(dt: float) -> void:
	head.position = hpos
	head.rotation.y = atan2(-cos(hd), -sin(hd))
	for i in cars.size():
		slots[i] = move_toward(slots[i], float(i + 1), 3.0 * dt)
		var at := _trail_at(slots[i] * SPACING)
		var ahead := _trail_at(slots[i] * SPACING - 0.5)
		cars[i].position = at
		var dir := ahead - at
		if dir.length_squared() > 0.0001:
			cars[i].rotation.y = atan2(-dir.x, -dir.z)


## The point `d` back along the head's trail (straight on past its end).
func _trail_at(d: float) -> Vector3:
	var acc := 0.0
	var prev := hpos
	for q in trail:
		var seg := prev.distance_to(q)
		if acc + seg >= d:
			return prev.lerp(q, (d - acc) / maxf(seg, 0.0001))
		acc += seg
		prev = q
	var n := trail.size()
	var dir := (trail[n - 1] - trail[n - 2]).normalized() if n >= 2 else Vector3(0, 0, -1)
	return prev + dir * (d - acc)


## Turns heading `a` toward `to` by at most `step` (radians); `sign` forces
## the way round (+1 = clockwise on screen, 0 = the short way).
func _turn(a: float, to: float, step: float, sign := 0.0) -> float:
	var diff := wrapf(to - a, -PI, PI)
	if sign != 0.0 and absf(diff) > 0.3 and signf(diff) != sign:
		diff += sign * TAU
	return a + clampf(diff, -step, step)


func _ang(v: Vector3) -> float:
	return atan2(v.z, v.x)


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


func _finish() -> void:
	finished = true
	for c in cars:
		game.remove_enemy(c)
		c.queue_free()
	cars.clear()
	game.remove_enemy(head)
	head.queue_free()
	game.remove_boss(self)
	queue_free()
