extends Node2D

const VIEW_SIZE := Vector2(720.0, 1280.0)
const SLING_ORIGIN := Vector2(140.0, 250.0)
const MAX_DRAG_DISTANCE := 145.0
const MIN_LAUNCH_SPEED := 560.0
const LAUNCH_MULTIPLIER := 7.4

var palette: Array[Color] = [Color("#ff595e"), Color("#1982c4"), Color("#ffca3a"), Color("#8ac926")]
var grid: FlockfallGrid
var current_bird: FlockfallBird
var is_dragging := false
var input_enabled := true
var shots_remaining := 20
var score := 0
var combo := 0
var shake_strength := 0.0
var base_position := Vector2.ZERO
var score_label: Label
var shots_label: Label
var combo_label: Label
var instruction_label: Label
var result_panel: PanelContainer
var result_label: Label

func _ready() -> void:
	randomize()
	base_position = position
	_build_world()
	_build_ui()
	_spawn_next_bird()
	queue_redraw()

func _process(delta: float) -> void:
	_update_camera_shake(delta)
	if current_bird == null or not is_instance_valid(current_bird):
		return
	if current_bird.has_launched:
		_check_bird_landing()
		_check_bird_out_of_bounds()

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or current_bird == null or current_bird.has_launched:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.position.distance_to(current_bird.global_position) <= 70.0:
			is_dragging = true
			instruction_label.text = "Släpp för att skjuta"
		elif not event.pressed and is_dragging:
			is_dragging = false
			_release_bird()
	if event is InputEventMouseMotion and is_dragging:
		_drag_bird_to(event.position)
	if event is InputEventScreenTouch:
		if event.pressed and event.position.distance_to(current_bird.global_position) <= 90.0:
			is_dragging = true
			instruction_label.text = "Släpp för att skjuta"
		elif not event.pressed and is_dragging:
			is_dragging = false
			_release_bird()
	if event is InputEventScreenDrag and is_dragging:
		_drag_bird_to(event.position)

func _build_world() -> void:
	grid = FlockfallGrid.new()
	grid.position = Vector2(72.0, 770.0)
	add_child(grid)
	grid.cascade_started.connect(_on_cascade_started)
	grid.cascade_step.connect(_on_cascade_step)
	grid.cascade_finished.connect(_on_cascade_finished)
	var peg_positions := [Vector2(300,220), Vector2(470,205), Vector2(620,245), Vector2(230,355), Vector2(390,345), Vector2(555,370), Vector2(150,500), Vector2(315,505), Vector2(485,490), Vector2(650,520), Vector2(250,640), Vector2(430,635), Vector2(590,655)]
	for index in range(peg_positions.size()):
		var peg := FlockfallPeg.new()
		peg.position = peg_positions[index]
		peg.radius = 19.0 if index % 3 else 24.0
		add_child(peg)

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var title := Label.new()
	title.text = "FLOCKFALL"
	title.position = Vector2(26,18)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#fff4d6"))
	canvas.add_child(title)
	score_label = Label.new()
	score_label.position = Vector2(490,22)
	score_label.size = Vector2(200,46)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 26)
	canvas.add_child(score_label)
	shots_label = Label.new()
	shots_label.position = Vector2(24,72)
	shots_label.add_theme_font_size_override("font_size", 20)
	canvas.add_child(shots_label)
	combo_label = Label.new()
	combo_label.position = Vector2(245,690)
	combo_label.size = Vector2(230,60)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.add_theme_font_size_override("font_size", 34)
	combo_label.modulate.a = 0.0
	canvas.add_child(combo_label)
	instruction_label = Label.new()
	instruction_label.text = "Dra fågeln bakåt"
	instruction_label.position = Vector2(25,700)
	instruction_label.size = Vector2(670,42)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 22)
	canvas.add_child(instruction_label)
	result_panel = PanelContainer.new()
	result_panel.position = Vector2(110,460)
	result_panel.size = Vector2(500,300)
	result_panel.visible = false
	canvas.add_child(result_panel)
	var result_box := VBoxContainer.new()
	result_box.alignment = BoxContainer.ALIGNMENT_CENTER
	result_box.add_theme_constant_override("separation", 24)
	result_panel.add_child(result_box)
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 30)
	result_box.add_child(result_label)
	var restart_button := Button.new()
	restart_button.text = "Spela igen"
	restart_button.custom_minimum_size = Vector2(260,64)
	restart_button.add_theme_font_size_override("font_size", 24)
	restart_button.pressed.connect(_restart_game)
	result_box.add_child(restart_button)
	_update_hud()

func _spawn_next_bird() -> void:
	if shots_remaining <= 0:
		_show_result()
		return
	input_enabled = true
	var color_index := randi_range(0, palette.size() - 1)
	current_bird = FlockfallBird.new()
	add_child(current_bird)
	current_bird.setup(color_index, palette[color_index], SLING_ORIGIN)
	current_bird.peg_hit.connect(_on_bird_peg_hit)
	instruction_label.text = "Dra fågeln bakåt"
	queue_redraw()

func _drag_bird_to(pointer_position: Vector2) -> void:
	var drag_vector := pointer_position - SLING_ORIGIN
	drag_vector.x = min(drag_vector.x, -12.0)
	if drag_vector.length() > MAX_DRAG_DISTANCE:
		drag_vector = drag_vector.normalized() * MAX_DRAG_DISTANCE
	current_bird.global_position = SLING_ORIGIN + drag_vector
	queue_redraw()

