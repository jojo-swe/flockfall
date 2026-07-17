class_name FlockfallGrid
extends Node2D

signal cascade_started
signal cascade_step(matches: int, combo: int)
signal cascade_finished(total_matches: int, combo: int)

const COLUMNS := 8
const ROWS := 6
const EMPTY := -1

@export var cell_size: float = 72.0

var palette: Array[Color] = [Color("#ff595e"), Color("#1982c4"), Color("#ffca3a"), Color("#8ac926")]
var cells: Array = []
var block_nodes: Array = []
var is_resolving: bool = false

func _ready() -> void:
	_reset_arrays()
	_fill_starting_rows(3)
	queue_redraw()

func _reset_arrays() -> void:
	cells.clear()
	block_nodes.clear()
	for row in ROWS:
		var cell_row: Array[int] = []
		var node_row: Array[Node2D] = []
		for column in COLUMNS:
			cell_row.append(EMPTY)
			node_row.append(null)
		cells.append(cell_row)
		block_nodes.append(node_row)

func get_board_size() -> Vector2:
	return Vector2(COLUMNS * cell_size, ROWS * cell_size)

func get_top_y_global() -> float:
	return global_position.y

func get_column_from_global_x(global_x: float) -> int:
	var local_x := to_local(Vector2(global_x, global_position.y)).x
	return clampi(int(floor(local_x / cell_size)), 0, COLUMNS - 1)

func can_insert(column: int) -> bool:
	return column >= 0 and column < COLUMNS and cells[0][column] == EMPTY and not is_resolving

func insert_bird(column: int, color_index: int) -> bool:
	if not can_insert(column):
		return false
	var target_row := _find_lowest_empty_row(column)
	cells[target_row][column] = color_index
	var block := _create_block(target_row, column, color_index)
	block.position = _cell_center(0, column) + Vector2(0.0, -cell_size * 1.2)
	block_nodes[target_row][column] = block
	var tween := create_tween()
	tween.tween_property(block, "position", _cell_center(target_row, column), 0.24).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tween.finished
	await resolve_matches()
	return true

func resolve_matches() -> void:
	if is_resolving:
		return
	is_resolving = true
	cascade_started.emit()
	var combo := 0
	var total_matches := 0
	while true:
		var matches := _find_all_matches()
		if matches.is_empty():
			break
		combo += 1
		total_matches += matches.size()
		cascade_step.emit(matches.size(), combo)
		await _pop_matches(matches)
		await _collapse_columns()
		await get_tree().create_timer(0.08).timeout
	is_resolving = false
	cascade_finished.emit(total_matches, combo)

func _find_lowest_empty_row(column: int) -> int:
	for row in range(ROWS - 1, -1, -1):
		if cells[row][column] == EMPTY:
			return row
	return -1

func _find_all_matches() -> Array[Vector2i]:
	var found: Dictionary = {}
	for row in ROWS:
		var start_column := 0
		while start_column < COLUMNS:
			var color_index: int = cells[row][start_column]
			if color_index == EMPTY:
				start_column += 1
				continue
			var end_column := start_column + 1
			while end_column < COLUMNS and cells[row][end_column] == color_index:
				end_column += 1
			if end_column - start_column >= 3:
				for column in range(start_column, end_column):
					found[Vector2i(column, row)] = true
			start_column = end_column
	for column in COLUMNS:
		var start_row := 0
		while start_row < ROWS:
			var color_index: int = cells[start_row][column]
			if color_index == EMPTY:
				start_row += 1
				continue
			var end_row := start_row + 1
			while end_row < ROWS and cells[end_row][column] == color_index:
				end_row += 1
			if end_row - start_row >= 3:
				for row in range(start_row, end_row):
					found[Vector2i(column, row)] = true
			start_row = end_row
	var result: Array[Vector2i] = []
	for position: Vector2i in found.keys():
		result.append(position)
	return result

func _pop_matches(matches: Array[Vector2i]) -> void:
	var longest_delay := 0.0
	for index in range(matches.size()):
		var cell := matches[index]
		var row := cell.y
		var column := cell.x
		var block: FlockfallBlock = block_nodes[row][column]
		var delay := index * 0.012
		longest_delay = max(longest_delay, delay)
		cells[row][column] = EMPTY
		block_nodes[row][column] = null
		if is_instance_valid(block):
			block.play_pop(delay)
	await get_tree().create_timer(0.16 + longest_delay).timeout

func _collapse_columns() -> void:
	var movements: Array = []
	for column in COLUMNS:
		var write_row := ROWS - 1
		for read_row in range(ROWS - 1, -1, -1):
			if cells[read_row][column] == EMPTY:
				continue
			if read_row != write_row:
				cells[write_row][column] = cells[read_row][column]
				cells[read_row][column] = EMPTY
				var block: FlockfallBlock = block_nodes[read_row][column]
				block_nodes[write_row][column] = block
				block_nodes[read_row][column] = null
				if is_instance_valid(block):
					movements.append(block.move_to(_cell_center(write_row, column), 0.18))
			write_row -= 1
	if not movements.is_empty():
		await get_tree().create_timer(0.20).timeout

func _fill_starting_rows(row_count: int) -> void:
	var first_row := ROWS - row_count
	for row in range(first_row, ROWS):
		for column in COLUMNS:
			var color_index := _safe_random_color(row, column)
			cells[row][column] = color_index
			block_nodes[row][column] = _create_block(row, column, color_index)

func _safe_random_color(row: int, column: int) -> int:
	var candidates := range(palette.size())
	candidates.shuffle()
	for candidate in candidates:
		var makes_horizontal := column >= 2 and cells[row][column - 1] == candidate and cells[row][column - 2] == candidate
		var makes_vertical := row >= 2 and cells[row - 1][column] == candidate and cells[row - 2][column] == candidate
		if not makes_horizontal and not makes_vertical:
			return candidate
	return randi_range(0, palette.size() - 1)

func _create_block(row: int, column: int, color_index: int) -> FlockfallBlock:
	var block := FlockfallBlock.new()
	block.setup(color_index, palette[color_index], cell_size)
	block.position = _cell_center(row, column)
	add_child(block)
	return block

func _cell_center(row: int, column: int) -> Vector2:
	return Vector2(column * cell_size + cell_size * 0.5, row * cell_size + cell_size * 0.5)

func _draw() -> void:
	var size := get_board_size()
	var background := Rect2(Vector2.ZERO, size)
	draw_rect(background, Color("#252236"), true)
	draw_rect(background, Color("#665f7c"), false, 5.0)
	for row in ROWS:
		for column in COLUMNS:
			var cell_rect := Rect2(Vector2(column * cell_size, row * cell_size), Vector2.ONE * cell_size)
			draw_rect(cell_rect.grow(-4.0), Color(1.0, 1.0, 1.0, 0.035), false, 2.0)
