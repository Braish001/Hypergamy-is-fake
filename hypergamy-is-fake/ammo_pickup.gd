extends Area2D

@export var ammo_amount: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body != null and body.has_method("collect_shotgun_ammo"):
		var taken: bool = body.collect_shotgun_ammo(ammo_amount)
		if taken:
			queue_free()
