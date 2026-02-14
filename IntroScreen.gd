## IntroScreen.gd
## 5-second animated intro screen for BLOCKNOVA
## Features bubble-style letters with bounce/scale animations
## Loaded and managed by Main.gd

class_name IntroScreen
extends Node2D

signal intro_done

const SCREEN_W : int = 480
const SCREEN_H : int = 854
const DURATION : float = 5.0

# Letter nodes and animation state
var letter_nodes  : Array[Node2D] = []
var letter_chars  := "BLOCKNOVA"
var elapsed       : float = 0.0
var anim_started  : bool  = false
var particles     : Array[Node2D] = []

# Color palette
var bg_color_top    := Color(0.04, 0.08, 0.28)
var bg_color_bottom := Color(0.08, 0.22, 0.52)

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
	_build_background()
	_build_letters()
	_build_subtitle()
	_build_particles()

func start() -> void:
	elapsed = 0.0
	anim_started = true
	visible = true
	# Reset letter transforms
	for i in letter_nodes.size():
		letter_nodes[i].scale = Vector2.ZERO
		letter_nodes[i].modulate.a = 0.0

func _process(delta: float) -> void:
	if not anim_started:
		return
	elapsed += delta

	# Animate letters staggered
	for i in letter_nodes.size():
		var delay  : float = i * 0.18
		var t      : float = clamp((elapsed - delay) / 0.45, 0.0, 1.0)
		var bounce : float = _bounce_ease(t)
		letter_nodes[i].scale = Vector2(bounce, bounce)
		letter_nodes[i].modulate.a = clamp(t * 2.0, 0.0, 1.0)

		# Continuous gentle bob after appearing
		if t >= 1.0:
			var bob := sin(elapsed * 2.0 + i * 0.7) * 6.0
			letter_nodes[i].position.y = _letter_base_y(i) + bob

	# Animate floating particles
	for p in particles:
		p.position.y -= delta * p.get_meta("speed")
		p.position.x += sin(elapsed * p.get_meta("freq") + p.get_meta("phase")) * 0.5
		p.modulate.a = 0.3 + sin(elapsed * p.get_meta("freq")) * 0.2
		if p.position.y < -30:
			p.position.y = SCREEN_H + 30

	# Background color shift
	queue_redraw()

	if elapsed >= DURATION:
		anim_started = false
		intro_done.emit()

func _draw() -> void:
	# Gradient background
	var t_shift : float = sin(elapsed * 0.3) * 0.04
	var c_top   := bg_color_top.lerp(Color(0.05, 0.12, 0.38), t_shift + 0.5)
	var c_bot   := bg_color_bottom.lerp(Color(0.12, 0.3, 0.65), t_shift + 0.5)
	for y in range(0, SCREEN_H, 4):
		var frac := float(y) / SCREEN_H
		var col  := c_top.lerp(c_bot, frac)
		draw_line(Vector2(0, y), Vector2(SCREEN_W, y), col, 4)

# ─────────────────────────────────────────────
# BUILDERS
# ─────────────────────────────────────────────
func _build_background() -> void:
	pass  # Drawn in _draw()

func _build_letters() -> void:
	letter_nodes.clear()
	var total_w  : float = 0.0
	var font_sz  : int   = 72
	var spacing  : float = 64.0

	for i in letter_chars.length():
		var lbl := Label.new()
		lbl.text = letter_chars[i]
		lbl.add_theme_font_size_override("font_size", font_sz)
		lbl.add_theme_color_override("font_color", letter_colors[i % letter_colors.size()])
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		lbl.add_theme_constant_override("shadow_offset_x", 3)
		lbl.add_theme_constant_override("shadow_offset_y", 3)
		lbl.add_theme_constant_override("shadow_outline_size", 2)
		total_w += spacing

	var start_x : float = (SCREEN_W - (letter_chars.length() - 1) * spacing) / 2.0

	for i in letter_chars.length():
		var wrapper := Node2D.new()
		wrapper.position = Vector2(start_x + i * spacing, _letter_base_y(i))
		wrapper.scale    = Vector2.ZERO

		var lbl := Label.new()
		lbl.text = letter_chars[i]
		lbl.add_theme_font_size_override("font_size", 72)
		lbl.add_theme_color_override("font_color", letter_colors[i % letter_colors.size()])
		lbl.add_theme_constant_override("shadow_offset_x", 4)
		lbl.add_theme_constant_override("shadow_offset_y", 4)
		lbl.add_theme_constant_override("outline_size", 4)
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))

		# Center the label
		lbl.position = Vector2(-22, -40)
		wrapper.add_child(lbl)

		# Colored circle behind letter (bubble effect)
		var bubble := ColorRect.new()
		bubble.size = Vector2(52, 52)
		bubble.position = Vector2(-26, -34)
		bubble.color = letter_colors[i % letter_colors.size()].darkened(0.4)
		bubble.modulate = Color(1, 1, 1, 0.3)
		# Make it appear round-ish by adding it behind
		wrapper.add_child(bubble)
		wrapper.move_child(bubble, 0)

		add_child(wrapper)
		letter_nodes.append(wrapper)

func _build_subtitle() -> void:
	var sub := Label.new()
	sub.text = "Tap. Fill. Blast."
	sub.add_theme_font_size_override("font_size", 26)
	sub.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 0.9))
	sub.add_theme_constant_override("shadow_offset_x", 2)
	sub.add_theme_constant_override("shadow_offset_y", 2)
	sub.position = Vector2(SCREEN_W / 2.0 - 100, SCREEN_H / 2.0 + 60)
	add_child(sub)

	# Animate subtitle fade in
	var tw := create_tween()
	tw.tween_interval(1.8)
	sub.modulate.a = 0.0
	tw.tween_property(sub, "modulate:a", 1.0, 0.8)

func _build_particles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _i in 20:
		var p := ColorRect.new()
		var sz := rng.randf_range(4, 12)
		p.size = Vector2(sz, sz)
		p.color = letter_colors[rng.randi() % letter_colors.size()]
		p.modulate.a = 0.3
		p.position = Vector2(rng.randf_range(0, SCREEN_W), rng.randf_range(0, SCREEN_H))
		p.set_meta("speed", rng.randf_range(20, 80))
		p.set_meta("freq", rng.randf_range(0.5, 2.5))
		p.set_meta("phase", rng.randf_range(0, TAU))
		add_child(p)
		particles.append(p)

# ─────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────
func _letter_base_y(i: int) -> float:
	return SCREEN_H / 2.0 - 40.0 + sin(i * 0.8) * 18.0

func _bounce_ease(t: float) -> float:
	# Overshoot bounce easing
	if t <= 0.0:
		return 0.0
	if t >= 1.0:
		return 1.0
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3) + c1 * pow(t - 1.0, 2)
