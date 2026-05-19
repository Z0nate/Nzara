extends Camera2D

var noise = FastNoiseLite.new()
var shake_intensity := 0.0
var shake_timer := 0.0
var target_offset := Vector2.ZERO
var target_rotation := 0.0

func shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_timer = duration

func _process(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		shake_intensity = lerpf(shake_intensity, 0.0, 1 - exp(-1.5 * delta))
		var t = Time.get_ticks_msec() * 0.1
		target_offset = Vector2(
			noise.get_noise_2d(t, 0.0),
			noise.get_noise_2d(0.0, t)
		) * shake_intensity
		target_rotation = noise.get_noise_2d(t, t) * shake_intensity * 0.002
	else:
		target_offset = Vector2.ZERO
		target_rotation = 0.0

	offset = offset.lerp(target_offset, 1 - exp(-30 * delta))
	rotation = lerpf(rotation, target_rotation, 1 - exp(-30 * delta))
