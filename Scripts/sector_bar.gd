extends Control

@export var progress_value: float = 1.0:
	set(v):
		progress_value = clampf(v, 0.0, 1.0)
		queue_redraw()

@export var bar_color: Color = Color(0.3, 0.6, 1.0)
@export var bar_thickness: float = 6.0
@export var bar_radius: float = 40.0

@export var track_sweep: float = 0.4
@export var start_angle: float = -0.5

@export var border_color: Color = Color(1, 1, 1, 0.4)
@export var border_width: float = 2.0

@export var progress_speed: float = 20.0

var target_progress: float = 1.0

func _ready():
	size = Vector2.ONE * bar_radius * 2
	custom_minimum_size = size
	pivot_offset = size / 2.0
	position = -pivot_offset
	modulate.a = 0.0
	mouse_filter = MOUSE_FILTER_IGNORE

func _draw():
	var center = size / 2
	var outer_radius = min(size.x, size.y) / 2 - border_width / 2.0
	var track_radius = outer_radius - bar_thickness / 2.0 - border_width / 2.0
	var total_angle = track_sweep * TAU
	var end_angle = start_angle + total_angle

	draw_arc(center, track_radius, start_angle, end_angle, 64,
			 Color(0, 0, 0, 0.3), bar_thickness + border_width)
	draw_arc(center, outer_radius, start_angle, end_angle, 64,
			 border_color, border_width)

	if progress_value <= 0.0:
		return

	var progress_angle = total_angle * (1.0 - progress_value)
	var segments = maxi(int(48 * progress_value), 4)
	draw_arc(center, track_radius, start_angle + progress_angle, end_angle,
			 segments, bar_color, bar_thickness)


func _process(delta: float) -> void:
	rotation = -get_parent().rotation

	progress_value = lerpf(progress_value, target_progress, 1 - exp(-progress_speed * delta))

	mouse_filter = MOUSE_FILTER_IGNORE if modulate.a <= 0.0 else MOUSE_FILTER_STOP

func set_visible_animated(bar_visible: bool, delta: float, speed: float = 10.0) -> void:
	var target_alpha = 1.0 if bar_visible else 0.0
	modulate.a = lerpf(modulate.a, target_alpha, 1 - exp(-speed * delta))
