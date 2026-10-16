extends Enemy
## A piece of a mid-boss or boss, moved by its controller (a BossBase).
## params: mesh ("" = an invisible hit zone, e.g. armour)

const INFO := {
	"name": "PART", "category": "part",
	"desc": "中ボス・ボスの部位（ボスが動かす）",
}


func _init_kind() -> void:
	mesh_name = p.get("mesh", "")
	leaves = false
	counts = false
