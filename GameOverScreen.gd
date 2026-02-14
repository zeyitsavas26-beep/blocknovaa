## GameOverScreen.gd
## Game Over screen for BLOCKNOVA
## Shows final score, best score, and options to retry or return to menu
## Loaded and managed by Main.gd

class_name GameOverScreen
extends Node2D

signal play_again
signal main_menu

const SCREEN_W : int = 480
const SCREEN_H : int = 854

var elapsed      : float = 0.0
var score_val    : int   = 0
var best_val     : int   = 0
var is_new_best  : bool  = false

var score_lbl    : Label
var best_lbl     : Label
var new_best_lbl : Label
var retry_btn    : Node2D
var menu_btn     : Node2D
var panel        : Node2D

func _ready() -> void:
	_build_overlay()
	_build_panel()
	_build_retry_button()
	_build_menu_button()

func setup(score: int, best: int) -> void:
	score_val   = score
	best_val    = best
	is_new_best = (score >= best and score > 0)
	elapsed     = 0.0

	score_lbl.text = "%d" % score
	best_lbl.text  = "BEST: %d" % best

	new_best_lbl.modulate.a = 1.0 if is_new_best else 0.0

	# Animate in
	panel.scale    = Vector2(0.3, 0.3)
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(0.15)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(panel, "modulate:a", 1.0, 0.3)

	# Animate score count up
	_count_up_score()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	# Bob buttons
	if retry_btn:
		retry_btn.position.y = SCREEN_H * 0.72 + sin(elapsed * 2.0) * 5.0
	if menu_btn:
		menu_btn.position.y = SCREEN_H * 0.83 + sin(elapsed * 2.0 + 1.0) * 5.0

func _draw() -> void:
	# Dimmed background overlay
	draw_rect(Rect2(0, 0, SCREEN_W, SCREEN_H), Color(0.0, 0.02, 0.08, 0.82))

# ─────────────────────────────────────────────
# BUILDERS
# ─────────────────────────────────────────────
func _build_overlay() -> void:
	pass  # Drawn in _draw()

func _build_panel() -> void:
	panel = Node2D.new()
	panel.position = Vector2(SCREEN_W / 2.0, SCREEN_H * 0.44)
	add_child(panel)

	# Panel background
	var bg := ColorRect.new()
	bg.size     = Vector2(360, 320)
	bg.position = Vector2(-180, -160)
	bg.color    = Color(0.06, 0.12, 0.30)
	panel.add_child(bg)

	# Panel border
	var border := ColorRect.new()
	border.size     = Vector2(360, 320)
	border.position = Vector2(-180, -160)
	border.color    = Color(0.3, 0.55, 0.9, 0.4)
	panel.add_child(border)
	var bg2 := ColorRect.new()
	bg2.size     = Vector2(354, 314)
	bg2.position = Vector2(-177, -157)
	bg2.color    = Color(0.06, 0.12, 0.30)
	panel.add_child(bg2)

	# "GAME OVER" title
	var go_lbl := Label.new()
	go_lbl.text = "GAME OVER"
	go_lbl.add_theme_font_size_override("font_size", 42)
	go_lbl.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35))
	go_lbl.add_theme_constant_override("outline_size", 4)
	go_lbl.add_theme_color_override("font_outline_color", Color(0.3, 0.0, 0.0))
	go_lbl.position = Vector2(-140, -145)
	panel.add_child(go_lbl)

	# Divider
	var div := ColorRect.new()
	div.size     = Vector2(320, 2)
	div.position = Vector2(-160, -88)
	div.color    = Color(0.3, 0.55, 0.9, 0.3)
	panel.add_child(div)

	# Score label
	var score_title := Label.new()
	score_title.text = "SCORE"
	score_title.add_theme_font_size_override("font_size", 22)
	score_title.add_theme_color_override("font_color", Color(0.65, 0.78, 0.98))
	score_title.position = Vector2(-50, -68)
	panel.add_child(score_title)

	score_lbl = Label.new()
	score_lbl.text = "0"
	score_lbl.add_theme_font_size_override("font_size", 62)
	score_lbl.add_theme_color_override("font_color", Color.WHITE)
	score_lbl.add_theme_constant_override("outline_size", 4)
	score_lbl.add_theme_color_override("font_outline_color", Color(0.15, 0.3, 0.65))
	score_lbl.position = Vector2(-60, -42)
	panel.add_child(score_lbl)

	# Best score
	best_lbl = Label.new()
	best_lbl.text = "BEST: 0"
	best_lbl.add_theme_font_size_override("font_size", 26)
	best_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.25))
	best_lbl.add_theme_constant_override("outline_size", 3)
	best_lbl.add_theme_color_override("font_outline_color", Color(0.4, 0.2, 0.0))
	best_lbl.position = Vector2(-60, 58)
	panel.add_child(best_lbl)

	# New best indicator
	new_best_lbl = Label.new()
	new_best_lbl.text = "★ NEW BEST! ★"
	new_best_lbl.add_theme_font_size_override("font_size", 24)
	new_best_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.18))
	new_best_lbl.add_theme_constant_override("outline_size", 3)
	new_best_lbl.add_theme_color_override("font_outline_color", Color(0.5, 0.3, 0.0))
	new_best_lbl.position = Vector2(-78, 98)
	new_best_lbl.modulate.a = 0.0
	panel.add_child(new_best_lbl)

