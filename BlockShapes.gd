## BlockShapes.gd
## Defines all Tetromino/Block Blast style shapes
## Each shape is an array of Vector2i cell offsets from origin (0,0)
## Used by GameScreen to generate random pieces

class_name BlockShapes
extends RefCounted

# ─────────────────────────────────────────────
# SHAPE DEFINITIONS  (row, col offsets)
# ─────────────────────────────────────────────
const SHAPES : Array = [
	# 1x1
	[[Vector2i(0,0)]],

	# 1x2 horizontal
	[[Vector2i(0,0), Vector2i(0,1)]],

	# 1x3 horizontal
	[[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2)]],

	# 1x4 horizontal
	[[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)]],

	# 1x5 horizontal
	[[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3), Vector2i(0,4)]],

	# 2x1 vertical
	[[Vector2i(0,0), Vector2i(1,0)]],

	# 3x1 vertical
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)]],

	# 4x1 vertical
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)]],

	# 5x1 vertical
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0)]],

	# 2x2 square
	[[Vector2i(0,0), Vector2i(0,1), Vector2i(1,0), Vector2i(1,1)]],

	# 3x3 square
	[[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2),
	  Vector2i(1,0), Vector2i(1,1), Vector2i(1,2),
	  Vector2i(2,0), Vector2i(2,1), Vector2i(2,2)]],

	# L-shape
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(2,1)]],

	# L-shape reversed
	[[Vector2i(0,0), Vector2i(0,1), Vector2i(1,0), Vector2i(2,0)]],

	# L-shape mirrored
	[[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)]],

	# L-shape mirrored reversed
	[[Vector2i(0,1), Vector2i(1,1), Vector2i(2,0), Vector2i(2,1)]],

	# T-shape
	[[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,1)]],

	# T-shape rotated 90
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,0)]],

	# T-shape rotated 180
	[[Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), Vector2i(1,2)]],

	# T-shape rotated 270
	[[Vector2i(0,0), Vector2i(0,1), Vector2i(1,0), Vector2i(2,0)]],

	# S-shape
	[[Vector2i(0,1), Vector2i(0,2), Vector2i(1,0), Vector2i(1,1)]],

	# Z-shape
	[[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(1,2)]],

	# S vertical
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1)]],

	# Z vertical
	[[Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), Vector2i(2,0)]],

	# Corner 2x2 (3 cells)
	[[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)]],
	[[Vector2i(0,0), Vector2i(0,1), Vector2i(1,0)]],
	[[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)]],
	[[Vector2i(0,1), Vector2i(1,0), Vector2i(1,1)]],
]

# Color palette for blocks
const BLOCK_COLORS : Array = [
	Color(0.95, 0.32, 0.32),   # Red
	Color(0.95, 0.62, 0.18),   # Orange
	Color(0.95, 0.88, 0.18),   # Yellow
	Color(0.28, 0.82, 0.38),   # Green
	Color(0.22, 0.68, 0.95),   # Blue
	Color(0.52, 0.32, 0.95),   # Purple
	Color(0.95, 0.32, 0.75),   # Pink
	Color(0.25, 0.88, 0.78),   # Cyan
	Color(0.95, 0.52, 0.28),   # Deep Orange
]

# ─────────────────────────────────────────────
# STATIC HELPERS
# ─────────────────────────────────────────────

## Returns a random shape (array of Vector2i offsets) with a random color
static func get_random(rng: RandomNumberGenerator) -> Dictionary:
	var idx    : int   = rng.randi() % SHAPES.size()
	var c_idx  : int   = rng.randi() % BLOCK_COLORS.size()
	return {
		"cells" : SHAPES[idx][0].duplicate(),
		"color" : BLOCK_COLORS[c_idx],
		"shape_idx" : idx,
	}

## Returns bounding size of a shape (rows, cols)
static func get_bounds(cells: Array) -> Vector2i:
	var max_r : int = 0
	var max_c : int = 0
	for cell in cells:
		max_r = max(max_r, cell.x)
		max_c = max(max_c, cell.y)
	return Vector2i(max_r + 1, max_c + 1)
