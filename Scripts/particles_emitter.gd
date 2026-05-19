extends Node2D

@export var follow_mouse: bool = false
@export var emit_on_click: bool = true

var active_emitter: GPUParticles2D
var emitters: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if child is GPUParticles2D:
			emitters[child.name.to_lower()] = child
			child.emitting = false

	activate("fire")


func _process(_delta: float) -> void:
	if follow_mouse and active_emitter:
		active_emitter.global_position = get_global_mouse_position()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: activate("fire")
			KEY_2: activate("sparks")
			KEY_3: activate("smoke")
			KEY_4: activate("magic")

	if emit_on_click and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			burst_at(get_global_mouse_position())


func activate(preset_name: String) -> void:
	if not emitters.has(preset_name):
		return

	if active_emitter:
		active_emitter.emitting = false

	active_emitter = emitters[preset_name]
	active_emitter.global_position = global_position
	active_emitter.one_shot = false
	active_emitter.emitting = true


func burst_at(pos: Vector2) -> void:
	if not active_emitter:
		return

	active_emitter.global_position = pos
	active_emitter.restart()
	active_emitter.one_shot = true
	active_emitter.emitting = true


func emit_all() -> void:
	for emitter in emitters.values():
		emitter.global_position = global_position
		emitter.emitting = true


func stop_all() -> void:
	for emitter in emitters.values():
		emitter.emitting = false