## =============================================================
## BLOCKNOVA — Complete Single-File Game (Main.gd)
## =============================================================
## Block Blast-style mobile puzzle game for Godot 4.x
##
## SETUP:
##   1. New Godot 4 project: "BLOCKNOVA"
##   2. Project Settings → Display → Window:
##        Width: 480  Height: 854  Orientation: Portrait
##        Stretch Mode: canvas_items  Aspect: expand
##   3. Create Main.tscn: root node = Node2D, name it "Main"
##   4. Attach THIS script to the Node2D root
##   5. Press Play — no assets needed, everything is generated
##   6. Android Export: standard Godot 4 Android export process
## =============================================================

extends Node2D

# ─────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────
const SW         : int   = 480     ## Screen width (virtual)
const SH         : int   = 854     ## Screen height (virtual)
const GRID_N     : int   = 8       ## Grid dimension (8×8)
const NUM_PIECES : int   = 3       ## Pieces shown in tray
const INTRO_DUR  : float = 5.0     ## Intro screen duration
const SAVE_PATH  : String = "user://blocknova_save.cfg"

## Block color palette
const COLORS : Array[Color] = [
	Color(0.95, 0.32, 0.32),  # Red
	Color(0.95, 0.62, 0.18),  # Orange
	Color(0.95, 0.88, 0.18),  # Yellow
	Color(0.28, 0.82, 0.38),  # Green
	Color(0.22, 0.68, 0.95),  # Blue
	Color(0.52, 0.32, 0.95),  # Purple
	Color(0.95, 0.32, 0.75),  # Pink
	Color(0.25, 0.88, 0.78),  # Cyan
	Color(0.95, 0.52, 0.28),  # Deep Orange
]

## All block shapes as Vector2i(row, col) offset arrays
const SHAPES : Array = [
	# 1-cell
	[Vector2i(0,0)],
	# 2-cell line H/V
	[Vector2i(0,0), Vector2i(0,1)],
	[Vector2i(0,0), Vector2i(1,0)],
	# 3-cell lines
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
	# 3-cell corners
	[Vector2i(0,0), Vector2i(0,1), Vector2i(1,0)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(1,0), Vector2i(1,1), Vector2i(0,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)],
	# 4-cell I
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)],
	# 4-cell O (2x2)
	[Vector2i(0,0), Vector2i(0,1), Vector2i(1,0), Vector2i(1,1)],
	# 4-cell L variants
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(2,1)],
	[Vector2i(0,1), Vector2i(1,1), Vector2i(2,0), Vector2i(2,1)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,0)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)],
	# 4-cell T
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,1)],
	[Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), Vector2i(1,2)],
	# 4-cell S/Z
	[Vector2i(0,1), Vector2i(0,2), Vector2i(1,0), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(1,2)],
	# 5-cell lines
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3), Vector2i(0,4)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0)],
	# 5-cell L
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,0), Vector2i(2,0)],
	# 3x3 square
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2),
	 Vector2i(1,0), Vector2i(1,1), Vector2i(1,2),
	 Vector2i(2,0), Vector2i(2,1), Vector2i(2,2)],
]

# ─────────────────────────────────────────────────────────────
# GAME STATE ENUM
# ─────────────────────────────────────────────────────────────
enum State { INTRO, MENU, GAME, GAME_OVER }
var state : State = State.INTRO

# ─────────────────────────────────────────────────────────────
# CANVAS LAYERS
# ─────────────────────────────────────────────────────────────
var l_intro    : CanvasLayer  ## Layer 20 — Intro screen
var l_menu     : CanvasLayer  ## Layer 10 — Main menu
var l_game     : CanvasLayer  ## Layer  5 — Gameplay
var l_gameover : CanvasLayer  ## Layer 30 — Game over overlay

# ─────────────────────────────────────────────────────────────
# INTRO VARS
# ─────────────────────────────────────────────────────────────
var i_elapsed    : float = 0.0
var i_letters    : Array[Control] = []
var i_particles  : Array[ColorRect] = []
var i_subtitle   : Label

# ─────────────────────────────────────────────────────────────
# MENU VARS
# ─────────────────────────────────────────────────────────────
var m_elapsed  : float = 0.0
var m_best_lbl : Label
var m_play_btn : Control
var m_shapes   : Array[Dictionary] = []
var m_draw_node: Node2D

# ─────────────────────────────────────────────────────────────
# GAME VARS
# ─────────────────────────────────────────────────────────────
var grid         : Array = []         ## grid[r][c] = Color|null
var cell_sz      : float = 48.0
var grid_origin  : Vector2
var g_elapsed    : float = 0.0
var g_score      : int = 0
var g_combo      : int = 0
var g_best       : int = 0
var g_score_lbl  : Label
var g_combo_lbl  : Label
var g_drawer     : Node2D             ## draws grid + ghost

## Pieces: each slot has data dict, a _PieceNode, and used flag
var p_data  : Array[Dictionary] = []
var p_nodes : Array[Node2D] = []
var p_used  : Array[bool] = []

## Drag state
var d_idx       : int = -1       ## which piece is being dragged
var d_touch_id  : int = -1
var d_started   : bool = false
var d_press_pos : Vector2
var d_ghost     : Vector2i = Vector2i(-1, -1)
const D_THRESH  : float = 10.0

# ─────────────────────────────────────────────────────────────
# GAME OVER VARS
# ─────────────────────────────────────────────────────────────
var go_elapsed    : float = 0.0
var go_panel      : Control
var go_score_lbl  : Label
var go_best_lbl   : Label
var go_newbest    : Label
var go_retry_btn  : Control
var go_menu_btn   : Control

# ─────────────────────────────────────────────────────────────
# RNG
# ─────────────────────────────────────────────────────────────
var rng := RandomNumberGenerator.new()

