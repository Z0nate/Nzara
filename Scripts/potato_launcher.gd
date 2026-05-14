extends Node2D

func _ready() -> void:
	pass # Replace with function body.


func _process(_delta: float) -> void:
	global_position = get_parent().global_position
	look_at(get_global_mouse_position())
	scale.y = -1 if get_global_mouse_position().x < global_position.x else 1
