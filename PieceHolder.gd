## PieceHolder.gd
## Draggable block piece displayed in the bottom tray
## Renders itself procedurally with no assets
## Emits drag_started when the player begins dragging

class_name PieceHolder
extends Node2D

signal drag_started(touch_pos: Vector2)

var shape_data  : Dictionary = {}   # { cells, color, shape_idx }
var cell_size   : float      = 34.0
var used        : bool       = false
var is_dragging : bool       = false
var base_pos    : Vector2    = Vector2.ZERO

# Touch tracking
var touch_id    : int = -1
var press_pos   : Vector2 = Vector2.ZERO
const DRAG_THRESHOLD : float = 8.0

func init(data: Dictionary, pos: Vector2, c_size: float) -> void:
	shape_data = data
	base_pos   = pos
	cell_size  = c_size
	position   = pos

func _ready() -> void:
	pass

func _draw() -> void:
	if used:
		return
	var cells : Array = shape_data.get("cells", [])
	var col   : Color = shape_data.get("color", Color.WHITE)

	# Calculate center offset so shape appears centered in tray slot
	var bounds : Vector2i = BlockShapes.get_bounds(cells)
	var offset := Vector2(
		-bounds.y * cell_size / 2.0,
		-bounds.x * cell_size / 2.0
	)

	for cell in cells:
		var rect := Rect2(
			offset.x + cell.y * cell_size,
			offset.y + cell.x * cell_size,
			cell_size, cell_size
		)
		_draw_block(rect, col)

func _draw_block(rect: Rect2, col: Color) -> void:
	var shrunk := rect.grow(-2.0)
	# Main fill
	draw_rect(shrunk, col)
	# Top-left highlight
	draw_rect(Rect2(shrunk.position, Vector2(shrunk.size.x, 5)), Color(1, 1, 1, 0.22))
	draw_rect(Rect2(shrunk.position, Vector2(5, shrunk.size.y)), Color(1, 1, 1, 0.15))
	# Bottom-right shadow
	draw_rect(Rect2(shrunk.position + Vector2(0, shrunk.size.y - 5),
	                Vector2(shrunk.size.x, 5)), Color(0, 0, 0, 0.28))
	# Outline
	draw_rect(shrunk, col.darkened(0.35), false, 1.5)

func _input(event: InputEvent) -> void:
	if used:
		return

	# Handle touch
	if event is InputEventScreenTouch:
		if event.pressed:
			if touch_id == -1 and _hit_test(event.position):
				touch_id  = event.index
				press_pos = event.position
				get_viewport().set_input_as_handled()
		else:
			if event.index == touch_id:
				touch_id = -1
				if is_dragging:
					is_dragging = false

	elif event is InputEventScreenDrag:
		if event.index == touch_id:
			var dist := event.position.distance_to(press_pos)
			if not is_dragging and dist > DRAG_THRESHOLD:
				is_dragging = true
				drag_started.emit(event.position)
				get_viewport().set_input_as_handled()

	# Mouse fallback for desktop testing
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _hit_test(event.position):
				press_pos = event.position
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_dragging:
			var dist := event.position.distance_to(press_pos)
			if dist > DRAG_THRESHOLD:
				is_dragging = true
				drag_started.emit(event.position)
				get_viewport().set_input_as_handled()

func _hit_test(pos: Vector2) -> bool:
	# Check if pos is within the piece's bounding box in world space
	var cells : Array = shape_data.get("cells", [])
	var bounds : Vector2i = BlockShapes.get_bounds(cells)
	var half_w := bounds.y * cell_size / 2.0 + 10.0
	var half_h := bounds.x * cell_size / 2.0 + 10.0
	var local  := pos - global_position
	return abs(local.x) <= half_w and abs(local.y) <= half_h

func start_drag() -> void:
	is_dragging = true
	# Visual: slight scale up
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1)

func cancel_drag() -> void:
	is_dragging = false
	# Bounce back to base position
	var tw := create_tween()
	tw.tween_property(self, "position", base_pos, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "scale", Vector2.ONE, 0.2)

func mark_used() -> void:
	used = true
	# Fade and shrink
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(0.0, 0.0), 0.25).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	queue_redraw()
