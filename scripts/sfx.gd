class_name Sfx
extends Node
## Simple chip-style sound effects synthesised at start-up (no asset files):
## square/triangle tones with pitch sweeps and decaying noise. Pooled players
## with a per-sound minimum gap so rapid fire never piles up.

const RATE := 22050
const MIN_GAP := {"shot": 0.06, "hit": 0.045, "deflect": 0.08, "tile": 0.04, "tile_break": 0.04, "energy": 0.035, "exp_s": 0.05, "exp_m": 0.08}
const LEVEL := {"shot": -16.0, "hit": -15.0, "deflect": -17.0, "tile": -20.0, "tile_break": -15.0, "energy": -18.0, "exp_s": -8.0, "exp_m": -6.0, "exp_l": -3.0}

var streams := {}
var players: Array[AudioStreamPlayer] = []
var last := {}
var next_player := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	for i in 24:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)


func play(name: String) -> void:
	if not streams.has(name):
		return
	var now := Time.get_ticks_msec() * 0.001
	var gap: float = MIN_GAP.get(name, 0.03)
	if now - float(last.get(name, -1.0)) < gap:
		return
	last[name] = now
	var p := players[next_player]
	next_player = (next_player + 1) % players.size()
	p.stream = streams[name]
	p.volume_db = LEVEL.get(name, -8.0)
	p.play()


# ------------------------------------------------------------ synthesis

func _build() -> void:
	streams["shot"] = _wav(_tone(1400.0, 700.0, 0.045, "square", 0.5))
	streams["hit"] = _wav(_noise(0.04, 0.6, 0.5))
	streams["deflect"] = _wav(_tone(2400.0, 2100.0, 0.05, "square", 0.35))
	streams["tile"] = _wav(_noise(0.025, 0.4, 0.8))
	streams["tile_break"] = _wav(_mix(_noise(0.09, 0.7, 0.4), _tone(500.0, 200.0, 0.08, "square", 0.3)))
	streams["energy"] = _wav(_tone(1760.0, 2640.0, 0.04, "triangle", 0.5))
	streams["exp_s"] = _wav(_noise(0.28, 1.0, 0.15))
	streams["exp_m"] = _wav(_mix(_noise(0.5, 1.0, 0.1), _tone(160.0, 50.0, 0.4, "square", 0.4)))
	streams["exp_l"] = _wav(_mix(_noise(1.3, 1.0, 0.05), _tone(110.0, 30.0, 1.1, "square", 0.5)))
	streams["spear"] = _wav(_mix(_noise(0.35, 0.6, 0.2), _tone(300.0, 1600.0, 0.3, "square", 0.35)))
	streams["homing"] = _wav(_seq([[900.0, 1800.0], [1100.0, 2200.0], [1300.0, 2600.0]], 0.06, "triangle", 0.5))
	streams["power"] = _wav(_seq([[523.0, 523.0], [659.0, 659.0], [784.0, 784.0], [1047.0, 1047.0]], 0.07, "square", 0.4))
	streams["star"] = _wav(_seq([[1568.0, 1568.0], [2093.0, 2093.0], [2637.0, 2637.0]], 0.05, "triangle", 0.5))
	streams["shield"] = _wav(_mix(_tone(900.0, 200.0, 0.35, "square", 0.45), _noise(0.3, 0.5, 0.2)))
	streams["die"] = _wav(_mix(_noise(1.2, 1.0, 0.04), _tone(800.0, 40.0, 1.0, "square", 0.5)))
	streams["warning"] = _wav(_seq([[880.0, 880.0], [660.0, 660.0], [880.0, 880.0], [660.0, 660.0], [880.0, 880.0], [660.0, 660.0]], 0.22, "square", 0.35))
	streams["extend"] = _wav(_seq([[784.0, 784.0], [988.0, 988.0], [1175.0, 1175.0], [1568.0, 1568.0], [1175.0, 1175.0], [1568.0, 1568.0]], 0.07, "square", 0.4))
	streams["slam"] = _wav(_tone(600.0, 120.0, 0.4, "square", 0.35))
	streams["start"] = _wav(_seq([[392.0, 392.0], [523.0, 523.0], [659.0, 659.0], [784.0, 784.0]], 0.09, "square", 0.35))
	streams["clear"] = _wav(_seq([[523.0, 523.0], [659.0, 659.0], [784.0, 784.0], [1047.0, 1047.0], [784.0, 784.0], [1047.0, 1047.0]], 0.12, "square", 0.35))
	streams["cursor"] = _wav(_tone(1200.0, 1200.0, 0.04, "square", 0.3))


func _tone(f0: float, f1: float, dur: float, wave: String, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / n
		var f := f0 * pow(f1 / f0, t)
		ph += f / RATE
		var x := fmod(ph, 1.0)
		var s := 0.0
		match wave:
			"square":
				s = 1.0 if x < 0.5 else -1.0
			"triangle":
				s = 4.0 * absf(x - 0.5) - 1.0
			_:
				s = sin(ph * TAU)
		var env := minf(1.0, i / (RATE * 0.004)) * pow(1.0 - t, 1.5)
		out[i] = s * env * vol
	return out


## Decaying noise; `tone` (0..1) lowers the pitch by holding samples.
func _noise(dur: float, vol: float, tone: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var hold := maxi(1, int(1.0 / maxf(tone, 0.02)))
	var v := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(dur * 1000.0) + hold
	for i in n:
		var t := float(i) / n
		if i % hold == 0:
			v = rng.randf_range(-1.0, 1.0)
		out[i] = v * vol * pow(1.0 - t, 2.0)
	return out


func _seq(notes: Array, step: float, wave: String, vol: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for nt: Array in notes:
		out.append_array(_tone(nt[0], nt[1], step, wave, vol))
	return out


func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n := maxi(a.size(), b.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var s := 0.0
		if i < a.size():
			s += a[i]
		if i < b.size():
			s += b[i]
		out[i] = clampf(s, -1.0, 1.0)
	return out


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