# ═════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════
func _ready() -> void:
	rng.randomize()
	_load_best()
	_calc_layout()
	_build_intro_layer()
	_build_menu_layer()
	_build_game_layer()
	_build_gameover_layer()
	_switch(State.INTRO)

func _process(delta: float) -> void:
	match state:
		State.INTRO:     _tick_intro(delta)
		State.MENU:      _tick_menu(delta)
		State.GAME:      _tick_game(delta)
		State.GAME_OVER: _tick_gameover(delta)

func _input(event: InputEvent) -> void:
	match state:
		State.MENU:      _in_menu(event)
		State.GAME:      _in_game(event)
		State.GAME_OVER: _in_gameover(event)

# ─────────────────────────────────────────────────────────────
# STATE SWITCH
# ─────────────────────────────────────────────────────────────
func _switch(new_state: State) -> void:
	state = new_state
	l_intro.visible    = (new_state == State.INTRO)
	l_menu.visible     = (new_state == State.MENU)
	l_game.visible     = (new_state == State.GAME)
	l_gameover.visible = (new_state == State.GAME_OVER)

	match new_state:
		State.INTRO:
			_start_intro()
		State.MENU:
			_start_menu()
		State.GAME:
			_start_game()

# ═════════════════════════════════════════════════════════════
# ██ INTRO SCREEN
# ═════════════════════════════════════════════════════════════
func _build_intro_layer() -> void:
	l_intro = CanvasLayer.new(); l_intro.layer = 20
	add_child(l_intro)

	# Background
	var bg := ColorRect.new()
	bg.size = Vector2(SW, SH); bg.color = Color(0.04, 0.08, 0.28)
	l_intro.add_child(bg)

	# Floating particles
	i_particles.clear()
	for _i in 24:
		var p := ColorRect.new()
		var sz := rng.randf_range(4, 13)
		p.size = Vector2(sz, sz)
		p.color = COLORS[rng.randi() % COLORS.size()]
		p.position = Vector2(rng.randf_range(0, SW), rng.randf_range(0, SH))
		p.set_meta("spd",   rng.randf_range(18, 72))
		p.set_meta("freq",  rng.randf_range(0.5, 2.5))
		p.set_meta("phase", rng.randf_range(0.0, TAU))
		p.modulate.a = 0.28
		l_intro.add_child(p)
		i_particles.append(p)

	# Letter nodes
	i_letters.clear()
	var text    := "BLOCKNOVA"
	var spacing : float = 50.0
	var sx      : float = (SW - (text.length() - 1) * spacing) / 2.0

	for i in text.length():
		var node := Control.new()
		node.size = Vector2(50, 72)
		var by := SH / 2.0 - 52.0 + sin(i * 0.78) * 16.0
		node.set_meta("by", by)
		node.position    = Vector2(sx + i * spacing - 25.0, by)
		node.pivot_offset = Vector2(25, 36)
		node.scale       = Vector2.ZERO
		node.modulate.a  = 0.0

		var lbl := Label.new()
		lbl.text = text[i]
		lbl.add_theme_font_size_override("font_size", 66)
		lbl.add_theme_color_override("font_color", COLORS[i % COLORS.size()])
		lbl.add_theme_constant_override("outline_size", 5)
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
		lbl.add_theme_constant_override("shadow_offset_x", 4)
		lbl.add_theme_constant_override("shadow_offset_y", 4)
		lbl.position = Vector2(2, 4)
		node.add_child(lbl)
		l_intro.add_child(node)
		i_letters.append(node)

	# Subtitle
	i_subtitle = Label.new()
	i_subtitle.text = "Tap. Fill. Blast."
	i_subtitle.add_theme_font_size_override("font_size", 28)
	i_subtitle.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 0.9))
	i_subtitle.position = Vector2(SW / 2.0 - 105, SH / 2.0 + 75)
	i_subtitle.modulate.a = 0.0
	l_intro.add_child(i_subtitle)

func _start_intro() -> void:
	i_elapsed = 0.0
	l_intro.modulate.a = 1.0
	for node in i_letters:
		node.scale = Vector2.ZERO; node.modulate.a = 0.0
	i_subtitle.modulate.a = 0.0

func _tick_intro(delta: float) -> void:
	i_elapsed += delta

	# Staggered letter animation
	for i in i_letters.size():
		var delay : float = i * 0.15
		var t     : float = clamp((i_elapsed - delay) / 0.42, 0.0, 1.0)
		var sc    : float = _bounce(t)
		i_letters[i].scale     = Vector2(sc, sc)
		i_letters[i].modulate.a = clamp(t * 2.2, 0.0, 1.0)
		if t >= 1.0:
			var by : float = i_letters[i].get_meta("by")
			i_letters[i].position.y = by + sin(i_elapsed * 2.1 + i * 0.65) * 7.0

	# Subtitle fade
	if i_elapsed > 1.9:
		i_subtitle.modulate.a = clamp((i_elapsed - 1.9) / 0.65, 0.0, 1.0)

	# Floating particles
	for p in i_particles:
		p.position.y -= delta * float(p.get_meta("spd"))
		p.position.x += sin(i_elapsed * float(p.get_meta("freq")) + float(p.get_meta("phase"))) * 0.5
		if p.position.y < -20: p.position.y = SH + 20
		p.modulate.a = 0.2 + sin(i_elapsed * float(p.get_meta("freq"))) * 0.1

	# Fade out near end
	if i_elapsed >= INTRO_DUR - 0.55:
		l_intro.modulate.a = clamp(1.0 - (i_elapsed - (INTRO_DUR - 0.55)) / 0.55, 0.0, 1.0)

	if i_elapsed >= INTRO_DUR:
		l_intro.modulate.a = 1.0
		_switch(State.MENU)

