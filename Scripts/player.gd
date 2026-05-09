extends CharacterBody2D

@onready var eyes = $Eyes
@onready var audio_stream_player = $AudioStreamPlayer
@onready var camera = $Camera

@onready var slime_jump = load("res://Sounds/slime_jump.wav")
@onready var slime_land = load("res://Sounds/slime_land.wav")
@onready var particles = $Dust/Particles

const FOLLOW_RADIUS = 2.0
const GRAVITY = 800.0
const SPEED = 400.0
const STICK_TIME = 3.0
const MAX_CHARGE_TIME = 1

var stuck := false
var stick_normal := Vector2.ZERO
var stick_timer := 0.0
var sliding := false
var charge_timer := 0.0
var just_launched := false
var launch_timer := 0.0

var target_camera_zoom = Vector2.ONE * 3

const LAUNCH_GRACE = 0.1

func _physics_process(delta: float) -> void:
	if just_launched:
		launch_timer += delta
		if launch_timer >= LAUNCH_GRACE:
			just_launched = false

	if Input.is_action_just_pressed("ui_accept"):
		charge_timer = 0.0
	if Input.is_action_just_released("ui_accept") and charge_timer > 0:
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
				velocity += Vector2.DOWN * GRAVITY / 8 * delta
		elif surface == "ceiling":
			stick_timer += delta
			if stick_timer >= STICK_TIME:
				stuck = false
				velocity += Vector2.DOWN * GRAVITY / 4 * delta
		else:
			stick_timer += delta

	elif sliding:
		velocity.y += GRAVITY * delta
		velocity.x = 0.0
		if get_slide_collision_count() > 0:
			var collision = get_slide_collision(0)
			var normal = collision.get_normal()
			if normal.dot(Vector2.UP) > 0.5:
				sliding = false
				velocity = Vector2.ZERO
	else:
		velocity += Vector2.DOWN * GRAVITY * delta
		if velocity.length() > 0.1:
			rotation = velocity.angle() + PI / 2

	move_and_slide()

	if not just_launched and not stuck and not sliding and get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		stick_normal = collision.get_normal()
		rotation = stick_normal.angle() + PI / 2
		audio_stream_player.stream = slime_land
		audio_stream_player.play()
		stuck = true
		stick_timer = 0.0
		velocity = Vector2.ZERO

func _get_surface_type(normal: Vector2) -> String:
	if normal.dot(Vector2.UP) > 0.5:
		return "floor"
	elif normal.dot(Vector2.DOWN) > 0.5:
		return "ceiling"
	else:
		return "wall"
		
func _launch(charge_time: float) -> void:
	if not stuck and not sliding:
		return

	stuck = false
	sliding = false
	just_launched = true
	launch_timer = 0.0

	var local_up = transform.y * -1
	var mouse_dir = (get_global_mouse_position() - global_position).normalized()

	var away_angle = local_up.angle()
	var mouse_angle = mouse_dir.angle()

	var diff = fmod(mouse_angle - away_angle + PI, TAU) - PI
	diff = clamp(diff, deg_to_rad(-70), deg_to_rad(70))

	var final_dir = Vector2(cos(away_angle + diff), sin(away_angle + diff))
	var charge_factor = 1.0 + (clamp(charge_time, 0.0, MAX_CHARGE_TIME) / MAX_CHARGE_TIME) * 0.5
	velocity = final_dir * SPEED * charge_factor

	particles.emitting = true
	particles.restart()
	audio_stream_player.stream = slime_jump
	audio_stream_player.play()

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_accept"):
			charge_timer += delta
	target_camera_zoom = 3 + (charge_timer / MAX_CHARGE_TIME) * 0.5
	camera.zoom = camera.zoom.lerp(Vector2.ONE * target_camera_zoom, 0.1)

	var direction = (get_global_mouse_position() - global_position).normalized()
	eyes.global_position = global_position + direction * FOLLOW_RADIUS
