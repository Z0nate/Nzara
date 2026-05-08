extends CharacterBody2D

@onready var eyes = $Eyes
@onready var audio_stream_player = $AudioStreamPlayer
@onready var slime_jump = load("res://Sounds/slime_jump.wav")
@onready var slime_land = load("res://Sounds/slime_land.wav")
@onready var particles = $Dust/Particles

const FOLLOW_RADIUS = 2.0
const GRAVITY = 800.0
const SPEED = 400.0

var stuck := false
var stick_normal := Vector2.ZERO

func _physics_process(delta: float) -> void:
	if stuck:
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed("ui_accept"):
			stuck = false
			var dir = (get_global_mouse_position() - global_position).normalized()
			var dot = dir.dot(-stick_normal)
			if dot > 0.2:
				dir = dir.reflect(stick_normal)
			velocity = dir * SPEED
			
			# Visual Effects
			particles.emitting = true
			particles.restart()
			
			# Sound Effects
			audio_stream_player.stream = slime_jump
			audio_stream_player.play()
	else:
		velocity += Vector2.DOWN * GRAVITY * delta
		if velocity.length() > 0.1:
			rotation = velocity.angle() + PI / 2

	move_and_slide()

	if not stuck and get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		stick_normal = collision.get_normal()
		rotation = stick_normal.angle() + PI / 2
		audio_stream_player.stream = slime_land
		audio_stream_player.play()
		stuck = true
		velocity = Vector2.ZERO

func _process(_delta: float) -> void:
	var direction = (get_global_mouse_position() - global_position).normalized()
	eyes.global_position = global_position + direction * FOLLOW_RADIUS
