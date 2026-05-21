extends Node2D

@onready var sprite: Sprite2D = $Sprite
@onready var launching_point: Node2D = $LaunchingPoint
@onready var trajectory_line: Line2D = $TrajectoryLine

@onready var camera: Camera2D = get_parent().get_node("Camera")

@onready var potato_scene: PackedScene = preload("res://Scenes/potato.tscn")

@onready var explosion_sound = load("res://Sounds/PotatoLauncher/explosion.mp3")
@onready var launch_sound = load("res://Sounds/PotatoLauncher/launch.wav")

@onready var particles: Node2D = get_parent().get_parent().get_node("ParticlesEmitter")

@export var projectile_speed: float = 600.0
@export var gravity: float = 900.0
@export var recoil_distance: float = 12.0
@export var shot_cooldown: float = 0.8
@export var recoil_interpolation_speed: float = 10.0
@export var rotation_interpolation_speed: float = 12.0

@export_flags_2d_physics var trajectory_collision_mask: int = 2

var active_potatoes: Array = []
var to_remove: Array = []
var cooldown_timer: float = 0.0
var screen_size: Vector2
var recoil_offset: float = 0.0
var target_rotation: float = 0.0
var base_position: Vector2

var particle_pool: Dictionary = {}
var pool_size: int = 5

func _ready() -> void:
	trajectory_line.clear_points()
	screen_size = get_viewport().size
	base_position = get_parent().global_position
	cooldown_timer = 0.0

func _process(delta: float) -> void:
	base_position = get_parent().global_position

	var mouse_pos = get_global_mouse_position()
	target_rotation = (mouse_pos - base_position).angle()
	global_rotation = lerp_angle(global_rotation, target_rotation, rotation_interpolation_speed * delta)

	scale.y = -1.0 if abs(global_rotation) > PI / 2 else 1.0

	recoil_offset = lerp(recoil_offset, 0.0, recoil_interpolation_speed * delta)
	global_position = base_position + Vector2.from_angle(global_rotation) * recoil_offset

	cooldown_timer = max(cooldown_timer - delta, 0.0)
	if cooldown_timer == 0.0:
		sprite.frame = 0
		# trajectory_line.visible = true
		if Input.is_action_just_pressed("shoot"):
			_shoot()

	var cam = get_viewport().get_camera_2d()
	var cam_pos = cam.global_position
	var half = screen_size / 2

	var aim_dir = Vector2.from_angle(global_rotation)
	_update_trajectory_line(launching_point.global_position, aim_dir * projectile_speed)

	to_remove.clear()
	for potato in active_potatoes:
		_update_potato(potato, delta)
		var p = potato.global_position
		if p.x < cam_pos.x - half.x - 100 or p.x > cam_pos.x + half.x + 100 \
		or p.y < cam_pos.y - half.y - 100 or p.y > cam_pos.y + half.y + 100:
			to_remove.append(potato)

	for potato in to_remove:
		potato.queue_free()
		active_potatoes.erase(potato)

func _shoot() -> void:
	recoil_offset = -recoil_distance
	cooldown_timer = 0.8
	print(cooldown_timer)
	
	# trajectory_line.visible = false
	Utils.emit_particles_at_position(launching_point.global_position, "MuzzleFlash", global_rotation)
	Utils.play_sound_at_position(launching_point.global_position, launch_sound, self)
	
	sprite.frame = 1

	var aim_dir = Vector2.from_angle(global_rotation)
	var potato = potato_scene.instantiate() as CharacterBody2D
	potato.velocity = aim_dir * projectile_speed
	potato.global_rotation = aim_dir.angle()
	potato.global_position = launching_point.global_position
	get_tree().current_scene.add_child(potato)
	active_potatoes.append(potato)

func _update_trajectory_line(start_pos: Vector2, initial_velocity: Vector2) -> void:
	trajectory_line.clear_points()
	var space = get_world_2d().direct_space_state
	var time_step = 0.05

	var prev_pos = start_pos
	trajectory_line.add_point(prev_pos)

	for i in range(1, 26):
		var t = i * time_step
		var next_pos = Vector2(
			start_pos.x + initial_velocity.x * t,
			start_pos.y + initial_velocity.y * t + 0.5 * gravity * t * t
		)

		var query = PhysicsRayQueryParameters2D.create(prev_pos, next_pos)
		query.exclude = active_potatoes
		query.collision_mask = trajectory_collision_mask
		var result = space.intersect_ray(query)

		if result:
			trajectory_line.add_point(result.position)
			break

		trajectory_line.add_point(next_pos)
		prev_pos = next_pos

func _update_potato(potato: CharacterBody2D, delta: float) -> void:
	potato.velocity.y += gravity * delta
	var potato_dir = potato.velocity.normalized()
	potato.global_rotation = lerp_angle(potato.global_rotation, potato_dir.angle(), rotation_interpolation_speed * delta)
	var collision = potato.move_and_collide(potato.velocity * delta)
	if collision:
		Utils.play_sound_at_position(potato.global_position, explosion_sound, potato)
		Utils.emit_particles_at_position(potato.global_position, "Smoke")
		Utils.emit_particles_at_position(potato.global_position, "Explosion")

		particles.get_node("Explosion2").global_position = potato.global_position
		particles.get_node("Explosion2").play()

		var distance_to_camera = potato.global_position.distance_to(camera.global_position)
		var shake_intensity = 75.0 / (distance_to_camera / 10)

		camera.shake(shake_intensity, 0.5)

		to_remove.append(potato)
		potato.queue_free()
		active_potatoes.erase(potato)