# ═════════════════════════════════════════════════════════════
# ██ MENU SCREEN
# ═════════════════════════════════════════════════════════════
func _build_menu_layer() -> void:
	l_menu = CanvasLayer.new(); l_menu.layer = 10
	add_child(l_menu)

	# Background
	var bg := ColorRect.new()
	bg.size = Vector2(SW, SH); bg.color = Color(0.04, 0.08, 0.28)
	l_menu.add_child(bg)

	# Animated background shapes (drawn by a child Node2D)
	var srng := RandomNumberGenerator.new(); srng.seed = 888
	m_shapes.clear()
	for _i in 16:
		m_shapes.append({
			"pos"  : Vector2(srng.randf_range(30, SW-30), srng.randf_range(30, SH-30)),
			"sz"   : srng.randf_range(26, 82),
			"col"  : COLORS[srng.randi() % COLORS.size()],
			"rot"  : srng.randf_range(0.0, TAU),
			"rspd" : srng.randf_range(-0.3, 0.3),
			"freq" : srng.randf_range(0.3, 1.1),
			"ph"   : srng.randf_range(0.0, TAU),
		})

	m_draw_node = _BgDrawer.new()
	(m_draw_node as _BgDrawer).main = self
	l_menu.add_child(m_draw_node)

	# Title letters
	var title := "BLOCKNOVA"
	var sp    : float = 47.0
	var sx    : float = (SW - (title.length()-1) * sp) / 2.0
	for i in title.length():
		var lbl := Label.new()
		lbl.text = title[i]
		lbl.add_theme_font_size_override("font_size", 52)
		lbl.add_theme_color_override("font_color", COLORS[i % COLORS.size()])
		lbl.add_theme_constant_override("outline_size", 5)
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
		lbl.add_theme_constant_override("shadow_offset_x", 3)
		lbl.add_theme_constant_override("shadow_offset_y", 3)
		lbl.position = Vector2(sx + i * sp - 18, SH * 0.18 + sin(i * 0.78) * 12.0)
		l_menu.add_child(lbl)

	# Tagline
	var tag := Label.new()
	tag.text = "Puzzle Block Game"
	tag.add_theme_font_size_override("font_size", 22)
	tag.add_theme_color_override("font_color", Color(0.6, 0.78, 1.0, 0.8))
	tag.position = Vector2(SW / 2.0 - 88, SH * 0.31)
	l_menu.add_child(tag)

	# PLAY button
	m_play_btn = Control.new()
	m_play_btn.size = Vector2(244, 76)
	m_play_btn.pivot_offset = Vector2(122, 38)
	m_play_btn.position = Vector2(SW / 2.0 - 122, SH * 0.52)
	var pb := ColorRect.new(); pb.size = Vector2(244, 76); pb.color = Color(0.18, 0.52, 0.92)
	m_play_btn.add_child(pb)
	var ph := ColorRect.new(); ph.size = Vector2(240, 30); ph.position = Vector2(2, 2)
	ph.color = Color(1, 1, 1, 0.13); m_play_btn.add_child(ph)
	var pl := Label.new(); pl.text = "▶  PLAY"
	pl.add_theme_font_size_override("font_size", 40)
	pl.add_theme_color_override("font_color", Color.WHITE)
	pl.add_theme_constant_override("outline_size", 3)
	pl.add_theme_color_override("font_outline_color", Color(0.05, 0.15, 0.45))
	pl.position = Vector2(38, 14)
	m_play_btn.add_child(pl)
	l_menu.add_child(m_play_btn)

	# Best score display
	var sp2 := ColorRect.new(); sp2.size = Vector2(280, 68)
	sp2.position = Vector2(SW/2.0 - 140, SH * 0.70); sp2.color = Color(0,0,0,0.35)
	l_menu.add_child(sp2)

	m_best_lbl = Label.new(); m_best_lbl.text = "BEST: 0"
	m_best_lbl.add_theme_font_size_override("font_size", 32)
	m_best_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.22))
	m_best_lbl.add_theme_constant_override("outline_size", 3)
	m_best_lbl.add_theme_color_override("font_outline_color", Color(0.4, 0.2, 0))
	m_best_lbl.position = Vector2(SW / 2.0 - 64, SH * 0.70 + 16)
	l_menu.add_child(m_best_lbl)

	# Version label
	var ver := Label.new(); ver.text = "v1.0"
	ver.add_theme_font_size_override("font_size", 16)
	ver.add_theme_color_override("font_color", Color(1,1,1,0.22))
	ver.position = Vector2(SW - 48, SH - 28); l_menu.add_child(ver)

func _start_menu() -> void:
	m_elapsed = 0.0
	if m_best_lbl: m_best_lbl.text = "BEST: %d" % g_best
	if m_play_btn:
		m_play_btn.scale = Vector2.ZERO
		var tw := create_tween()
		tw.tween_interval(0.2)
		tw.tween_property(m_play_btn, "scale", Vector2.ONE, 0.45) \
		  .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _tick_menu(delta: float) -> void:
	m_elapsed += delta
	if m_play_btn:
		m_play_btn.position.y = SH * 0.52 + sin(m_elapsed * 2.0) * 6.0
	if m_draw_node: m_draw_node.queue_redraw()

