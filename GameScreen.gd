## GameScreen.gd
## Core gameplay screen for BLOCKNOVA
## 8x8 grid, drag & drop block placement, row/column clearing, scoring
## Loaded and managed by Main.gd

class_name GameScreen
extends Node2D

signal game_over(score: int)

const SCREEN_W  : int   = 480
const SCREEN_H  : int   = 854
const GRID_SIZE : int   = 8
const NUM_PIECES: int   = 3

# Grid layout
var CELL_SIZE    : float = 48.0
var GRID_ORIGIN  : Vector2

# Grid state: -1 = empty, 0..N = color index
var grid : Array = []   # [row][col] → Color or null

# Score
var score      : int = 0
var combo      : int = 0
var score_lbl  : Label
var combo_lbl  : Label

# Piece trays at bottom
const TRAY_Y_START : float = 680.0
var piece_holders  : Array[PieceHolder] = []

# Drag state
var dragging_piece  : PieceHolder = null
var drag_offset     : Vector2     = Vector2.ZERO
var drag_ghost      : Node2D      = null
var ghost_valid     : bool        = false
var ghost_grid_pos  : Vector2i    = Vector2i(-1, -1)

var rng := RandomNumberGenerator.new()
var elapsed : float = 0.0

# ─────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────
func _ready() -> void:
	rng.randomize()
	# Calculate grid to center in screen
	CELL_SIZE   = min(float(SCREEN_W - 40) / GRID_SIZE, 52.0)
	GRID_ORIGIN = Vector2(
		(SCREEN_W - GRID_SIZE * CELL_SIZE) / 2.0,
		110.0
	)

func start_game() -> void:
	score   = 0
	combo   = 0
	elapsed = 0.0
	_init_grid()
	_rebuild_ui()
	_spawn_pieces()

# ─────────────────────────────────────────────
# PROCESS
# ─────────────────────────────────────────────
func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

# ─────────────────────────────────────────────
# DRAW
# ─────────────────────────────────────────────
func _draw() -> void:
	_draw_background()
	_draw_grid_bg()
	_draw_grid_cells()
	_draw_grid_lines()
	_draw_drag_ghost()

func _draw_background() -> void:
	for y in range(0, SCREEN_H, 4):
		var frac := float(y) / SCREEN_H
		var c    := Color(0.04, 0.08, 0.22).lerp(Color(0.06, 0.18, 0.40), frac)
		draw_line(Vector2(0, y), Vector2(SCREEN_W, y), c, 4)

func _draw_grid_bg() -> void:
	var rect := Rect2(GRID_ORIGIN - Vector2(6, 6),
	                  Vector2(GRID_SIZE * CELL_SIZE + 12, GRID_SIZE * CELL_SIZE + 12))
	draw_rect(rect, Color(0, 0, 0, 0.45))
	draw_rect(rect, Color(0.3, 0.55, 0.9, 0.18), false, 2.0)

func _draw_grid_cells() -> void:
	for r in GRID_SIZE:
		for c in GRID_SIZE:
			var cell_rect := _cell_rect(r, c)
			if grid[r][c] == null:
				# Empty cell — subtle checker
				var checker_alpha := 0.04 if (r + c) % 2 == 0 else 0.08
				draw_rect(cell_rect, Color(1, 1, 1, checker_alpha))
			else:
				var col : Color = grid[r][c]
				_draw_block_cell(cell_rect, col, 1.0)

func _draw_block_cell(rect: Rect2, col: Color, alpha: float) -> void:
	var shrunk := rect.grow(-2.0)
	draw_rect(shrunk, Color(col.r, col.g, col.b, alpha))
	# Top-left highlight
	draw_rect(Rect2(shrunk.position, Vector2(shrunk.size.x, 5)), Color(1, 1, 1, 0.18 * alpha))
	draw_rect(Rect2(shrunk.position, Vector2(5, shrunk.size.y)), Color(1, 1, 1, 0.12 * alpha))
	# Bottom-right shadow
	draw_rect(Rect2(shrunk.position + Vector2(0, shrunk.size.y - 5),
	                Vector2(shrunk.size.x, 5)), Color(0, 0, 0, 0.25 * alpha))
	# Outline
	draw_rect(shrunk, col.darkened(0.35), false, 1.5)

