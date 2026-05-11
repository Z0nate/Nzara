extends CharacterBody2D

@onready var eyes = $Eyes
@onready var pointer = $Pointer
@onready var audio_stream_player = $AudioStreamPlayer
@onready var camera = $Camera

@onready var slime_jump = load("res://Sounds/slime_jump.wav")
@onready var slime_land = load("res://Sounds/slime_land.wav")
@onready var slime_long_jump = load("res://Sounds/slime_long_jump.wav")
@onready var slime_wall_slide_down = load("res://Sounds/slime_wall_slide_down.wav")
@onready var particles = $Particles

const EYE_FOLLOW_RADIUS = 2.0
const POINTER_FOLLOW_RADIUS = 25.0

var SPEED = 350.0
var STICK_TIME = 3.0
var MAX_CHARGE_TIME = 1
var MIN_CHARGE_TIME = 0.2
var GRAVITY: int = ProjectSettings.get_setting("physics/2d/default_gravity")

var stuck := false
var stick_normal := Vector2.ZERO
var stick_timer := 0.0
var sliding := false
var charge_timer := 0.0
var just_launched := false
var launch_timer := 0.0
var blink_timer := 0.0
var charge_factor := 1.0
var blink_time := randf_range(3.0, 5.0)
var launch_dir := Vector2.ZERO

var target_camera_zoom = 3.0
var charging := false
var wall_slide_playing := false
var wall_slide_delay_timer := 0.0
var falling_from_ceiling := false

const LAUNCH_GRACE = 0.0
const WALL_SLIDE_LOOP_DELAY = 0.3

func _eyes_blink(delta: float) -> void:
	if charge_timer > 0.0:
		eyes.frame = 1
	else:
		blink_timer += delta
		if blink_timer >= blink_time and blink_timer < blink_time + 0.1:
			eyes.frame = 1
		elif blink_timer >= blink_time + 0.1:
			eyes.frame = 0
			blink_timer = 0.0
			blink_time = randf_range(3.0, 5.0)
		else:
			eyes.frame = 0


func _player_movement(delta: float) -> void:
	if just_launched:
		launch_timer += delta
		if launch_timer >= LAUNCH_GRACE:
			just_launched = false

	if Input.is_action_just_pressed("ui_accept"):
		if  stuck or sliding:
			charging = true
			charge_timer = 0.0
	if (Input.is_action_just_released("ui_accept") or charge_timer >= MAX_CHARGE_TIME):
		charging = false
		if charge_timer > MIN_CHARGE_TIME:
			_launch(charge_timer)
		charge_timer = 0.0

	if stuck:
		velocity = Vector2.ZERO
		var surface := _get_surface_type(stick_normal)
		if surface == "wall":
			stick_timer += delta
			if stick_timer >= STICK_TIME:
				sliding = true
				stuck = false
				velocity += Vector2.DOWN * GRAVITY * delta
				if not wall_slide_playing:
					audio_stream_player.stream = slime_wall_slide_down
					audio_stream_player.play()
					wall_slide_playing = true
					wall_slide_delay_timer = 0.0
		elif surface == "ceiling":
			stick_timer += delta
			if stick_timer >= STICK_TIME:
				if not falling_from_ceiling:
					audio_stream_player.stream = slime_wall_slide_down
					audio_stream_player.play()
					falling_from_ceiling = true
				stuck = false
				velocity += Vector2.DOWN * GRAVITY * delta
		else:
			stick_timer += delta

	elif sliding:
		velocity.y += GRAVITY / 8.0 * delta
		velocity.x = 0.0
		if not audio_stream_player.playing and wall_slide_playing:
			wall_slide_delay_timer += delta
			if wall_slide_delay_timer >= WALL_SLIDE_LOOP_DELAY:
				audio_stream_player.play()
				wall_slide_delay_timer = 0.0
		if get_slide_collision_count() > 0:
			var collision = get_slide_collision(0)
			var normal = collision.get_normal()
			if normal.dot(Vector2.UP) > 0.5:
				_land(normal, false)
				audio_stream_player.stop()
				wall_slide_playing = false
		else:
			sliding = false
			audio_stream_player.stop()
			wall_slide_playing = false

	else:
		velocity += Vector2.DOWN * GRAVITY * delta
		if velocity.length() > 0.1:
			rotation = velocity.angle() + PI / 2

	move_and_slide()

	if not just_launched and not stuck and not sliding and get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		var normal = collision.get_normal()
		_land(normal, true)