## Called by _BgDrawer to render animated bg shapes
func draw_menu_bg(canvas: CanvasItem) -> void:
	for sh in m_shapes:
		var rot : float = float(sh["rot"]) + m_elapsed * float(sh["rspd"])
		var dx  : float = sin(m_elapsed * float(sh["freq"]) + float(sh["ph"])) * 10.0
		var dy  : float = cos(m_elapsed * float(sh["freq"]) * 0.7 + float(sh["ph"])) * 7.0
		var pos : Vector2 = sh["pos"] + Vector2(dx, dy)
		var al  : float   = 0.07 + sin(m_elapsed * float(sh["freq"]) + float(sh["ph"])) * 0.035
		var sz  : float   = float(sh["sz"])
		canvas.draw_set_transform(pos, rot, Vector2.ONE)
		canvas.draw_rect(Rect2(-sz/2, -sz/2, sz, sz), Color((sh["col"] as Color).r, (sh["col"] as Color).g, (sh["col"] as Color).b, al))
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _in_menu(event: InputEvent) -> void:
	var pos := Vector2(-999, -999)
	if event is InputEventScreenTouch and event.pressed:
		pos = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	else:
		return
	if m_play_btn and Rect2(m_play_btn.position, m_play_btn.size).has_point(pos):
		var tw := create_tween()
		tw.tween_property(m_play_btn, "scale", Vector2(0.87, 0.87), 0.07)
		tw.tween_property(m_play_btn, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)
		tw.tween_interval(0.1)
		tw.tween_callback(func(): _switch(State.GAME))

# ═════════════════════════════════════════════════════════════
# ██ GAME SCREEN
# ═════════════════════════════════════════════════════════════
func _calc_layout() -> void:
	cell_sz     = min(float(SW - 38) / GRID_N, 52.0)
	grid_origin = Vector2((SW - GRID_N * cell_sz) / 2.0, 108.0)

func _build_game_layer() -> void:
	l_game = CanvasLayer.new(); l_game.layer = 5
	add_child(l_game)

	# Background
	var bg := ColorRect.new(); bg.size = Vector2(SW, SH)
	bg.color = Color(0.04, 0.08, 0.22); l_game.add_child(bg)

	# Grid panel
	var gp := ColorRect.new()
	gp.size     = Vector2(GRID_N * cell_sz + 14, GRID_N * cell_sz + 14)
	gp.position = grid_origin - Vector2(7, 7)
	gp.color    = Color(0, 0, 0, 0.48); l_game.add_child(gp)

	# Score bar
	var sbar := ColorRect.new(); sbar.size = Vector2(SW, 102); sbar.color = Color(0,0,0,0.42)
	l_game.add_child(sbar)

	var stitle := Label.new(); stitle.text = "SCORE"
	stitle.add_theme_font_size_override("font_size", 17)
	stitle.add_theme_color_override("font_color", Color(0.6, 0.75, 1.0, 0.75))
	stitle.position = Vector2(SW/2.0 - 26, 2); l_game.add_child(stitle)

	g_score_lbl = Label.new(); g_score_lbl.text = "0"
	g_score_lbl.add_theme_font_size_override("font_size", 44)
	g_score_lbl.add_theme_color_override("font_color", Color.WHITE)
	g_score_lbl.add_theme_constant_override("outline_size", 4)
	g_score_lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.2, 0.5))
	g_score_lbl.pivot_offset = Vector2(40, 22)
	g_score_lbl.position = Vector2(SW/2.0 - 40, 18); l_game.add_child(g_score_lbl)

	g_combo_lbl = Label.new(); g_combo_lbl.text = ""
	g_combo_lbl.add_theme_font_size_override("font_size", 26)
	g_combo_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.18))
	g_combo_lbl.add_theme_constant_override("outline_size", 3)
	g_combo_lbl.add_theme_color_override("font_outline_color", Color(0.5, 0.25, 0))
	g_combo_lbl.modulate.a = 0.0
	g_combo_lbl.position = Vector2(SW/2.0 - 80, 66); l_game.add_child(g_combo_lbl)

	# Tray separator and background
	var tsep := ColorRect.new(); tsep.size = Vector2(SW, 2); tsep.position = Vector2(0, 635)
	tsep.color = Color(0.3, 0.55, 0.9, 0.3); l_game.add_child(tsep)
	var tbg := ColorRect.new(); tbg.size = Vector2(SW, SH - 637); tbg.position = Vector2(0, 637)
	tbg.color = Color(0.02, 0.06, 0.18, 0.55); l_game.add_child(tbg)

	# Grid + ghost drawer
	g_drawer = _GridDrawer.new()
	(g_drawer as _GridDrawer).main = self
	l_game.add_child(g_drawer)

func _start_game() -> void:
	g_score   = 0
	g_combo   = 0
	g_elapsed = 0.0
	_init_grid()
	if g_score_lbl: g_score_lbl.text = "0"
	_spawn_pieces()

func _tick_game(delta: float) -> void:
	g_elapsed += delta
	if g_drawer: g_drawer.queue_redraw()

## Public — called by _GridDrawer
func draw_grid_and_ghost(canvas: CanvasItem) -> void:
	# Draw filled cells
	for r in GRID_N:
		for c in GRID_N:
			var rect := _crect(r, c)
			if grid[r][c] == null:
				canvas.draw_rect(rect.grow(-1.0), Color(1,1,1, 0.05 if (r+c)%2==0 else 0.09))
			else:
				_draw_cell(canvas, rect, grid[r][c] as Color)

	# Grid lines
	for r in GRID_N + 1:
		var y := grid_origin.y + r * cell_sz
		canvas.draw_line(Vector2(grid_origin.x, y), Vector2(grid_origin.x + GRID_N*cell_sz, y), Color(0.3,0.55,0.9,0.1), 1.0)
	for c in GRID_N + 1:
		var x := grid_origin.x + c * cell_sz
		canvas.draw_line(Vector2(x, grid_origin.y), Vector2(x, grid_origin.y + GRID_N*cell_sz), Color(0.3,0.55,0.9,0.1), 1.0)

	# Ghost
	if d_idx >= 0 and d_started and d_ghost.x >= 0 and d_ghost.y >= 0:
		var cells : Array = p_data[d_idx]["cells"]
		var col   : Color = p_data[d_idx]["color"]
		var valid : bool  = _can_place(cells, d_ghost)
		var gcol  : Color = col if valid else Color(0.9, 0.2, 0.2)
		var alpha : float = 0.70 if valid else 0.38
		var pulse : float = 0.08 * sin(g_elapsed * 9.0)
		for cell in cells:
			var gr : int = d_ghost.x + cell.x
			var gc : int = d_ghost.y + cell.y
			if gr >= 0 and gr < GRID_N and gc >= 0 and gc < GRID_N:
				var rect := _crect(gr, gc)
				_draw_cell(canvas, rect, Color(gcol.r, gcol.g, gcol.b, alpha))
				canvas.draw_rect(rect.grow(-1.0), Color(1,1,1, 0.28 + pulse), false, 2.0)