func _draw_grid_lines() -> void:
	for r in GRID_SIZE + 1:
		var y := GRID_ORIGIN.y + r * CELL_SIZE
		draw_line(Vector2(GRID_ORIGIN.x, y),
		          Vector2(GRID_ORIGIN.x + GRID_SIZE * CELL_SIZE, y),
		          Color(0.3, 0.55, 0.9, 0.12), 1.0)
	for c in GRID_SIZE + 1:
		var x := GRID_ORIGIN.x + c * CELL_SIZE
		draw_line(Vector2(x, GRID_ORIGIN.y),
		          Vector2(x, GRID_ORIGIN.y + GRID_SIZE * CELL_SIZE),
		          Color(0.3, 0.55, 0.9, 0.12), 1.0)

func _draw_drag_ghost() -> void:
	if dragging_piece == null:
		return
	var cells : Array = dragging_piece.shape_data["cells"]
	var col   : Color = dragging_piece.shape_data["color"]

	if ghost_grid_pos.x < 0 or ghost_grid_pos.y < 0:
		return

	var can_place := _can_place(cells, ghost_grid_pos)
	var ghost_col := col if can_place else Color(0.9, 0.2, 0.2)
	var ghost_alpha := 0.7 if can_place else 0.4

	for cell in cells:
		var gr : int = ghost_grid_pos.x + cell.x
		var gc : int = ghost_grid_pos.y + cell.y
		if gr >= 0 and gr < GRID_SIZE and gc >= 0 and gc < GRID_SIZE:
			var rect := _cell_rect(gr, gc)
			_draw_block_cell(rect, ghost_col, ghost_alpha)
			# Pulse outline
			draw_rect(rect.grow(-1), Color(1, 1, 1, 0.3 * ghost_alpha + sin(elapsed * 8.0) * 0.1), false, 2.0)

# ─────────────────────────────────────────────
# GRID LOGIC
# ─────────────────────────────────────────────
func _init_grid() -> void:
	grid = []
	for r in GRID_SIZE:
		var row := []
		for _c in GRID_SIZE:
			row.append(null)
		grid.append(row)

func _cell_rect(row: int, col: int) -> Rect2:
	return Rect2(
		GRID_ORIGIN.x + col * CELL_SIZE,
		GRID_ORIGIN.y + row * CELL_SIZE,
		CELL_SIZE, CELL_SIZE
	)

func _world_to_grid(pos: Vector2) -> Vector2i:
	var local := pos - GRID_ORIGIN
	return Vector2i(int(local.y / CELL_SIZE), int(local.x / CELL_SIZE))

func _can_place(cells: Array, grid_pos: Vector2i) -> bool:
	for cell in cells:
		var r : int = grid_pos.x + cell.x
		var c : int = grid_pos.y + cell.y
		if r < 0 or r >= GRID_SIZE or c < 0 or c >= GRID_SIZE:
			return false
		if grid[r][c] != null:
			return false
	return true

func _place_shape(cells: Array, grid_pos: Vector2i, col: Color) -> void:
	for cell in cells:
		var r : int = grid_pos.x + cell.x
		var c : int = grid_pos.y + cell.y
		grid[r][c] = col

func _check_and_clear() -> void:
	var rows_to_clear : Array[int] = []
	var cols_to_clear : Array[int] = []

	for r in GRID_SIZE:
		var full := true
		for c in GRID_SIZE:
			if grid[r][c] == null:
				full = false
				break
		if full:
			rows_to_clear.append(r)

	for c in GRID_SIZE:
		var full := true
		for r in GRID_SIZE:
			if grid[r][c] == null:
				full = false
				break
		if full:
			cols_to_clear.append(c)

	var cleared := rows_to_clear.size() + cols_to_clear.size()
	if cleared == 0:
		combo = 0
		return

	# Animate clear
	_animate_clear(rows_to_clear, cols_to_clear)

	# Clear cells
	for r in rows_to_clear:
		for c in GRID_SIZE:
			grid[r][c] = null
	for c in cols_to_clear:
		for r in GRID_SIZE:
			grid[r][c] = null

	# Score: 50 per line * cells * combo multiplier
	combo += 1
	var base_cells : int = cleared * GRID_SIZE
	var points     : int = base_cells * 10 * combo
	score += points
	_update_score_display()
	_show_combo_popup(points, combo)

