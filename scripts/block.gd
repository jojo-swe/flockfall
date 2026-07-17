class_name FlockfallBlock
extends Node2D

var color_index: int = -1
var block_color: Color = Color.WHITE
var cell_size: float = 64.0

func setup(new_color_index: int, new_color: Color, new_cell_size: float) -> void:
	color_index = new_color_index
	block_color = new_color
	cell_size = new_cell_size
	queue_redraw()

func play_spawn() -> void:
	scale = Vector2(0.25, 0.25)
	rotation = randf_range(-0.18, 0.18)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", 0.0, 0.18)

func play_pop(delay: float = 0.0) -> void:
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.45, 0.15), 0.12).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	await tween.finished
	queue_free()

func move_to(target: Vector2, duration: float = 0.18) -> Signal:
	var tween := create_tween()
	tween.tween_property(self, "position", target, duration).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	return tween.finished

func _draw() -> void:
	var half := cell_size * 0.44
	var rect := Rect2(Vector2(-half, -half), Vector2(half * 2.0, half * 2.0))
	var shadow_rect := Rect2(rect.position + Vector2(3.0, 5.0), rect.size)
	draw_style_box(_make_box(Color(0.0, 0.0, 0.0, 0.20), 12.0), shadow_rect)
	draw_style_box(_make_box(block_color, 12.0), rect)
	draw_rect(rect, Color("#353044"), false, 3.0)
	draw_circle(Vector2(-half * 0.36, -half * 0.38), half * 0.18, Color(1.0, 1.0, 1.0, 0.28))

func _make_box(color: Color, radius: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = int(radius)
	box.corner_radius_top_right = int(radius)
	box.corner_radius_bottom_left = int(radius)
	box.corner_radius_bottom_right = int(radius)
	return box