# ─────────────────── GRID LOGIC ─────────────────────────────
func _init_grid() -> void:
	grid = []
	for _r in GRID_N:
		var row := []; for _c in GRID_N: row.append(null)
		grid.append(row)

func _crect(r: int, c: int) -> Rect2:
	return Rect2(grid_origin.x + c * cell_sz, grid_origin.y + r * cell_sz, cell_sz, cell_sz)

func _world_to_cell(pos: Vector2) -> Vector2i:
	var local := pos - grid_origin
	return Vector2i(int(floor(local.y / cell_sz)), int(floor(local.x / cell_sz)))

func _can_place(cells: Array, gp: Vector2i) -> bool:
	for cell in cells:
		var r := gp.x + cell.x; var c := gp.y + cell.y
		if r < 0 or r >= GRID_N or c < 0 or c >= GRID_N: return false
		if grid[r][c] != null: return false
	return true

func _place_shape(cells: Array, gp: Vector2i, col: Color) -> void:
	for cell in cells: grid[gp.x + cell.x][gp.y + cell.y] = col

func _check_clears() -> void:
	var rc : Array[int] = []; var cc : Array[int] = []
	for r in GRID_N:
		var full := true
		for c in GRID_N:
			if grid[r][c] == null: full = false; break
		if full: rc.append(r)
	for c in GRID_N:
		var full := true
		for r in GRID_N:
			if grid[r][c] == null: full = false; break
		if full: cc.append(c)

	var total := rc.size() + cc.size()
	if total == 0: g_combo = 0; return

	for r in rc: for c in GRID_N: grid[r][c] = null
	for c in cc: for r in GRID_N: grid[r][c] = null

	g_combo += 1
	var pts : int = total * GRID_N * 10 * g_combo
	g_score += pts
	if g_score > g_best: g_best = g_score; _save_best()
	_update_score()
	_show_combo_pop(pts)
	_spawn_clear_fx(rc, cc)
	_clear_flash()

func _update_score() -> void:
	if not g_score_lbl: return
	g_score_lbl.text = "%d" % g_score
	var tw := create_tween()
	tw.tween_property(g_score_lbl, "scale", Vector2(1.3, 1.3), 0.07)
	tw.tween_property(g_score_lbl, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)

func _show_combo_pop(pts: int) -> void:
	if not g_combo_lbl: return
	g_combo_lbl.text     = "+%d  COMBO ×%d" % [pts, g_combo] if g_combo > 1 else "+%d" % pts
	g_combo_lbl.modulate.a = 1.0
	g_combo_lbl.position = Vector2(SW/2.0 - 80, 64)
	var tw := create_tween()
	tw.tween_property(g_combo_lbl, "position:y", 46.0, 0.35).set_trans(Tween.TRANS_QUAD)
	tw.tween_interval(0.55); tw.tween_property(g_combo_lbl, "modulate:a", 0.0, 0.3)

func _clear_flash() -> void:
	var fl := ColorRect.new(); fl.size = Vector2(SW, SH); fl.color = Color(1,1,1,0)
	l_game.add_child(fl)
	var tw := create_tween()
	tw.tween_property(fl, "color", Color(1,1,1,0.38), 0.08)
	tw.tween_property(fl, "color", Color(1,1,1,0.0),  0.24)
	tw.tween_callback(func(): fl.queue_free())

func _spawn_clear_fx(rows: Array[int], cols: Array[int]) -> void:
	for r in rows:
		for c in range(0, GRID_N, 2): _spawn_fx_particle(_crect(r,c).get_center())
	for c in cols:
		for r in range(0, GRID_N, 2): _spawn_fx_particle(_crect(r,c).get_center())

func _spawn_fx_particle(center: Vector2) -> void:
	var p := ColorRect.new()
	p.size  = Vector2(rng.randf_range(5, 13), rng.randf_range(5, 13))
	p.color = COLORS[rng.randi() % COLORS.size()]; p.position = center
	l_game.add_child(p)
	var tw := create_tween()
	tw.tween_property(p, "position", center + Vector2(rng.randf_range(-88,88), rng.randf_range(-88,88)), 0.52).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(p, "modulate:a", 0.0, 0.48)
	tw.tween_callback(func(): p.queue_free())