func _get_surface_type(normal: Vector2) -> String:
	if normal.dot(Vector2.UP) > 0.5:
		return "floor"
	elif normal.dot(Vector2.DOWN) > 0.5:
		return "ceiling"
	else:
		return "wall"

func _get_launch_direction() -> Vector2:
	var local_up = transform.y * -1
	var mouse_dir = (get_global_mouse_position() - global_position).normalized()
	var away_angle = local_up.angle()
	var mouse_angle = mouse_dir.angle()
	var diff = fmod(mouse_angle - away_angle + PI, TAU) - PI
	diff = clamp(diff, deg_to_rad(-70), deg_to_rad(70))
	return Vector2(cos(away_angle + diff), sin(away_angle + diff))

func _land(normal: Vector2, impact: bool) -> void:
	stick_normal = normal
	rotation = normal.angle() + PI / 2
	particles.global_position = global_position
	var slime_particles = particles.get_node("Slime")
	slime_particles.amount = int(20 * charge_factor)
	if impact:
		slime_particles.restart()
		slime_particles.emitting = true
	audio_stream_player.stream = slime_land
	audio_stream_player.play()
	stuck = true
	stick_timer = 0.0
	velocity = Vector2.ZERO
	falling_from_ceiling = false
		
func _launch(charge_time: float) -> void:
	if not stuck and not sliding:
		return

	stuck = false
	sliding = false
	just_launched = true
	launch_timer = 0.0

	var final_dir = _get_launch_direction()
	charge_factor = 1.0 + (clamp(charge_time, 0.0, MAX_CHARGE_TIME) / MAX_CHARGE_TIME) * 0.5
	velocity = final_dir * SPEED * charge_factor

	charge_timer = 0.0

	particles.get_node("Dust").restart()
	particles.get_node("Dust").emitting = true

	if charge_time > MAX_CHARGE_TIME * 0.5:
		audio_stream_player.stream = slime_long_jump
	else:
		audio_stream_player.stream = slime_jump
	audio_stream_player.play()

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()

func _ready() -> void:
	pointer.global_position = global_position
	pointer.modulate.a = 0.0

func _process(delta: float) -> void:
	if stuck or sliding:
		if charging:
			camera.shake(charge_timer / MAX_CHARGE_TIME * 15.0, 0.1)
			charge_timer += delta
			if charge_timer >= MIN_CHARGE_TIME:
				pointer.modulate.a = lerpf(pointer.modulate.a, 1.0, 1 - exp(-20 * delta))
		else:
			pointer.modulate.a = lerpf(pointer.modulate.a, 0.0, 1 - exp(-20 * delta))
		target_camera_zoom = 3.0 + (charge_timer / MAX_CHARGE_TIME) * 0.5
	else:
		target_camera_zoom = 3.0
		pointer.modulate.a = lerpf(pointer.modulate.a, 0.0, 1 - exp(-10 * delta))
	
	camera.zoom = camera.zoom.lerp(Vector2.ONE * target_camera_zoom, 1 - exp(-5 * delta))

	launch_dir = _get_launch_direction() if (pointer.modulate.a <= 0.01 or (charging and (stuck or sliding))) else launch_dir
	var direction = (get_global_mouse_position() - global_position).normalized()
	eyes.global_position = global_position + direction * EYE_FOLLOW_RADIUS

	var target_pos = global_position + launch_dir * POINTER_FOLLOW_RADIUS
	pointer.global_position = pointer.global_position.lerp(target_pos, 1 - exp(-30 * delta))

	var target_rotation = launch_dir.angle() + PI / 2
	var angle_diff = angle_difference(pointer.global_rotation, target_rotation)
	pointer.global_rotation += angle_diff * (1 - exp(-30 * delta))

	pointer.visible = pointer.modulate.a > 0.01

func _physics_process(delta: float) -> void:
		_player_movement(delta)
		_eyes_blink(delta)