func _build_retry_button() -> void:
	retry_btn = Node2D.new()
	retry_btn.position = Vector2(SCREEN_W / 2.0, SCREEN_H * 0.72)
	add_child(retry_btn)

	var bg := ColorRect.new()
	bg.size     = Vector2(260, 64)
	bg.position = Vector2(-130, -32)
	bg.color    = Color(0.22, 0.72, 0.38)
	retry_btn.add_child(bg)

	var hl := ColorRect.new()
	hl.size     = Vector2(256, 26)
	hl.position = Vector2(-128, -30)
	hl.color    = Color(1, 1, 1, 0.12)
	retry_btn.add_child(hl)

	var lbl := Label.new()
	lbl.text = "▶  PLAY AGAIN"
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.25, 0.1))
	lbl.position = Vector2(-100, -22)
	retry_btn.add_child(lbl)

	var area  := Area2D.new()
	var col   := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(260, 64)
	col.shape  = shape
	area.add_child(col)
	area.input_pickable = true
	retry_btn.add_child(area)
	area.input_event.connect(_on_retry_input)

func _build_menu_button() -> void:
	menu_btn = Node2D.new()
	menu_btn.position = Vector2(SCREEN_W / 2.0, SCREEN_H * 0.83)
	add_child(menu_btn)

	var bg := ColorRect.new()
	bg.size     = Vector2(260, 64)
	bg.position = Vector2(-130, -32)
	bg.color    = Color(0.18, 0.35, 0.72)
	menu_btn.add_child(bg)

	var hl := ColorRect.new()
	hl.size     = Vector2(256, 26)
	hl.position = Vector2(-128, -30)
	hl.color    = Color(1, 1, 1, 0.10)
	menu_btn.add_child(hl)

	var lbl := Label.new()
	lbl.text = "⌂  MAIN MENU"
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.1, 0.3))
	lbl.position = Vector2(-100, -22)
	menu_btn.add_child(lbl)

	var area  := Area2D.new()
	var col   := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(260, 64)
	col.shape  = shape
	area.add_child(col)
	area.input_pickable = true
	menu_btn.add_child(area)
	area.input_event.connect(_on_menu_input)

# ─────────────────────────────────────────────
# ANIMATION
# ─────────────────────────────────────────────
func _count_up_score() -> void:
	var target := score_val
	var tw     := create_tween()
	var counter := {"v": 0}
	tw.tween_method(
		func(v: float):
			score_lbl.text = "%d" % int(v),
		0.0,
		float(target),
		1.0
	).set_trans(Tween.TRANS_QUAD)

	# New best pulse
	if is_new_best:
		await get_tree().create_timer(0.8).timeout
		var ptw := create_tween().set_loops()
		ptw.tween_property(new_best_lbl, "modulate:a", 0.3, 0.5)
		ptw.tween_property(new_best_lbl, "modulate:a", 1.0, 0.5)

# ─────────────────────────────────────────────
# INPUT
# ─────────────────────────────────────────────
func _on_retry_input(_viewport, event, _shape_idx) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_press_retry()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_press_retry()

func _on_menu_input(_viewport, event, _shape_idx) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_press_menu()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_press_menu()

func _press_retry() -> void:
	var tw := create_tween()
	tw.tween_property(retry_btn, "scale", Vector2(0.88, 0.88), 0.07)
	tw.tween_property(retry_btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.1)
	tw.tween_callback(func(): play_again.emit())

func _press_menu() -> void:
	var tw := create_tween()
	tw.tween_property(menu_btn, "scale", Vector2(0.88, 0.88), 0.07)
	tw.tween_property(menu_btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.1)
	tw.tween_callback(func(): main_menu.emit())
