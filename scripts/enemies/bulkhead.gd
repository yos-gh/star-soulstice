extends Barrier
## A bulkhead shut across the base's tunnel between its waves (stage 4):
## about half a Spear breaks it; the scroll brakes while it comes.
## params: z

const INFO := {
	"name": "BULKHEAD", "category": "barrier", "stage": 4,
	"desc": "隔壁：基地の通路をふさぐ。近づく間はスクロールが遅くなる。ショットで壊せ（スピア半分ほど）、壊せないとぶつかってミス",
	"demos": [["SHUT", "one", [0.0, "bulkhead", 0.0]]],
	"area": "core", "scroll": 6.0,
}


func _init_kind() -> void:
	super._init_kind()
	hp = 30.0
	brake = 6.0
	score = 1500
	energy_drop = 6.0
	half_ext.y = 0.55