# ─────────────────── PIECES ─────────────────────────────────
func _spawn_pieces() -> void:
	for n in p_nodes:
		if is_instance_valid(n): n.queue_free()
	p_nodes.clear(); p_data.clear(); p_used.clear()

	var tx : Array[float] = [SW*0.18, SW*0.50, SW*0.82]
	for i in NUM_PIECES:
		var sid : int = rng.randi() % SHAPES.size()
		var cid : int = rng.randi() % COLORS.size()
		var pd := {"cells": SHAPES[sid].duplicate(), "color": COLORS[cid], "tpos": Vector2(tx[i], 704.0)}
		p_data.append(pd); p_used.append(false)

		var pn := _PieceNode.new()
		(pn as _PieceNode).setup(pd, cell_sz * 0.68)
		pn.position = pd["tpos"]; pn.scale = Vector2.ZERO; pn.modulate.a = 0.0
		l_game.add_child(pn); p_nodes.append(pn)

		var tw := create_tween()
		tw.tween_interval(i * 0.1)
		tw.parallel().tween_property(pn, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK)
		tw.parallel().tween_property(pn, "modulate:a", 1.0, 0.3)

func _check_gameover_condition() -> void:
	for i in NUM_PIECES:
		if p_used[i]: continue
		for r in GRID_N:
			for c in GRID_N:
				if _can_place(p_data[i]["cells"], Vector2i(r, c)): return
	call_deferred("_trigger_gameover")

func _trigger_gameover() -> void:
	_save_best()
	_setup_gameover(g_score, g_best)
	await get_tree().create_timer(0.45).timeout
	_switch(State.GAME_OVER)

func _place_flash(cells: Array, gp: Vector2i, col: Color) -> void:
	for cell in cells:
		var r := gp.x + cell.x; var c := gp.y + cell.y
		var fl := ColorRect.new()
		fl.size     = Vector2(cell_sz - 4, cell_sz - 4)
		fl.position = _crect(r, c).position + Vector2(2, 2)
		fl.color    = Color(min(col.r+0.35,1.0), min(col.g+0.35,1.0), min(col.b+0.35,1.0), 0.85)
		l_game.add_child(fl)
		var tw := create_tween()
		tw.tween_property(fl, "modulate:a", 0.0, 0.3)
		tw.tween_callback(func(): fl.queue_free())

# ─────────────────── GAME INPUT ─────────────────────────────
func _in_game(event: InputEvent) -> void:
	var pos      : Vector2 = Vector2.ZERO
	var released : bool    = false
	var moved    : bool    = false
	var is_input : bool    = false
	var eid      : int     = 0

	if event is InputEventScreenTouch:
		pos = event.position; released = not event.pressed; is_input = true; eid = event.index
	elif event is InputEventScreenDrag:
		pos = event.position; moved = true; is_input = true; eid = event.index
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position; released = not event.pressed; is_input = true
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pos = event.position; moved = true; is_input = true

	if not is_input: return

	# Start drag
	if not moved and not released and d_idx == -1:
		for i in NUM_PIECES:
			if p_used[i]: continue
			if _piece_hit(i, pos):
				d_idx = i; d_touch_id = eid
				d_press_pos = pos; d_started = false
				p_nodes[i].scale = Vector2(1.08, 1.08)
				break

	# Move drag
	if d_idx >= 0 and (moved or (not released)):
		if not d_started and pos.distance_to(d_press_pos) > D_THRESH:
			d_started = true

		if d_started:
			var bounds := _shape_bounds(p_data[d_idx]["cells"])
			var pcs    := cell_sz * 0.68
			var lift   := Vector2(0, -cell_sz * 1.65)
			p_nodes[d_idx].position = pos + lift

			var half := Vector2(bounds.y * pcs * 0.5, bounds.x * pcs * 0.5)
			d_ghost = _world_to_cell(pos + lift + half)

	# Release
	if released and d_idx >= 0:
		if d_started:
			_try_drop()
		else:
			p_nodes[d_idx].position = p_data[d_idx]["tpos"]
			p_nodes[d_idx].scale    = Vector2.ONE
		d_idx = -1; d_started = false; d_ghost = Vector2i(-1, -1)
		if g_drawer: g_drawer.queue_redraw()

func _piece_hit(idx: int, pos: Vector2) -> bool:
	var pn    := p_nodes[idx]
	var bounds := _shape_bounds(p_data[idx]["cells"])
	var pcs    := cell_sz * 0.68
	var hw     := bounds.y * pcs / 2.0 + 16.0
	var hh     := bounds.x * pcs / 2.0 + 16.0
	var local  := pos - pn.position
	return abs(local.x) <= hw and abs(local.y) <= hh

func _try_drop() -> void:
	var gp    := d_ghost
	var cells : Array = p_data[d_idx]["cells"]
	var col   : Color = p_data[d_idx]["color"]

	if gp.x >= 0 and gp.y >= 0 and _can_place(cells, gp):
		_place_shape(cells, gp, col)
		_place_flash(cells, gp, col)
		p_used[d_idx] = true
		p_nodes[d_idx].scale = Vector2.ZERO; p_nodes[d_idx].modulate.a = 0.0
		_check_clears()
		var all := true
		for u in p_used: if not u: all = false; break
		if all: _spawn_pieces()
		else:   _check_gameover_condition()
	else:
		# Invalid — bounce back
		var pn   := p_nodes[d_idx]
		var tpos : Vector2 = p_data[d_idx]["tpos"]
		var tw   := create_tween()
		tw.tween_property(pn, "position", tpos, 0.3).set_trans(Tween.TRANS_BACK)
		tw.parallel().tween_property(pn, "scale", Vector2.ONE, 0.22)

# ─────────────────── DRAW CELL HELPER ───────────────────────
func _draw_cell(canvas: CanvasItem, rect: Rect2, col: Color) -> void:
	var s := rect.grow(-2.0)
	canvas.draw_rect(s, col)
	canvas.draw_rect(Rect2(s.position, Vector2(s.size.x, 5)), Color(1,1,1,0.22))
	canvas.draw_rect(Rect2(s.position, Vector2(5, s.size.y)), Color(1,1,1,0.14))
	canvas.draw_rect(Rect2(s.position + Vector2(0, s.size.y-5), Vector2(s.size.x,5)), Color(0,0,0,0.28))
	canvas.draw_rect(s, col.darkened(0.36), false, 1.5)

