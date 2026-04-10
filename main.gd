extends Control

# ─────────────────────────────────────────────────────────────
#  Écran titre – Pixels en Provence
#  Fond : ciel provençal (coucher de soleil) + collines + forêt
# ─────────────────────────────────────────────────────────────

class _CollinesDraw extends Control:
	var _rng := RandomNumberGenerator.new()

	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w == 0.0 or h == 0.0:
			return

		# Étoiles / lucioles dans le ciel
		_rng.seed = 137
		for i in 40:
			var x := _rng.randf() * w
			var y := _rng.randf() * h * 0.38
			var r := _rng.randf_range(0.8, 2.2)
			var a := _rng.randf_range(0.3, 0.85)
			draw_circle(Vector2(x, y), r, Color(1.0, 1.0, 0.85, a))

		# Collines arrière (lavande – couleur iconique de Provence)
		draw_colored_polygon(PackedVector2Array([
			Vector2(0,         h * 0.60),
			Vector2(w * 0.10,  h * 0.46),
			Vector2(w * 0.22,  h * 0.53),
			Vector2(w * 0.38,  h * 0.41),
			Vector2(w * 0.52,  h * 0.50),
			Vector2(w * 0.67,  h * 0.43),
			Vector2(w * 0.82,  h * 0.51),
			Vector2(w,         h * 0.46),
			Vector2(w,         h),
			Vector2(0,         h),
		]), Color("#4e3565"))

		# Forêt (silhouette de sapins/pins)
		draw_colored_polygon(PackedVector2Array([
			Vector2(0,         h * 0.74),
			Vector2(w * 0.04,  h * 0.62),
			Vector2(w * 0.08,  h * 0.68),
			Vector2(w * 0.13,  h * 0.59),
			Vector2(w * 0.18,  h * 0.65),
			Vector2(w * 0.24,  h * 0.57),
			Vector2(w * 0.29,  h * 0.63),
			Vector2(w * 0.35,  h * 0.56),
			Vector2(w * 0.40,  h * 0.62),
			Vector2(w * 0.46,  h * 0.55),
			Vector2(w * 0.51,  h * 0.61),
			Vector2(w * 0.57,  h * 0.54),
			Vector2(w * 0.62,  h * 0.60),
			Vector2(w * 0.68,  h * 0.55),
			Vector2(w * 0.73,  h * 0.61),
			Vector2(w * 0.79,  h * 0.56),
			Vector2(w * 0.85,  h * 0.62),
			Vector2(w * 0.91,  h * 0.57),
			Vector2(w * 0.96,  h * 0.63),
			Vector2(w,         h * 0.60),
			Vector2(w,         h),
			Vector2(0,         h),
		]), Color("#183d14"))

		# Prairie avant
		draw_rect(Rect2(0, h * 0.80, w, h * 0.20), Color("#234f1a"))

		# Reflets chauds sur la prairie
		draw_rect(Rect2(0, h * 0.80, w, h * 0.04), Color(1.0, 0.6, 0.1, 0.08))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_construire_fond()
	_construire_titre()
	_construire_menu()


# ── Fond dégradé ──────────────────────────────────────────────

# ── Fond Image (Remplace le dégradé) ──────────────────────────

func _construire_fond() -> void:
	# 1. Création du conteneur pour l'image
	var bg := TextureRect.new()
	
	# 2. Chargement de ton image
	var texture_image = load("res://assets/fonts/ecranAcceuil.png")
	
	if texture_image:
		bg.texture = texture_image
		# On s'assure que l'image couvre tout l'écran proprement
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
	else:
		push_error("Impossible de charger l'image : res://assets/fonts/encranAcceuil.png")

	# OPTIONNEL : Si tu veux garder tes collines dessinées PAR-DESSUS l'image :
	# var collines := _CollinesDraw.new()
	# collines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# add_child(collines)
# ── Titre ─────────────────────────────────────────────────────