func _release_bird() -> void:
	var pull_vector := SLING_ORIGIN - current_bird.global_position
	if pull_vector.length() < 20.0:
		current_bird.global_position = SLING_ORIGIN
		instruction_label.text = "Dra lite längre bakåt"
		return
	shots_remaining -= 1
	_update_hud()
	var velocity := pull_vector * LAUNCH_MULTIPLIER
	if velocity.length() < MIN_LAUNCH_SPEED:
		velocity = velocity.normalized() * MIN_LAUNCH_SPEED
	current_bird.launch(velocity)
	input_enabled = false
	instruction_label.text = ""
	queue_redraw()

func _check_bird_landing() -> void:
	if current_bird.global_position.y < grid.get_top_y_global() + 10.0:
		return
	var column := grid.get_column_from_global_x(current_bird.global_position.x)
	var color_index := current_bird.color_index
	var landing_position := current_bird.global_position
	current_bird.queue_free()
	current_bird = null
	_trigger_shake(6.0)
	_spawn_landing_particles(landing_position, palette[color_index])
	if not grid.can_insert(column):
		instruction_label.text = "Kolumnen är full!"
		await get_tree().create_timer(0.45).timeout
		_spawn_next_bird()
		return
	await grid.insert_bird(column, color_index)
	if current_bird == null and not grid.is_resolving:
		_spawn_next_bird()

func _check_bird_out_of_bounds() -> void:
	var p := current_bird.global_position
	if p.x < -100.0 or p.x > VIEW_SIZE.x + 100.0 or p.y < -180.0:
		current_bird.queue_free()
		current_bird = null
		instruction_label.text = "Miss!"
		await get_tree().create_timer(0.35).timeout
		_spawn_next_bird()

func _on_bird_peg_hit(impact_strength: float) -> void:
	_trigger_shake(clampf(impact_strength / 250.0, 1.5, 7.0))
	score += int(clampf(impact_strength * 0.035, 5.0, 70.0))
	_update_hud()

func _on_cascade_started() -> void:
	combo = 0

func _on_cascade_step(match_count: int, new_combo: int) -> void:
	combo = new_combo
	score += match_count * 100 * max(1, combo)
	_update_hud()
	combo_label.text = "CHAIN x%d" % combo
	combo_label.scale = Vector2(0.65,0.65)
	combo_label.modulate.a = 1.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(combo_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	tween.tween_property(combo_label, "modulate:a", 0.0, 0.55).set_delay(0.35)
	_trigger_shake(8.0 + combo * 2.5)

func _on_cascade_finished(_total_matches: int, _final_combo: int) -> void:
	await get_tree().create_timer(0.12).timeout
	if current_bird == null:
		_spawn_next_bird()

func _update_hud() -> void:
	score_label.text = "%07d" % score
	shots_label.text = "Fåglar: %d" % shots_remaining

func _show_result() -> void:
	input_enabled = false
	instruction_label.text = ""
	result_label.text = "Rundan är slut\n\nPoäng: %d" % score
	result_panel.visible = true

func _restart_game() -> void:
	get_tree().reload_current_scene()

func _trigger_shake(strength: float) -> void:
	shake_strength = max(shake_strength, strength)

func _update_camera_shake(delta: float) -> void:
	if shake_strength <= 0.05:
		position = base_position
		shake_strength = 0.0
		return
	position = base_position + Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	shake_strength = move_toward(shake_strength, 0.0, delta * 32.0)

func _spawn_landing_particles(world_position: Vector2, color: Color) -> void:
	for index in 12:
		var particle := Polygon2D.new()
		particle.polygon = PackedVector2Array([Vector2(-4,-4), Vector2(4,-4), Vector2(4,4), Vector2(-4,4)])
		particle.color = color.lightened(randf_range(0.0,0.25))
		particle.position = world_position
		particle.rotation = randf_range(0.0, TAU)
		add_child(particle)
		var direction := Vector2.UP.rotated(randf_range(-1.2,1.2))
		var target := world_position + direction * randf_range(50.0,130.0)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(particle, "position", target, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "rotation", particle.rotation + randf_range(-3.0,3.0), 0.35)
		tween.tween_property(particle, "modulate:a", 0.0, 0.35)
		tween.chain().tween_callback(particle.queue_free)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("#161427"), true)
	draw_circle(Vector2(610,110), 210.0, Color(0.25,0.18,0.48,0.30))
	draw_circle(Vector2(90,650), 260.0, Color(0.12,0.35,0.50,0.15))
	draw_line(SLING_ORIGIN + Vector2(-18,8), SLING_ORIGIN + Vector2(-36,92), Color("#8f5a3c"), 16.0, true)
	draw_line(SLING_ORIGIN + Vector2(18,8), SLING_ORIGIN + Vector2(36,92), Color("#8f5a3c"), 16.0, true)
	draw_line(SLING_ORIGIN + Vector2(-38,92), SLING_ORIGIN + Vector2(38,92), Color("#5c3a2b"), 18.0, true)
	if current_bird != null and is_instance_valid(current_bird) and not current_bird.has_launched:
		draw_line(SLING_ORIGIN + Vector2(-17,0), current_bird.global_position, Color("#35261f"), 7.0, true)
		draw_line(SLING_ORIGIN + Vector2(17,0), current_bird.global_position, Color("#35261f"), 7.0, true)
		if is_dragging:
			_draw_trajectory_preview()

func _draw_trajectory_preview() -> void:
	var pull_vector := SLING_ORIGIN - current_bird.global_position
	var velocity := pull_vector * LAUNCH_MULTIPLIER
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0) * current_bird.gravity_scale
	for step in range(1,18):
		var time := step * 0.085
		var point := SLING_ORIGIN + velocity * time + Vector2(0.0, 0.5 * gravity * time * time)
		if step % 2 == 0:
			draw_circle(point, 4.0, Color(1.0,1.0,1.0,0.55))
