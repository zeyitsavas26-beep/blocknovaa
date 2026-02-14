## MenuScreen.gd
## Animated main menu for BLOCKNOVA
## Shows title, PLAY button, best score, and animated background
## Loaded and managed by Main.gd

class_name MenuScreen
extends Node2D

signal play_pressed

const SCREEN_W : int = 480
const SCREEN_H : int = 854

var elapsed     : float = 0.0
var bg_shapes   : Array[Dictionary] = []
var best_lbl    : Label
var play_btn    : Node2D

var letter_colors := [
	Color(0.95, 0.35, 0.35),
	Color(0.95, 0.62, 0.2),
	Color(0.95, 0.88, 0.2),
	Color(0.35, 0.88, 0.42),
	Color(0.28, 0.75, 0.95),
	Color(0.55, 0.38, 0.95),
	Color(0.95, 0.35, 0.78),
	Color(0.35, 0.95, 0.82),
	Color(0.95, 0.55, 0.28),
]

func _ready() -> void:
	_build_bg_shapes()
	_build_title()
	_build_play_button()
	_build_score_display()
	_animate_in()

func refresh(best: int) -> void:
	if best_lbl:
		best_lbl.text = "BEST: %d" % best
	_animate_in()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	# Bob play button
	if play_btn:
		play_btn.position.y = SCREEN_H * 0.62 + sin(elapsed * 2.2) * 6.0

func _draw() -> void:
	# Gradient background
	for y in range(0, SCREEN_H, 4):
		var frac := float(y) / SCREEN_H
		var c    := Color(0.04, 0.08, 0.28).lerp(Color(0.08, 0.22, 0.52), frac)
		draw_line(Vector2(0, y), Vector2(SCREEN_W, y), c, 4)

	# Animated background block shapes
	for sh in bg_shapes:
		var pos  : Vector2 = sh["pos"]
		var sz   : float   = sh["size"]
		var col  : Color   = sh["color"]
		var rot  : float   = sh["rot"] + elapsed * sh["rot_spd"]
		var drift_x : float = sin(elapsed * sh["freq"] + sh["phase"]) * 12.0
		var drift_y : float = cos(elapsed * sh["freq"] * 0.7 + sh["phase"]) * 8.0
		var draw_pos := pos + Vector2(drift_x, drift_y)
		var alpha : float = 0.08 + sin(elapsed * sh["freq"] + sh["phase"]) * 0.04
		draw_set_transform(draw_pos, rot, Vector2.ONE)
		draw_rect(Rect2(-sz/2, -sz/2, sz, sz), Color(col.r, col.g, col.b, alpha))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

# ─────────────────────────────────────────────
# BUILDERS
# ─────────────────────────────────────────────
func _build_bg_shapes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # Fixed seed for consistent look
	for _i in 18:
		bg_shapes.append({
			"pos"    : Vector2(rng.randf_range(30, SCREEN_W - 30), rng.randf_range(30, SCREEN_H - 30)),
			"size"   : rng.randf_range(30, 90),
			"color"  : letter_colors[rng.randi() % letter_colors.size()],
			"rot"    : rng.randf_range(0, TAU),
			"rot_spd": rng.randf_range(-0.4, 0.4),
			"freq"   : rng.randf_range(0.3, 1.2),
			"phase"  : rng.randf_range(0, TAU),
		})

func _build_title() -> void:
	var title_text := "BLOCKNOVA"
	var spacing    : float = 50.0
	var start_x    : float = (SCREEN_W - (title_text.length() - 1) * spacing) / 2.0

	for i in title_text.length():
		var wrapper := Node2D.new()
		wrapper.position = Vector2(start_x + i * spacing, SCREEN_H * 0.22 + sin(float(i) * 0.8) * 14.0)
		wrapper.name = "TitleLetter%d" % i

		var lbl := Label.new()
		lbl.text = title_text[i]
		lbl.add_theme_font_size_override("font_size", 56)
		lbl.add_theme_color_override("font_color", letter_colors[i % letter_colors.size()])
		lbl.add_theme_constant_override("outline_size", 5)
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
		lbl.add_theme_constant_override("shadow_offset_x", 4)
		lbl.add_theme_constant_override("shadow_offset_y", 4)
		lbl.position = Vector2(-18, -32)
		wrapper.add_child(lbl)
		add_child(wrapper)

	# Tagline
	var tag := Label.new()
	tag.text = "Puzzle Block Game"
	tag.add_theme_font_size_override("font_size", 22)
	tag.add_theme_color_override("font_color", Color(0.6, 0.78, 1.0, 0.85))
	tag.position = Vector2(SCREEN_W / 2.0 - 88, SCREEN_H * 0.32)
	add_child(tag)

func _build_play_button() -> void:
	play_btn = Node2D.new()
	play_btn.position = Vector2(SCREEN_W / 2.0, SCREEN_H * 0.62)
	add_child(play_btn)

	# Button background (drawn via ColorRect)
	var bg := ColorRect.new()
	bg.size = Vector2(220, 72)
	bg.position = Vector2(-110, -36)
	bg.color = Color(0.22, 0.62, 0.95)
	play_btn.add_child(bg)

	# Inner highlight
	var hl := ColorRect.new()
	hl.size = Vector2(216, 30)
	hl.position = Vector2(-108, -34)
	hl.color = Color(1.0, 1.0, 1.0, 0.12)
	play_btn.add_child(hl)

	# Label
	var lbl := Label.new()
	lbl.text = "▶  PLAY"
	lbl.add_theme_font_size_override("font_size", 38)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.2, 0.5))
	lbl.position = Vector2(-72, -28)
	play_btn.add_child(lbl)

	# Touch input
	var area := Area2D.new()
	var col  := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(220, 72)
	col.shape = shape
	area.add_child(col)
	area.input_pickable = true
	play_btn.add_child(area)
	area.input_event.connect(_on_play_input)

func _build_score_display() -> void:
	# Score area background
	var panel := ColorRect.new()
	panel.size = Vector2(280, 70)
	panel.position = Vector2(SCREEN_W / 2.0 - 140, SCREEN_H * 0.75)
	panel.color = Color(0.0, 0.0, 0.0, 0.3)
	add_child(panel)

	best_lbl = Label.new()
	best_lbl.text = "BEST: 0"
	best_lbl.add_theme_font_size_override("font_size", 30)
	best_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.25))
	best_lbl.add_theme_constant_override("outline_size", 3)
	best_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	best_lbl.position = Vector2(SCREEN_W / 2.0 - 70, SCREEN_H * 0.75 + 16)
	add_child(best_lbl)

# ─────────────────────────────────────────────
# ANIMATIONS
# ─────────────────────────────────────────────
func _animate_in() -> void:
	elapsed = 0.0
	if play_btn:
		play_btn.scale = Vector2.ZERO
		var tw := create_tween()
		tw.tween_interval(0.3)
		tw.tween_property(play_btn, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ─────────────────────────────────────────────
# INPUT
# ─────────────────────────────────────────────
func _on_play_input(_viewport, event, _shape_idx) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_press_play()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_press_play()

func _press_play() -> void:
	var tw := create_tween()
	tw.tween_property(play_btn, "scale", Vector2(0.88, 0.88), 0.07)
	tw.tween_property(play_btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.1)
	tw.tween_callback(func(): play_pressed.emit())