func _construire_titre() -> void:
	var font_titre := _charger_font("res://assets/fonts/ManaSeedTitle.ttf")

	# Bande semi-transparente derrière le titre
	var bande := Panel.new()
	var style_bande := StyleBoxFlat.new()
	style_bande.bg_color = Color(0.0, 0.0, 0.0, 0.38)
	style_bande.border_color = Color("#c8922a")
	style_bande.border_width_top    = 2
	style_bande.border_width_bottom = 2
	bande.add_theme_stylebox_override("panel", style_bande)
	bande.set_anchor(SIDE_LEFT,   0.0)
	bande.set_anchor(SIDE_RIGHT,  1.0)
	bande.set_anchor(SIDE_TOP,    0.0)
	bande.set_anchor(SIDE_BOTTOM, 0.0)
	bande.offset_top    = 58
	bande.offset_bottom = 190
	add_child(bande)

	# Titre principal
	var titre := Label.new()
	titre.text = "Pixels en Provence"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	titre.offset_top    = 68
	titre.offset_bottom = 152
	if font_titre:
		titre.add_theme_font_override("font", font_titre)
	titre.add_theme_font_size_override("font_size", 58)
	titre.add_theme_color_override("font_color",        Color("#ffecd2"))
	titre.add_theme_color_override("font_shadow_color", Color("#1e0800"))
	titre.add_theme_constant_override("shadow_offset_x",   3)
	titre.add_theme_constant_override("shadow_offset_y",   4)
	titre.add_theme_constant_override("shadow_outline_size", 2)
	add_child(titre)

	# Sous-titre
	var sous := Label.new()
	sous.text = "~ Un monde de nature et d'aventure ~"
	sous.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sous.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	sous.offset_top    = 152
	sous.offset_bottom = 188
	if font_titre:
		sous.add_theme_font_override("font", font_titre)
	sous.add_theme_font_size_override("font_size", 17)
	sous.add_theme_color_override("font_color", Color("#f0b840"))
	add_child(sous)


# ── Menu principal ────────────────────────────────────────────

func _construire_menu() -> void:
	var font_body  := _charger_font("res://assets/fonts/ManaSeedBody.ttf")
	var a_save     := GameData.sauvegarde_existe()

	var boutons := [
		["Nouvelle Partie", _on_nouvelle_partie, true],
		["Continuer",       _on_continuer,       a_save],
		["Quitter",         _on_quitter,         true],
	]

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 18)
	menu.set_anchor(SIDE_LEFT,   0.5)
	menu.set_anchor(SIDE_RIGHT,  0.5)
	menu.set_anchor(SIDE_TOP,    0.5)
	menu.set_anchor(SIDE_BOTTOM, 0.5)
	menu.offset_left   = -170
	menu.offset_right  =  170
	menu.offset_top    =   20
	menu.offset_bottom =  210
	add_child(menu)

	for data in boutons:
		var btn := _creer_bouton(data[0], font_body)
		btn.disabled = not data[2]
		btn.pressed.connect(data[1])
		menu.add_child(btn)

	# Version
	var version := Label.new()
	version.text = "v0.1 – alpha"
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.offset_left = -130
	version.offset_top  = -28
	version.add_theme_color_override("font_color", Color(1, 1, 1, 0.30))
	if font_body:
		version.add_theme_font_override("font", font_body)
	version.add_theme_font_size_override("font_size", 13)
	add_child(version)


# ── Helpers ───────────────────────────────────────────────────

func _creer_bouton(texte: String, font: Font) -> Button:
	var btn := Button.new()
	btn.text = texte
	btn.custom_minimum_size = Vector2(340, 56)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if font:
		btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 22)

	btn.add_theme_stylebox_override("normal",   _style_btn(Color("#5c2e0e"), Color("#c8922a")))
	btn.add_theme_stylebox_override("hover",    _style_btn(Color("#7d3e14"), Color("#e8b040")))
	btn.add_theme_stylebox_override("pressed",  _style_btn(Color("#3a1c06"), Color("#a07020")))
	btn.add_theme_stylebox_override("disabled", _style_btn(Color("#222222"), Color("#444444")))
	btn.add_theme_stylebox_override("focus",    _style_btn(Color("#7d3e14"), Color("#e8b040")))

	btn.add_theme_color_override("font_color",          Color("#ffecd2"))
	btn.add_theme_color_override("font_hover_color",    Color("#ffffff"))
	btn.add_theme_color_override("font_pressed_color",  Color("#ffc060"))
	btn.add_theme_color_override("font_disabled_color", Color("#505050"))

	return btn


func _style_btn(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color     = bg
	s.border_color = border
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left     = 5
	s.corner_radius_top_right    = 5
	s.corner_radius_bottom_left  = 5
	s.corner_radius_bottom_right = 5
	s.content_margin_left   = 16
	s.content_margin_right  = 16
	s.content_margin_top    = 8
	s.content_margin_bottom = 8
	return s


func _charger_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path)
	return null


# ── Actions ───────────────────────────────────────────────────

func _on_nouvelle_partie() -> void:
	get_tree().change_scene_to_file("res://creation_perso.tscn")


func _on_continuer() -> void:
	GameData.charger()
	get_tree().change_scene_to_file("res://monde.tscn")


func _on_quitter() -> void:
	get_tree().quit()