# ═════════════════════════════════════════════════════════════
# ██ GAME OVER SCREEN
# ═════════════════════════════════════════════════════════════
func _build_gameover_layer() -> void:
	l_gameover = CanvasLayer.new(); l_gameover.layer = 30
	add_child(l_gameover)

	# Dim overlay
	var dim := ColorRect.new(); dim.size = Vector2(SW, SH)
	dim.color = Color(0.0, 0.02, 0.08, 0.83); l_gameover.add_child(dim)

	# Panel
	go_panel = Control.new(); go_panel.size = Vector2(372, 338)
	go_panel.position = Vector2(SW/2.0 - 186, SH*0.24)
	go_panel.pivot_offset = Vector2(186, 169); l_gameover.add_child(go_panel)

	var pb := ColorRect.new(); pb.size = Vector2(372, 338); pb.color = Color(0.06, 0.12, 0.30)
	go_panel.add_child(pb)
	var pb2 := ColorRect.new(); pb2.size = Vector2(368, 334); pb2.position = Vector2(2, 2)
	pb2.color = Color(0.08, 0.16, 0.38); go_panel.add_child(pb2)
	var top_bar := ColorRect.new(); top_bar.size = Vector2(372, 5); top_bar.color = Color(0.95, 0.32, 0.32)
	go_panel.add_child(top_bar)

	var go_t := Label.new(); go_t.text = "GAME OVER"
	go_t.add_theme_font_size_override("font_size", 46)
	go_t.add_theme_color_override("font_color", Color(0.95, 0.32, 0.32))
	go_t.add_theme_constant_override("outline_size", 4)
	go_t.add_theme_color_override("font_outline_color", Color(0.22, 0.0, 0.0))
	go_t.position = Vector2(22, 14); go_panel.add_child(go_t)

	var divl := ColorRect.new(); divl.size = Vector2(332, 2); divl.position = Vector2(20, 84)
	divl.color = Color(0.3, 0.55, 0.9, 0.3); go_panel.add_child(divl)

	var stit := Label.new(); stit.text = "SCORE"
	stit.add_theme_font_size_override("font_size", 21)
	stit.add_theme_color_override("font_color", Color(0.65, 0.78, 0.98))
	stit.position = Vector2(140, 94); go_panel.add_child(stit)

	go_score_lbl = Label.new(); go_score_lbl.text = "0"
	go_score_lbl.add_theme_font_size_override("font_size", 70)
	go_score_lbl.add_theme_color_override("font_color", Color.WHITE)
	go_score_lbl.add_theme_constant_override("outline_size", 5)
	go_score_lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.28, 0.65))
	go_score_lbl.position = Vector2(106, 116); go_panel.add_child(go_score_lbl)

	go_best_lbl = Label.new(); go_best_lbl.text = "BEST: 0"
	go_best_lbl.add_theme_font_size_override("font_size", 28)
	go_best_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.22))
	go_best_lbl.add_theme_constant_override("outline_size", 3)
	go_best_lbl.add_theme_color_override("font_outline_color", Color(0.4, 0.2, 0))
	go_best_lbl.position = Vector2(110, 200); go_panel.add_child(go_best_lbl)

	go_newbest = Label.new(); go_newbest.text = "★  NEW BEST!  ★"
	go_newbest.add_theme_font_size_override("font_size", 24)
	go_newbest.add_theme_color_override("font_color", Color(0.95, 0.88, 0.18))
	go_newbest.add_theme_constant_override("outline_size", 3)
	go_newbest.add_theme_color_override("font_outline_color", Color(0.5, 0.28, 0))
	go_newbest.position = Vector2(68, 244); go_newbest.modulate.a = 0.0
	go_panel.add_child(go_newbest)

	# Retry
	go_retry_btn = Control.new(); go_retry_btn.size = Vector2(262, 68)
	go_retry_btn.pivot_offset = Vector2(131, 34)
	go_retry_btn.position = Vector2(SW/2.0 - 131, SH*0.68); l_gameover.add_child(go_retry_btn)
	var rb := ColorRect.new(); rb.size = Vector2(262,68); rb.color = Color(0.18,0.68,0.35)
	go_retry_btn.add_child(rb)
	var rh := ColorRect.new(); rh.size = Vector2(258, 28); rh.position = Vector2(2,2)
	rh.color = Color(1,1,1,0.13); go_retry_btn.add_child(rh)
	var rl := Label.new(); rl.text = "▶  PLAY AGAIN"
	rl.add_theme_font_size_override("font_size", 30); rl.add_theme_color_override("font_color", Color.WHITE)
	rl.add_theme_constant_override("outline_size", 3)
	rl.add_theme_color_override("font_outline_color", Color(0.05,0.25,0.1))
	rl.position = Vector2(28, 16); go_retry_btn.add_child(rl)

	# Menu
	go_menu_btn = Control.new(); go_menu_btn.size = Vector2(262, 68)
	go_menu_btn.pivot_offset = Vector2(131, 34)
	go_menu_btn.position = Vector2(SW/2.0 - 131, SH*0.79); l_gameover.add_child(go_menu_btn)
	var mb := ColorRect.new(); mb.size = Vector2(262,68); mb.color = Color(0.18,0.35,0.72)
	go_menu_btn.add_child(mb)
	var mh := ColorRect.new(); mh.size = Vector2(258,28); mh.position = Vector2(2,2)
	mh.color = Color(1,1,1,0.10); go_menu_btn.add_child(mh)
	var ml := Label.new(); ml.text = "⌂  MAIN MENU"
	ml.add_theme_font_size_override("font_size", 30); ml.add_theme_color_override("font_color", Color.WHITE)
	ml.add_theme_constant_override("outline_size", 3)
	ml.add_theme_color_override("font_outline_color", Color(0.05,0.1,0.3))
	ml.position = Vector2(28, 16); go_menu_btn.add_child(ml)