func _animate_clear(rows: Array[int], cols: Array[int]) -> void:
	# Flash cleared rows/columns white
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color", Color(1, 1, 1, 0.45), 0.1)
	tw.tween_property(flash, "color", Color(1, 1, 1, 0.0), 0.22)
	tw.tween_callback(func(): flash.queue_free())

	# Spawn score particles per cleared line
	for r in rows:
		_spawn_line_particles(GRID_ORIGIN + Vector2(GRID_SIZE * CELL_SIZE / 2.0, r * CELL_SIZE + CELL_SIZE / 2.0))
	for c in cols:
		_spawn_line_particles(GRID_ORIGIN + Vector2(c * CELL_SIZE + CELL_SIZE / 2.0, GRID_SIZE * CELL_SIZE / 2.0))

func _spawn_line_particles(center: Vector2) -> void:
	for _i in 8:
		var p := ColorRect.new()
		p.size = Vector2(8, 8)
		p.color = Color(randf(), randf_range(0.7, 1.0), randf_range(0.2, 0.8))
		p.position = center
		add_child(p)
		var tw := create_tween()
		var target := center + Vector2(randf_range(-80, 80), randf_range(-80, 80))
		tw.tween_property(p, "position", target, 0.5).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.5)
		tw.tween_callback(func(): p.queue_free())

