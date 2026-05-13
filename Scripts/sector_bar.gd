extends Control

@export var progress_value: float = 1.0:
    set(v):
        progress_value = clampf(v, 0.0, 1.0)
        queue_redraw()

@export var bar_color: Color = Color(0.3, 0.6, 1.0)
@export var bar_radius: float = 12.0:
    set(v):
        bar_radius = v
        custom_minimum_size = Vector2.ONE * bar_radius * 2
        queue_redraw()
@export var border_color: Color = Color(1, 1, 1, 0.4)
@export var border_width: float = 2.0

func _ready():
    custom_minimum_size = Vector2.ONE * bar_radius * 2
    size = Vector2.ONE * bar_radius * 2

func _draw():
    var center = size / 2
    var r = min(size.x, size.y) / 2 - border_width
    var outer = r + border_width

    draw_circle(center, outer, border_color)
    draw_circle(center, r, Color(0, 0, 0, 0.3))

    if progress_value <= 0.0:
        return

    var start_angle = -PI / 2
    var sweep = progress_value * TAU
    var end_angle = start_angle + sweep

    var segments = maxi(int(48 * progress_value), 4)
    var points: PackedVector2Array = [center]
    for i in range(segments + 1):
        var a = start_angle + sweep * (float(i) / segments)
        points.append(center + Vector2(cos(a), sin(a)) * r)

    draw_colored_polygon(points, bar_color)

    draw_arc(center, r, start_angle, end_angle, segments, border_color, border_width, true)
    draw_line(center, center + Vector2(cos(start_angle), sin(start_angle)) * r, border_color, border_width)
    draw_line(center, center + Vector2(cos(end_angle), sin(end_angle)) * r, border_color, border_width)
