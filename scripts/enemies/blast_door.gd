extends Barrier
## The blast door of the enemy base (stage 4): shut in the gate's frame at
## the mouth of the base's tunnel. About one Spear (without homing) breaks
## it; the scroll brakes while it comes.
## params: gate (ride the tunnel's mouth), z

const INFO := {
	"name": "BLAST DOOR", "category": "barrier", "stage": 4,
	"desc": "基地の扉：通路をふさぐ壁。近づく間はスクロールが遅くなる。ショットで壊せ（スピア1発ほど）、壊せないとぶつかってミス",
	"demos": [["SHUT", "one", [0.0, "blast_door", 0.0]]],
	"area": "hangar", "scroll": 4.5,
}


func _init_kind() -> void:
	super._init_kind()
	hp = 60.0
	brake = 4.5
	score = 3000
	energy_drop = 10.0
	half_ext.y = 0.75