func _setup_gameover(score: int, best: int) -> void:
	go_elapsed = 0.0
	go_score_lbl.text = "0"; go_best_lbl.text = "BEST: %d" % best
	go_newbest.modulate.a = 0.0

	go_panel.scale = Vector2(0.2, 0.2); go_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(0.12)
	tw.tween_property(go_panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(go_panel, "modulate:a", 1.0, 0.32)
	tw.tween_method(func(v: float): go_score_lbl.text = "%d" % int(v), 0.0, float(score), 1.0).set_trans(Tween.TRANS_QUAD)
	if score >= best and score > 0:
		tw.tween_property(go_newbest, "modulate:a", 1.0, 0.3)
		var ptw := create_tween().set_loops()
		ptw.tween_interval(0.9); ptw.tween_property(go_newbest, "modulate:a", 0.22, 0.5)
		ptw.tween_property(go_newbest, "modulate:a", 1.0, 0.5)

	go_retry_btn.scale = Vector2.ZERO; go_menu_btn.scale = Vector2.ZERO
	var btw := create_tween()
	btw.tween_interval(0.58)
	btw.tween_property(go_retry_btn, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK)
	btw.tween_interval(0.08)
	btw.tween_property(go_menu_btn, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK)

func _tick_gameover(delta: float) -> void:
	go_elapsed += delta
	if go_retry_btn: go_retry_btn.position.y = SH*0.68 + sin(go_elapsed*2.0)*5.0
	if go_menu_btn:  go_menu_btn.position.y  = SH*0.79 + sin(go_elapsed*2.0+1.0)*5.0

func _in_gameover(event: InputEvent) -> void:
	var pos := Vector2(-999, -999)
	if event is InputEventScreenTouch and event.pressed: pos = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: pos = event.position
	else: return

	if go_retry_btn and Rect2(go_retry_btn.position, go_retry_btn.size).has_point(pos):
		var tw := create_tween()
		tw.tween_property(go_retry_btn, "scale", Vector2(0.88,0.88), 0.07)
		tw.tween_property(go_retry_btn, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)
		tw.tween_interval(0.1); tw.tween_callback(func(): _switch(State.GAME))
	elif go_menu_btn and Rect2(go_menu_btn.position, go_menu_btn.size).has_point(pos):
		var tw := create_tween()
		tw.tween_property(go_menu_btn, "scale", Vector2(0.88,0.88), 0.07)
		tw.tween_property(go_menu_btn, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)
		tw.tween_interval(0.1); tw.tween_callback(func(): _switch(State.MENU))

# ═════════════════════════════════════════════════════════════
# UTILITIES
# ═════════════════════════════════════════════════════════════
func _shape_bounds(cells: Array) -> Vector2i:
	var mr := 0; var mc := 0
	for cell in cells: mr = max(mr, int(cell.x)); mc = max(mc, int(cell.y))
	return Vector2i(mr+1, mc+1)

func _bounce(t: float) -> float:
	## Overshoot bounce easing
	if t <= 0.0: return 0.0
	if t >= 1.0: return 1.0
	var c1 := 1.70158; var c3 := c1 + 1.0
	return 1.0 + c3 * pow(t-1.0, 3.0) + c1 * pow(t-1.0, 2.0)

func _save_best() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "best", g_best); cfg.save(SAVE_PATH)

func _load_best() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK: g_best = cfg.get_value("scores", "best", 0)

# ═════════════════════════════════════════════════════════════
# INNER CLASS: _GridDrawer — dedicated canvas for grid/ghost
# ═════════════════════════════════════════════════════════════
class _GridDrawer extends Node2D:
	var main : Node2D = null
	func _draw() -> void:
		if main: main.draw_grid_and_ghost(self)

# ═════════════════════════════════════════════════════════════
# INNER CLASS: _BgDrawer — animated menu background shapes
# ═════════════════════════════════════════════════════════════
class _BgDrawer extends Node2D:
	var main : Node2D = null
	func _draw() -> void:
		if main: main.draw_menu_bg(self)

# ═════════════════════════════════════════════════════════════
# INNER CLASS: _PieceNode — renders a tray piece procedurally
# ═════════════════════════════════════════════════════════════
class _PieceNode extends Node2D:
	var pdata    : Dictionary = {}
	var piece_cs : float = 32.0

	func setup(data: Dictionary, cs: float) -> void:
		pdata = data; piece_cs = cs; queue_redraw()

	func _draw() -> void:
		var cells : Array = pdata.get("cells", [])
		var col   : Color = pdata.get("color", Color.WHITE)
		var mr := 0; var mc := 0
		for cell in cells: mr = max(mr, int(cell.x)); mc = max(mc, int(cell.y))
		var off := Vector2(-(mc+1)*piece_cs/2.0, -(mr+1)*piece_cs/2.0)
		for cell in cells:
			var s := Rect2(off.x+cell.y*piece_cs, off.y+cell.x*piece_cs, piece_cs, piece_cs).grow(-2.0)
			draw_rect(s, col)
			draw_rect(Rect2(s.position, Vector2(s.size.x, 5)), Color(1,1,1,0.22))
			draw_rect(Rect2(s.position, Vector2(5, s.size.y)), Color(1,1,1,0.14))
			draw_rect(Rect2(s.position+Vector2(0,s.size.y-5), Vector2(s.size.x,5)), Color(0,0,0,0.28))
			draw_rect(s, col.darkened(0.38), false, 1.5)
