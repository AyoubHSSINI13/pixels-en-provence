@tool
extends Node2D

const MAP_W := 160
const MAP_H := 90
const TILE  := 16

# --- Atlas coords dans gentle_forest.png (16×16 tiles, grille 16×16) ---
const GRASS_TILES := [Vector2i(0,0), Vector2i(2,0), Vector2i(3,0), Vector2i(7,0)]
const DIRT_TILES  := [Vector2i(1,0), Vector2i(4,0), Vector2i(5,0)]
const CLIFF_TILES := [Vector2i(1,1), Vector2i(2,1)]
const WATER_TILES := [Vector2i(1,9), Vector2i(2,9), Vector2i(4,9)]  # tuiles eau bleue

var _rng := RandomNumberGenerator.new()
var _grid: Array[String] = []
var _atlas_source: TileSetAtlasSource

# Palettes selon l'heure
const PALETTE_JOUR  := "res://assets/tilemap/gentle_forest/gentle_forest.png"       # v01
const PALETTE_SOIR  := "res://assets/tilemap/gentle_forest/gentle_forest_v02.png"   # v02
const PALETTE_NUIT  := "res://assets/tilemap/gentle_forest/gentle_forest_v03.png"   # v03

var _current_palette := ""


func _ready() -> void:
	_rng.seed = 42
	_generate_grid()
	_build_tileset()
	_paint_map()
	_build_water_overlay()
	if Engine.is_editor_hint():
		return
	_build_collision()
	_build_waterfall()
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


# =================================================================
# GENERATION DE LA GRILLE — fidele au MapDesign.png
# F=falaise  G=herbe  D=chemin  W=eau
# =================================================================
func _generate_grid() -> void:
	_grid.clear()

	# 1) Tout en falaise par defaut
	for y in MAP_H:
		_grid.append("F".repeat(MAP_W))

	# 2) Carve oval interieur (herbe)
	var cx := MAP_W / 2.0     # 40
	var cy := MAP_H / 2.0     # 22.5
	var rx := MAP_W / 2.0 - 3 # rayon X avec bordure ~3 tiles
	var ry := MAP_H / 2.0 - 3 # rayon Y avec bordure ~3 tiles

	for y in MAP_H:
		for x in MAP_W:
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			if dx * dx + dy * dy < 1.0:
				_set_tile(x, y, "G")

	# 3) Riviere — coule du haut-droite vers le bas
	#    Colonne ~55, de row 4 a row 38
	_draw_river()

	# 4) Lac — zone elargie au milieu-droite
	_draw_lake()

	# 5) Chemins de terre
	_draw_paths()


func _draw_river() -> void:
	# Riviere principale : du haut (~row 10) au bas (~row 76)
	for y in range(10, 77):
		var base_x := 110 + int(sin(y * 0.08) * 3.0)
		var width := 5
		if y >= 36 and y <= 56:
			continue  # gere par _draw_lake
		for dx in range(-2, width - 1):
			var px := base_x + dx
			if _is_inside_oval(px, y):
				_set_tile(px, y, "W")


func _draw_lake() -> void:
	# Lac : ellipse au milieu-droite
	var lake_cx := 112.0
	var lake_cy := 46.0
	var lake_rx := 12.0
	var lake_ry := 11.0

	for y in range(30, 64):
		for x in range(96, 132):
			var dx := (x - lake_cx) / lake_rx
			var dy := (y - lake_cy) / lake_ry
			if dx * dx + dy * dy < 1.0 and _is_inside_oval(x, y):
				_set_tile(x, y, "W")