# ─────────────────────────────────────────────
# PIECE MANAGEMENT
# ─────────────────────────────────────────────
func _spawn_pieces() -> void:
	# Remove old holders
	for ph in piece_holders:
		ph.queue_free()
	piece_holders.clear()

	var tray_positions : Array[Vector2] = [
		Vector2(SCREEN_W * 0.18, TRAY_Y_START),
		Vector2(SCREEN_W * 0.50, TRAY_Y_START),
		Vector2(SCREEN_W * 0.82, TRAY_Y_START),
	]

	for i in NUM_PIECES:
		var shape_data : Dictionary = BlockShapes.get_random(rng)
		var ph := PieceHolder.new()
		ph.init(shape_data, tray_positions[i], CELL_SIZE * 0.72)
		ph.drag_started.connect(_on_drag_started.bind(ph))
		add_child(ph)
		piece_holders.append(ph)

	# Animate in
	for i in piece_holders.size():
		piece_holders[i].scale   = Vector2.ZERO
		piece_holders[i].modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(i * 0.1)
		tw.parallel().tween_property(piece_holders[i], "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
		tw.parallel().tween_property(piece_holders[i], "modulate:a", 1.0, 0.3)

func _check_game_over() -> void:
	# Check if any remaining piece can be placed anywhere
	for ph in piece_holders:
		if ph.used:
			continue
		for r in GRID_SIZE:
			for c in GRID_SIZE:
				if _can_place(ph.shape_data["cells"], Vector2i(r, c)):
					return   # At least one placement exists

	# No moves left → game over
	await get_tree().create_timer(0.5).timeout
	game_over.emit(score)

# ─────────────────────────────────────────────
# DRAG & DROP
# ─────────────────────────────────────────────
func _on_drag_started(touch_pos: Vector2, ph: PieceHolder) -> void:
	if ph.used:
		return
	dragging_piece = ph
	drag_offset    = Vector2.ZERO
	ph.start_drag()

func _input(event: InputEvent) -> void:
	if dragging_piece == null:
		return

	var pos : Vector2 = Vector2.ZERO
	var released : bool = false

	if event is InputEventScreenTouch:
		pos      = event.position
		released = not event.pressed
	elif event is InputEventScreenDrag:
		pos = event.position
	elif event is InputEventMouseButton:
		pos      = event.position
		released = not event.pressed
	elif event is InputEventMouseMotion:
		pos = event.position
	else:
		return

	# Offset so piece appears above thumb
	var lift_offset := Vector2(0, -CELL_SIZE * 1.5)
	dragging_piece.position = pos + lift_offset

	# Find grid position under center of piece
	var bounds      : Vector2i = BlockShapes.get_bounds(dragging_piece.shape_data["cells"])
	var piece_center := pos + lift_offset + Vector2(bounds.y * CELL_SIZE * 0.5 * 0.72, bounds.x * CELL_SIZE * 0.5 * 0.72)
	var gp          := _world_to_grid(piece_center)
	ghost_grid_pos  = gp

	if released:
		_try_place_piece(gp)
		queue_redraw()

func _try_place_piece(gp: Vector2i) -> void:
	if dragging_piece == null:
		return
	var cells : Array = dragging_piece.shape_data["cells"]
	var col   : Color = dragging_piece.shape_data["color"]

	if _can_place(cells, gp):
		_place_shape(cells, gp, col)
		_animate_place(cells, gp, col)
		dragging_piece.mark_used()
		dragging_piece = null
		ghost_grid_pos = Vector2i(-1, -1)
		_check_and_clear()
		# Check if all 3 used → respawn
		var all_used : bool = true
		for ph in piece_holders:
			if not ph.used:
				all_used = false
				break
		if all_used:
			_spawn_pieces()
		else:
			_check_game_over()
	else:
		# Reject — bounce back
		dragging_piece.cancel_drag()
		dragging_piece = null
		ghost_grid_pos = Vector2i(-1, -1)

func _animate_place(cells: Array, gp: Vector2i, col: Color) -> void:
	# Flash each placed cell
	for cell in cells:
		var r : int = gp.x + cell.x
		var c : int = gp.y + cell.y
		var rect := _cell_rect(r, c)
		var flash := ColorRect.new()
		flash.size     = Vector2(CELL_SIZE - 4, CELL_SIZE - 4)
		flash.position = rect.position + Vector2(2, 2)
		flash.color    = Color(col.r + 0.3, col.g + 0.3, col.b + 0.3, 0.8)
		add_child(flash)
		var tw := create_tween()
		tw.tween_property(flash, "modulate:a", 0.0, 0.3)
		tw.tween_callback(func(): flash.queue_free())

# ─────────────────────────────────────────────
# UI
# ─────────────────────────────────────────────
func _rebuild_ui() -> void:
	# Clear previous UI elements
	for child in get_children():
		if child is Label or child is ColorRect:
			# Keep only game-specific UI, not grid children
			if child.get_meta("ui_element", false):
				child.queue_free()

	# Score background
	var score_bg := ColorRect.new()
	score_bg.size = Vector2(SCREEN_W, 96)
	score_bg.color = Color(0.0, 0.0, 0.0, 0.4)
	score_bg.set_meta("ui_element", true)
	add_child(score_bg)

	# Score label
	score_lbl = Label.new()
	score_lbl.text = "SCORE: 0"
	score_lbl.add_theme_font_size_override("font_size", 34)
	score_lbl.add_theme_color_override("font_color", Color.WHITE)
	score_lbl.add_theme_constant_override("outline_size", 3)
	score_lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.2, 0.5))
	score_lbl.position = Vector2(SCREEN_W / 2.0 - 90, 28)
	score_lbl.set_meta("ui_element", true)
	add_child(score_lbl)

	# Combo label (hidden initially)
	combo_lbl = Label.new()
	combo_lbl.text = ""
	combo_lbl.add_theme_font_size_override("font_size", 28)
	combo_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.2))
	combo_lbl.add_theme_constant_override("outline_size", 3)
	combo_lbl.add_theme_color_override("font_outline_color", Color(0.5, 0.2, 0.0))
	combo_lbl.position = Vector2(SCREEN_W / 2.0 - 60, 62)
	combo_lbl.modulate.a = 0.0
	combo_lbl.set_meta("ui_element", true)
	add_child(combo_lbl)

	# Tray background
	var tray_bg := ColorRect.new()
	tray_bg.size = Vector2(SCREEN_W, SCREEN_H - 630)
	tray_bg.position = Vector2(0, 630)
	tray_bg.color = Color(0.02, 0.06, 0.18, 0.6)
	tray_bg.set_meta("ui_element", true)
	add_child(tray_bg)

	# Divider line
	var divider := ColorRect.new()
	divider.size = Vector2(SCREEN_W, 2)
	divider.position = Vector2(0, 630)
	divider.color = Color(0.3, 0.55, 0.9, 0.3)
	divider.set_meta("ui_element", true)
	add_child(divider)

func _update_score_display() -> void:
	if score_lbl:
		score_lbl.text = "SCORE: %d" % score
		# Punch animation
		var tw := create_tween()
		tw.tween_property(score_lbl, "scale", Vector2(1.25, 1.25), 0.07)
		tw.tween_property(score_lbl, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)

func _show_combo_popup(points: int, cmb: int) -> void:
	if not combo_lbl:
		return
	if cmb > 1:
		combo_lbl.text = "COMBO x%d  +%d" % [cmb, points]
	else:
		combo_lbl.text = "+%d" % points
	combo_lbl.modulate.a = 1.0
	combo_lbl.position   = Vector2(SCREEN_W / 2.0 - 80, 58)
	var tw := create_tween()
	tw.tween_property(combo_lbl, "position:y", 38.0, 0.35)
	tw.tween_interval(0.5)
	tw.tween_property(combo_lbl, "modulate:a", 0.0, 0.3)
