extends Control

@export var progress_value: float = 1.0:
    set(v):
        progress_value = clampf(v, 0.0, 1.0)
        queue_redraw()

@export var bar_color: Color = Color(0.3, 0.6, 1.0)
@export var bar_thickness: float = 6.0

@export var bar_radius: float = 40.0:
    set(v):
        bar_radius = v
        custom_minimum_size = Vector2.ONE * bar_radius * 2
        queue_redraw()

# Fraction of a full circle the gauge occupies (0.4 = 144°)
@export var track_sweep: float = 0.4:
    set(v):
        track_sweep = clampf(v, 0.0, 1.0)
        queue_redraw()

# Where the arc starts. -PI/2 = top, 0 = right.
@export var start_angle: float = -PI / 2.0:
    set(v):
        start_angle = v
        queue_redraw()

@export var border_color: Color = Color(1, 1, 1, 0.4)
@export var border_width: float = 2.0

func _ready():
    custom_minimum_size = Vector2.ONE * bar_radius * 2
    size = Vector2.ONE * bar_radius * 2

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

    var progress_angle = total_angle * progress_value
    var segment_count = maxi(int(48 * progress_value), 4)
    draw_arc(center, track_radius, start_angle, start_angle + progress_angle,
             segment_count, bar_color, bar_thickness)

    draw_arc(center, outer_radius, start_angle, start_angle + progress_angle,
             segment_count, border_color, border_width)