func _draw_paths() -> void:
	# Chemin horizontal principal (row 44-45)
	for x in range(16, 140):
		for row in [44, 45]:
			if _is_inside_oval(x, row) and _get_tile(x, row) != "W":
				_set_tile(x, row, "D")

	# Chemin vertical principal (col 50-51)
	for y in range(12, 80):
		for col in [50, 51]:
			if _is_inside_oval(col, y) and _get_tile(col, y) != "W":
				_set_tile(col, y, "D")

	# Chemin secondaire horizontal haut (row 24)
	for x in range(30, 100):
		if _is_inside_oval(x, 24) and _get_tile(x, 24) != "W":
			_set_tile(x, 24, "D")

	# Chemin secondaire horizontal bas (row 66)
	for x in range(24, 104):
		if _is_inside_oval(x, 66) and _get_tile(x, 66) != "W":
			_set_tile(x, 66, "D")

	# Chemin diagonal vers la cascade (de col 51,row 24 vers col 106,row 12)
	for i in range(56):
		var px := 51 + i
		var py := 24 - int(i * 12.0 / 55.0)
		if _is_inside_oval(px, py) and _get_tile(px, py) != "W":
			_set_tile(px, py, "D")

	# Chemin vertical secondaire (col 80)
	for y in range(20, 72):
		if _is_inside_oval(80, y) and _get_tile(80, y) != "W":
			_set_tile(80, y, "D")

	# Chemin autour du lac (rive ouest)
	for y in range(34, 60):
		var lx := 100 - int(abs(y - 46) * 0.5)
		if _is_inside_oval(lx, y) and _get_tile(lx, y) != "W":
			_set_tile(lx, y, "D")


# --- Helpers grille ---

func _is_inside_oval(x: int, y: int) -> bool:
	var cx := MAP_W / 2.0
	var cy := MAP_H / 2.0
	var rx := MAP_W / 2.0 - 3
	var ry := MAP_H / 2.0 - 3
	var dx := (x - cx) / rx
	var dy := (y - cy) / ry
	return dx * dx + dy * dy < 1.0


func _set_tile(x: int, y: int, c: String) -> void:
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return
	var row := _grid[y]
	_grid[y] = row.substr(0, x) + c + row.substr(x + 1)


func _get_tile(x: int, y: int) -> String:
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return "F"
	return _grid[y][x]


# =================================================================
# TILESET
# =================================================================
func _build_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	_atlas_source = TileSetAtlasSource.new()
	_atlas_source.texture = load(PALETTE_JOUR)
	_atlas_source.texture_region_size = Vector2i(TILE, TILE)
	for ty in 16:
		for tx in 16:
			_atlas_source.create_tile(Vector2i(tx, ty))
	ts.add_source(_atlas_source, 0)
	$sol.tile_set = ts


# =================================================================
# PEINTURE DES TUILES
# =================================================================
func _paint_map() -> void:
	var sol: TileMapLayer = $sol
	for y in MAP_H:
		for x in MAP_W:
			var c := _get_tile(x, y)
			var atlas: Vector2i
			match c:
				"G":
					atlas = GRASS_TILES[_rng.randi() % GRASS_TILES.size()]
				"D":
					atlas = DIRT_TILES[_rng.randi() % DIRT_TILES.size()]
				"F":
					atlas = CLIFF_TILES[_rng.randi() % CLIFF_TILES.size()]
				"W":
					atlas = WATER_TILES[_rng.randi() % WATER_TILES.size()]
			sol.set_cell(Vector2i(x, y), 0, atlas)


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
# CASCADE
# =================================================================
func _build_waterfall() -> void:
	var old := get_node_or_null("WaterfallRoot")
	if old:
		old.queue_free()

	var root := Node2D.new()
	root.name = "WaterfallRoot"
	root.z_index = 2
	add_child(root)

	# AnimatedSprite2D avec les 3 frames du waterfall
	var frames := SpriteFrames.new()
	frames.add_animation("cascade")
	frames.set_animation_loop("cascade", true)
	frames.set_animation_speed("cascade", 6.0)
	for i in range(1, 4):
		var tex: Texture2D = load("res://assets/tilemap/gentle_forest/waterfall_v0%d.png" % i)
		frames.add_frame("cascade", tex)

	# Positionner la cascade en haut de la riviere (col 110, row 10)
	var wf := AnimatedSprite2D.new()
	wf.sprite_frames = frames
	wf.position = Vector2(110 * TILE + TILE * 1.5, 10 * TILE)
	wf.play("cascade")
	root.add_child(wf)


