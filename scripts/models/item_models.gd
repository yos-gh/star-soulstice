class_name ItemModels
extends Models
## Pick-ups (the energy cube itself is drawn by Items).

const NAMES := ["energy", "power", "star"]


static func make(name: String) -> ArrayMesh:
	match name:
		"energy":
			return _energy()
		"power":
			return _power()
		"star":
			return _star()
	return null


static func _energy() -> ArrayMesh:
	var v := Vox.new(4, 6, 4)
	v.jitter = 0.0
	# a lit crystal with a dim self-lit band: readable, but no bloom
	var body := Color(0.34, 0.66, 0.5)
	var band := Color(0.3, 0.72, 0.46)
	v.fill(-1, 1, -1, 0, 4, 0, body)
	v.fill(-2, 2, -1, 1, 3, 0, band, true)
	v.fill(-1, 2, -2, 0, 3, 1, band, true)
	v.fill(-1, 0, -1, 0, 0, 0, body.darkened(0.2))
	v.fill(-1, 5, -1, 0, 5, 0, body.lightened(0.2))
	return v.mesh(0.09, Vector3(0, 3.0, 0), true)


## Power capsule: blue shell with white caps, a glowing band and a "P".
static func _power() -> ArrayMesh:
	var v := Vox.new(16, 7, 10)
	v.blob(0, 3, 0, 6.5, 2.6, 3.2, BLUE)
	v.fill(-7, 2, -1, -6, 4, 0, WHITE)
	v.fill(5, 2, -1, 6, 4, 0, WHITE)
	v.fill(-5, 3, -3, 4, 3, 2, CYAN, true)
	v.fill(-1, 5, -2, -1, 6, 2, WHITE)
	v.fill(0, 6, -2, 1, 6, -2, WHITE)
	v.fill(0, 6, 0, 1, 6, 0, WHITE)
	v.put(1, 6, -1, WHITE)
	return v.mesh(0.12, Vector3(0, 3.0, 0))


static func _star() -> ArrayMesh:
	var v := Vox.new(12, 3, 12)
	for z in range(-6, 6):
		for x in range(-6, 6):
			var p := Vector2(x + 0.5, z + 0.5)
			var a := atan2(p.y, p.x) + PI / 2.0
			var lobe := 0.5 + 0.5 * cos(5.0 * a)
			if p.length() < 2.4 + 3.4 * pow(lobe, 2.0):
				v.put(x, 1, z, YELLOW, true)
				if p.length() < 2.0:
					v.put(x, 2, z, Color(1.0, 0.97, 0.8), true)
	return v.mesh(0.1, Vector3(0, 1.5, 0), true)

