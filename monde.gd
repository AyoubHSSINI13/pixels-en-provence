@tool
extends Node2D

const TILE := 16

# --- Atlas coords des tuiles bloquantes (dans gentle_forest.png) ---
const CLIFF_TILES := [Vector2i(1,1), Vector2i(2,1)]
const WATER_TILES := [Vector2i(1,9), Vector2i(2,9), Vector2i(4,9)]

var _atlas_source: TileSetAtlasSource

# Palettes selon l'heure
const PALETTE_JOUR  := "res://assets/tilemap/gentle_forest/gentle_forest.png"       # v01
const PALETTE_SOIR  := "res://assets/tilemap/gentle_forest/gentle_forest_v02.png"   # v02
const PALETTE_NUIT  := "res://assets/tilemap/gentle_forest/gentle_forest_v03.png"   # v03

var _current_palette := ""


func _ready() -> void:
	_atlas_source = $sol.tile_set.get_source(0) as TileSetAtlasSource
	_build_water_overlay()
	if Engine.is_editor_hint():
		return
	_build_collision()
	_update_navigation()
	_apply_palette_for_hour(GameData.heure)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_apply_palette_for_hour(GameData.heure)


func _apply_palette_for_hour(h: float) -> void:
	var palette: String
	if h >= 6.0 and h < 17.0:
		palette = PALETTE_JOUR       # 6h - 17h : jour
	elif h >= 17.0 and h < 21.0:
		palette = PALETTE_SOIR       # 17h - 21h : fin d'aprem / coucher
	else:
		palette = PALETTE_NUIT       # 21h - 6h : nuit

	if palette == _current_palette:
		return
	_current_palette = palette
	_atlas_source.texture = load(palette)


func _is_blocking(cell: Vector2i) -> bool:
	var coords := ($sol as TileMapLayer).get_cell_atlas_coords(cell)
	return coords in CLIFF_TILES or coords in WATER_TILES


func _is_water(cell: Vector2i) -> bool:
	var coords := ($sol as TileMapLayer).get_cell_atlas_coords(cell)
	return coords in WATER_TILES


# =================================================================
# OVERLAY EAU — sparkles animes sur le lac
# =================================================================
func _build_water_overlay() -> void:
	var old := get_node_or_null("WaterOverlay")
	if old:
		old.queue_free()
	var root := Node2D.new()
	root.name = "WaterOverlay"
	root.z_index = 1
	add_child(root)


# =================================================================
# COLLISION — murs sur falaise et eau
# =================================================================
func _build_collision() -> void:
	var walls := Node2D.new()
	walls.name = "Walls"
	add_child(walls)

	var sol := $sol as TileMapLayer
	var rect := sol.get_used_rect()
	var x0 := rect.position.x
	var y0 := rect.position.y
	var x1 := rect.position.x + rect.size.x
	var y1 := rect.position.y + rect.size.y

	for y in range(y0, y1):
		var start_x := -1
		for x in range(x0, x1 + 1):
			var bloque := x < x1 and _is_blocking(Vector2i(x, y))
			if bloque and start_x == -1:
				start_x = x
			elif not bloque and start_x != -1:
				_add_wall(walls, start_x, y, x - start_x, 1)
				start_x = -1


func _add_wall(parent: Node2D, tx: int, ty: int, w: int, h: int) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2((tx + w * 0.5) * TILE, (ty + h * 0.5) * TILE)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w * TILE, h * TILE)
	shape.shape = rect
	body.add_child(shape)
	parent.add_child(body)


# =================================================================
# NAVIGATION — polygone avec trou pour la rivière/lac
# =================================================================
func _update_navigation() -> void:
	var nav: NavigationRegion2D = $NavigationRegion2D
	var sol := $sol as TileMapLayer
	var rect := sol.get_used_rect()
	var poly := NavigationPolygon.new()

	# Contour extérieur basé sur la zone utilisée de la TileMap
	var cx := (rect.position.x + rect.size.x * 0.5) * TILE
	var cy := (rect.position.y + rect.size.y * 0.5) * TILE
	var rx := (rect.size.x * 0.5 - 3) * TILE * 0.95
	var ry := (rect.size.y * 0.5 - 3) * TILE * 0.95
	var outer := PackedVector2Array()
	for i in 24:
		var angle := i * TAU / 24.0
		outer.append(Vector2(cx + rx * cos(angle), cy + ry * sin(angle)))

	var source_geo := NavigationMeshSourceGeometryData2D.new()
	source_geo.add_traversable_outline(outer)
	for outline in _find_water_outlines():
		source_geo.add_obstruction_outline(outline)

	NavigationServer2D.bake_from_source_geometry_data(poly, source_geo)
	nav.navigation_polygon = poly


func _find_water_outlines() -> Array[PackedVector2Array]:
	var sol := $sol as TileMapLayer
	var rect := sol.get_used_rect()
	var x0 := rect.position.x
	var y0 := rect.position.y
	var x1 := rect.position.x + rect.size.x
	var y1 := rect.position.y + rect.size.y

	var visited := {}
	var outlines: Array[PackedVector2Array] = []

	for y in range(y0, y1):
		for x in range(x0, x1):
			var cell := Vector2i(x, y)
			if not _is_water(cell) or visited.has(cell):
				continue

			# Flood fill pour trouver tous les tiles de cette zone d'eau
			var water_tiles: Array[Vector2i] = []
			var queue: Array[Vector2i] = [cell]
			while queue.size() > 0:
				var t: Vector2i = queue.pop_back()
				if visited.has(t) or not _is_water(t):
					continue
				visited[t] = true
				water_tiles.append(t)
				queue.append(Vector2i(t.x + 1, t.y))
				queue.append(Vector2i(t.x - 1, t.y))
				queue.append(Vector2i(t.x, t.y + 1))
				queue.append(Vector2i(t.x, t.y - 1))

			if water_tiles.size() < 4:
				continue

			var outline := _build_water_outline(water_tiles)
			if outline.size() >= 3:
				outlines.append(outline)

	return outlines


func _build_water_outline(tiles: Array[Vector2i]) -> PackedVector2Array:
	var min_x := tiles[0].x
	var max_x := tiles[0].x
	var min_y := tiles[0].y
	var max_y := tiles[0].y
	for t in tiles:
		if t.x < min_x: min_x = t.x
		if t.x > max_x: max_x = t.x
		if t.y < min_y: min_y = t.y
		if t.y > max_y: max_y = t.y

	var left_edge: Array[Vector2] = []
	var right_edge: Array[Vector2] = []

	for y_tile in range(min_y, max_y + 1):
		var row_min := max_x
		var row_max := min_x
		var has_water := false
		for t in tiles:
			if t.y == y_tile:
				has_water = true
				if t.x < row_min: row_min = t.x
				if t.x > row_max: row_max = t.x
		if has_water:
			left_edge.append(Vector2(row_min * TILE - 2, y_tile * TILE + TILE * 0.5))
			right_edge.append(Vector2((row_max + 1) * TILE + 2, y_tile * TILE + TILE * 0.5))

	if left_edge.size() < 2:
		return PackedVector2Array()

	var pts := PackedVector2Array()
	for p in left_edge:
		pts.append(p)
	right_edge.reverse()
	for p in right_edge:
		pts.append(p)

	return pts