# =================================================================
# COLLISION — murs sur F et W
# =================================================================
func _build_collision() -> void:
	var walls := Node2D.new()
	walls.name = "Walls"
	add_child(walls)

	for y in MAP_H:
		var start_x := -1
		for x in range(MAP_W + 1):
			var bloque := x < MAP_W and (_get_tile(x, y) == "F" or _get_tile(x, y) == "W")
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
	var poly := NavigationPolygon.new()

	# 1) Contour extérieur — ovale de la zone jouable
	var cx := MAP_W * TILE * 0.5
	var cy := MAP_H * TILE * 0.5
	var rx := (MAP_W * TILE * 0.5 - 3 * TILE) * 0.95
	var ry := (MAP_H * TILE * 0.5 - 3 * TILE) * 0.95
	var outer := PackedVector2Array()
	for i in 24:
		var angle := i * TAU / 24.0
		outer.append(Vector2(cx + rx * cos(angle), cy + ry * sin(angle)))
	poly.add_outline(outer)

	# 2) Trous — contours des zones d'eau (sens horaire inversé)
	#    On scanne la grille pour trouver les bords de chaque zone W
	var water_outlines := _find_water_outlines()
	for outline in water_outlines:
		poly.add_outline(outline)

	poly.make_polygons_from_outlines()
	nav.navigation_polygon = poly


func _find_water_outlines() -> Array[PackedVector2Array]:
	# Marching squares simplifié : on trouve les contours des zones d'eau
	# en parcourant les bords des tiles W
	var visited := {}
	var outlines: Array[PackedVector2Array] = []

	for y in MAP_H:
		for x in MAP_W:
			if _get_tile(x, y) != "W":
				continue
			var key := Vector2i(x, y)
			if visited.has(key):
				continue

			# Flood fill pour trouver tous les tiles de cette zone d'eau
			var water_tiles: Array[Vector2i] = []
			var queue: Array[Vector2i] = [key]
			while queue.size() > 0:
				var t: Vector2i = queue.pop_back()
				if visited.has(t):
					continue
				if t.x < 0 or t.x >= MAP_W or t.y < 0 or t.y >= MAP_H:
					continue
				if _get_tile(t.x, t.y) != "W":
					continue
				visited[t] = true
				water_tiles.append(t)
				queue.append(Vector2i(t.x + 1, t.y))
				queue.append(Vector2i(t.x - 1, t.y))
				queue.append(Vector2i(t.x, t.y + 1))
				queue.append(Vector2i(t.x, t.y - 1))

			if water_tiles.size() < 4:
				continue

			# Construire un contour convexe simplifié autour de cette zone
			var outline := _build_water_outline(water_tiles)
			if outline.size() >= 3:
				outlines.append(outline)

	return outlines


func _build_water_outline(tiles: Array[Vector2i]) -> PackedVector2Array:
	# Trouver les limites de la zone d'eau
	var min_x := MAP_W
	var max_x := 0
	var min_y := MAP_H
	var max_y := 0
	for t in tiles:
		if t.x < min_x: min_x = t.x
		if t.x > max_x: max_x = t.x
		if t.y < min_y: min_y = t.y
		if t.y > max_y: max_y = t.y

	# Pour chaque row, trouver le min_x et max_x des tiles d'eau
	# puis construire un contour qui suit la forme
	var left_edge: Array[Vector2] = []
	var right_edge: Array[Vector2] = []

	for y_tile in range(min_y, max_y + 1):
		var row_min := MAP_W
		var row_max := 0
		var has_water := false
		for t in tiles:
			if t.y == y_tile:
				has_water = true
				if t.x < row_min: row_min = t.x
				if t.x > row_max: row_max = t.x
		if has_water:
			# Marge de 2px pour que les animaux ne frôlent pas l'eau
			left_edge.append(Vector2(row_min * TILE - 2, y_tile * TILE + TILE * 0.5))
			right_edge.append(Vector2((row_max + 1) * TILE + 2, y_tile * TILE + TILE * 0.5))

	if left_edge.size() < 2:
		return PackedVector2Array()

	# Contour sens antihoraire (= trou pour NavigationPolygon)
	# Haut -> droite vers le bas -> bas -> gauche vers le haut
	var pts := PackedVector2Array()

	# Bord gauche de haut en bas
	for p in left_edge:
		pts.append(p)

	# Bord droit de bas en haut
	right_edge.reverse()
	for p in right_edge:
		pts.append(p)

	return pts
