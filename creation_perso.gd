extends Control

# ─────────────────────────────────────────────────────────────
#  Écran de création du personnage
#  Fond Provence identique au titre + carte centrée
# ─────────────────────────────────────────────────────────────

const BASE_PATH := "res://assets/personnage/mana_seed_demo/char_a_p1/"
const FRAME := Rect2(0, 256, 64, 64)

const NB_CARNATIONS  := 11
const NB_COULEURS    := 14   # v00 à v13

# Coiffures disponibles dans le pack
const COIFFURES := ["bob1", "dap1"]
const NOMS_COIFFURES := ["Bob", "Dreadlocks"]

# Tenues disponibles (type + nb variantes)
const TENUES := [
	{"id": "fstr", "nom": "Forestier",  "variantes": 5},
	{"id": "pfpn", "nom": "Paysan",     "variantes": 5},
	{"id": "boxr", "nom": "Boxeur",     "variantes": 1},
	{"id": "undi", "nom": "Sous-vêtements", "variantes": 1},
]

# Chapeaux disponibles
const CHAPEAUX := [
	{"id": "",     "nom": "Aucun",      "variantes": 0},
	{"id": "pfht", "nom": "Chapeau paysan", "variantes": 5},
	{"id": "pnty", "nom": "Bandana",    "variantes": 5},
]

var carnation       := 0
var coiffure        := 0
var couleur_cheveux := 0
var tenue_type      := 0
var tenue_var       := 0
var chapeau_type    := 0
var chapeau_var     := 0

var sprite_corps:   TextureRect
var sprite_tenue:   TextureRect
var sprite_cheveux: TextureRect
var sprite_chapeau: TextureRect

var village_input: LineEdit
var perso_input:   LineEdit
var lbl_carnation: Label
var lbl_coiffure:  Label
var lbl_couleur:   Label
var lbl_tenue:     Label
var lbl_chapeau:   Label
var lbl_erreur:    Label


# ── Fond (copie du titre pour la continuité visuelle) ─────────

class _FondDraw extends Control:
	var _rng := RandomNumberGenerator.new()
	func _ready() -> void:
		resized.connect(queue_redraw)
	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w == 0.0 or h == 0.0:
			return
		_rng.seed = 137
		for i in 40:
			var x := _rng.randf() * w
			var y := _rng.randf() * h * 0.38
			var r := _rng.randf_range(0.8, 2.2)
			var a := _rng.randf_range(0.3, 0.85)
			draw_circle(Vector2(x, y), r, Color(1.0, 1.0, 0.85, a))
		draw_colored_polygon(PackedVector2Array([
			Vector2(0,h*0.60),Vector2(w*0.10,h*0.46),Vector2(w*0.22,h*0.53),
			Vector2(w*0.38,h*0.41),Vector2(w*0.52,h*0.50),Vector2(w*0.67,h*0.43),
			Vector2(w*0.82,h*0.51),Vector2(w,h*0.46),Vector2(w,h),Vector2(0,h),
		]), Color("#4e3565"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(0,h*0.74),Vector2(w*0.04,h*0.62),Vector2(w*0.08,h*0.68),
			Vector2(w*0.13,h*0.59),Vector2(w*0.18,h*0.65),Vector2(w*0.24,h*0.57),
			Vector2(w*0.29,h*0.63),Vector2(w*0.35,h*0.56),Vector2(w*0.40,h*0.62),
			Vector2(w*0.46,h*0.55),Vector2(w*0.51,h*0.61),Vector2(w*0.57,h*0.54),
			Vector2(w*0.62,h*0.60),Vector2(w*0.68,h*0.55),Vector2(w*0.73,h*0.61),
			Vector2(w*0.79,h*0.56),Vector2(w*0.85,h*0.62),Vector2(w*0.91,h*0.57),
			Vector2(w*0.96,h*0.63),Vector2(w,h*0.60),Vector2(w,h),Vector2(0,h),
		]), Color("#183d14"))
		draw_rect(Rect2(0, h*0.80, w, h*0.20), Color("#234f1a"))
		draw_rect(Rect2(0, h*0.80, w, h*0.04), Color(1.0, 0.6, 0.1, 0.08))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var font_body  := _charger_font("res://assets/fonts/ManaSeedBody.ttf")
	var font_titre := _charger_font("res://assets/fonts/ManaSeedTitle.ttf")

	_construire_fond()
	_construire_carte(font_titre, font_body)
	_update_preview()


# ── Fond Provence ─────────────────────────────────────────────

func _construire_fond() -> void:
	var grad := Gradient.new()
	grad.set_color(0,  Color("#0c1835"))
	grad.set_offset(0, 0.0)
	grad.set_color(1,  Color("#1e3a18"))
	grad.set_offset(1, 1.0)
	grad.add_point(0.38, Color("#c85018"))
	grad.add_point(0.58, Color("#6b2a14"))

	var tex := GradientTexture2D.new()
	tex.gradient  = grad
	tex.fill      = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to   = Vector2(0.5, 1.0)
	tex.width     = 8
	tex.height    = 256

	var bg := TextureRect.new()
	bg.texture      = tex
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var fond := _FondDraw.new()
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	# Voile sombre pour faire ressortir la carte
	var voile := ColorRect.new()
	voile.color = Color(0.0, 0.0, 0.0, 0.45)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(voile)


# ── Carte centrée ─────────────────────────────────────────────

func _construire_carte(font_titre: Font, font_body: Font) -> void:
	var carte := Panel.new()
	var s_carte := StyleBoxFlat.new()
	s_carte.bg_color     = Color("#0d1a08e8")
	s_carte.border_color = Color("#c8922a")
	s_carte.border_width_left   = 2
	s_carte.border_width_right  = 2
	s_carte.border_width_top    = 2
	s_carte.border_width_bottom = 2
	s_carte.corner_radius_top_left     = 8
	s_carte.corner_radius_top_right    = 8
	s_carte.corner_radius_bottom_left  = 8
	s_carte.corner_radius_bottom_right = 8
	s_carte.shadow_color = Color(0, 0, 0, 0.6)
	s_carte.shadow_size  = 12
	carte.add_theme_stylebox_override("panel", s_carte)
	carte.custom_minimum_size = Vector2(870, 560)
	carte.set_anchor(SIDE_LEFT,   0.5)
	carte.set_anchor(SIDE_RIGHT,  0.5)
	carte.set_anchor(SIDE_TOP,    0.5)
	carte.set_anchor(SIDE_BOTTOM, 0.5)
	carte.offset_left   = -435
	carte.offset_right  =  435
	carte.offset_top    = -280
	carte.offset_bottom =  280
	add_child(carte)

	# Barre de titre de la carte
	var titre_bar := Panel.new()
	var s_bar := StyleBoxFlat.new()
	s_bar.bg_color     = Color("#1a3a10")
	s_bar.border_color = Color("#c8922a")
	s_bar.border_width_bottom = 2
	s_bar.corner_radius_top_left  = 7
	s_bar.corner_radius_top_right = 7
	titre_bar.add_theme_stylebox_override("panel", s_bar)
	titre_bar.set_anchor(SIDE_LEFT,   0.0)
	titre_bar.set_anchor(SIDE_RIGHT,  1.0)
	titre_bar.set_anchor(SIDE_TOP,    0.0)
	titre_bar.set_anchor(SIDE_BOTTOM, 0.0)
	titre_bar.offset_top    = 0
	titre_bar.offset_bottom = 52
	carte.add_child(titre_bar)

	var lbl_titre := Label.new()
	lbl_titre.text = "Création du Personnage"
	lbl_titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if font_titre:
		lbl_titre.add_theme_font_override("font", font_titre)
	lbl_titre.add_theme_font_size_override("font_size", 28)
	lbl_titre.add_theme_color_override("font_color",        Color("#ffecd2"))
	lbl_titre.add_theme_color_override("font_shadow_color", Color("#0a0a00"))
	lbl_titre.add_theme_constant_override("shadow_offset_x", 2)
	lbl_titre.add_theme_constant_override("shadow_offset_y", 2)
	titre_bar.add_child(lbl_titre)

	# Contenu de la carte (sous la barre)
	var contenu := HBoxContainer.new()
	contenu.add_theme_constant_override("separation", 24)
	contenu.set_anchor(SIDE_LEFT,   0.0)
	contenu.set_anchor(SIDE_RIGHT,  1.0)
	contenu.set_anchor(SIDE_TOP,    0.0)
	contenu.set_anchor(SIDE_BOTTOM, 1.0)
	contenu.offset_top    = 58
	contenu.offset_left   = 20
	contenu.offset_right  = -20
	contenu.offset_bottom = -16
	carte.add_child(contenu)

	_construire_preview(contenu)
	_construire_form(contenu, font_body)


# ── Aperçu personnage (colonne gauche) ───────────────────────

func _construire_preview(parent: Control) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.custom_minimum_size = Vector2(190, 0)
	parent.add_child(col)

	# Panel preview avec style
	var preview := Panel.new()
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var s := StyleBoxFlat.new()
	s.bg_color     = Color("#060e04")
	s.border_color = Color("#c8922a")
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left     = 5
	s.corner_radius_top_right    = 5
	s.corner_radius_bottom_left  = 5
	s.corner_radius_bottom_right = 5
	preview.add_theme_stylebox_override("panel", s)
	col.add_child(preview)

	for nom in ["corps", "tenue", "cheveux", "chapeau"]:
		var tex_rect := TextureRect.new()
		tex_rect.name         = nom
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		preview.add_child(tex_rect)

	sprite_corps   = preview.get_node("corps")
	sprite_tenue   = preview.get_node("tenue")
	sprite_cheveux = preview.get_node("cheveux")
	sprite_chapeau = preview.get_node("chapeau")


# ── Formulaire (colonne droite) ───────────────────────────────

func _construire_form(parent: Control, font: Font) -> void:
	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 6)
	parent.add_child(form)

	# Noms
	_champ_label(form, "Nom du village / forêt", font)
	village_input = _creer_input("Ex : La Forêt des Maules", font)
	form.add_child(village_input)

	_champ_label(form, "Nom du personnage", font)
	perso_input = _creer_input("Ex : Camille", font)
	form.add_child(perso_input)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color("#3a5a30"))
	form.add_child(sep)

	_champ_label(form, "Apparence", font)

	lbl_carnation = _selector(form, _on_carnation.bind(-1), _on_carnation.bind(1), font)
	lbl_coiffure  = _selector(form, _on_coiffure.bind(-1),  _on_coiffure.bind(1),  font)
	lbl_couleur   = _selector(form, _on_couleur.bind(-1),   _on_couleur.bind(1),   font)
	lbl_tenue     = _selector(form, _on_tenue.bind(-1),     _on_tenue.bind(1),     font)
	lbl_chapeau   = _selector(form, _on_chapeau.bind(-1),   _on_chapeau.bind(1),   font)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	form.add_child(spacer)

	lbl_erreur = Label.new()
	lbl_erreur.text = ""
	lbl_erreur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_erreur.add_theme_color_override("font_color", Color("#ff7070"))
	if font:
		lbl_erreur.add_theme_font_override("font", font)
	lbl_erreur.add_theme_font_size_override("font_size", 14)
	form.add_child(lbl_erreur)

	# Boutons bas (Retour + Commencer)
	var hbox_btns := HBoxContainer.new()
	hbox_btns.add_theme_constant_override("separation", 12)
	form.add_child(hbox_btns)

	var btn_retour := _creer_bouton("< Retour", font, Color("#2a1408"), Color("#7a5010"), 120, 46)
	btn_retour.add_theme_color_override("font_color", Color("#c8a060"))
	btn_retour.pressed.connect(_on_retour)
	hbox_btns.add_child(btn_retour)

	var btn_start := _creer_bouton("Commencer l'aventure", font, Color("#5c2e0e"), Color("#c8922a"), 0, 46)
	btn_start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_start.pressed.connect(_on_commencer)
	hbox_btns.add_child(btn_start)


# ── Helpers UI ────────────────────────────────────────────────

func _champ_label(parent: Control, texte: String, font: Font) -> void:
	var lbl := Label.new()
	lbl.text = texte
	if font:
		lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color("#a8d898"))
	parent.add_child(lbl)


func _creer_input(placeholder: String, font: Font) -> LineEdit:
	var input := LineEdit.new()
	input.placeholder_text = placeholder
	if font:
		input.add_theme_font_override("font", font)
	input.add_theme_font_size_override("font_size", 15)
	var s := StyleBoxFlat.new()
	s.bg_color     = Color("#060e04")
	s.border_color = Color("#3a6a28")
	s.border_width_bottom = 2
	s.border_width_top    = 1
	s.border_width_left   = 1
	s.border_width_right  = 1
	s.corner_radius_top_left     = 3
	s.corner_radius_top_right    = 3
	s.corner_radius_bottom_left  = 3
	s.corner_radius_bottom_right = 3
	s.content_margin_left   = 8
	s.content_margin_right  = 8
	s.content_margin_top    = 5
	s.content_margin_bottom = 5
	input.add_theme_stylebox_override("normal", s)
	input.add_theme_color_override("font_color",             Color("#ffecd2"))
	input.add_theme_color_override("font_placeholder_color", Color("#4a7040"))
	return input


func _selector(parent: Control, cb_prev: Callable, cb_next: Callable, font: Font) -> Label:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	parent.add_child(hbox)

	var btn_p := _creer_bouton("<", font, Color("#1e0e04"), Color("#7a5010"), 30, 28)
	btn_p.add_theme_color_override("font_color",       Color("#c8922a"))
	btn_p.add_theme_color_override("font_hover_color", Color("#ffecd2"))
	btn_p.pressed.connect(cb_prev)
	hbox.add_child(btn_p)

	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color("#ffecd2"))
	hbox.add_child(lbl)

	var btn_n := _creer_bouton(">", font, Color("#1e0e04"), Color("#7a5010"), 30, 28)
	btn_n.add_theme_color_override("font_color",       Color("#c8922a"))
	btn_n.add_theme_color_override("font_hover_color", Color("#ffecd2"))
	btn_n.pressed.connect(cb_next)
	hbox.add_child(btn_n)

	return lbl


func _creer_bouton(texte: String, font: Font, bg: Color, border: Color,
		min_w: int, min_h: int) -> Button:
	var btn := Button.new()
	btn.text = texte
	btn.custom_minimum_size = Vector2(min_w, min_h)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if font:
		btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_stylebox_override("normal",  _style_btn(bg, border))
	btn.add_theme_stylebox_override("hover",   _style_btn(bg.lightened(0.15), border.lightened(0.2)))
	btn.add_theme_stylebox_override("pressed", _style_btn(bg.darkened(0.15),  border.darkened(0.1)))
	btn.add_theme_stylebox_override("focus",   _style_btn(bg.lightened(0.15), border.lightened(0.2)))
	btn.add_theme_color_override("font_color",       Color("#ffecd2"))
	btn.add_theme_color_override("font_hover_color", Color("#ffffff"))
	return btn


func _style_btn(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color     = bg
	s.border_color = border
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left     = 4
	s.corner_radius_top_right    = 4
	s.corner_radius_bottom_left  = 4
	s.corner_radius_bottom_right = 4
	s.content_margin_left   = 8
	s.content_margin_right  = 8
	s.content_margin_top    = 4
	s.content_margin_bottom = 4
	return s


func _charger_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path)
	return null


# ── Aperçu ────────────────────────────────────────────────────

func _update_preview() -> void:
	# Corps
	sprite_corps.texture = _atlas_tex(
		"%schar_a_p1_0bas_humn_v%02d.png" % [BASE_PATH, carnation])

	# Tenue
	var t := TENUES[tenue_type]
	var t_var := (tenue_var % t.variantes) + 1 if t.variantes > 0 else 1
	sprite_tenue.texture = _atlas_tex(
		"%s1out/char_a_p1_1out_%s_v%02d.png" % [BASE_PATH, t.id, t_var])

	# Cheveux
	sprite_cheveux.texture = _atlas_tex(
		"%s4har/char_a_p1_4har_%s_v%02d.png" % [BASE_PATH, COIFFURES[coiffure], couleur_cheveux])

	# Chapeau
	var ch := CHAPEAUX[chapeau_type]
	if ch.id == "":
		sprite_chapeau.texture = null
	else:
		var ch_var := (chapeau_var % ch.variantes) + 1 if ch.variantes > 0 else 1
		sprite_chapeau.texture = _atlas_tex(
			"%s5hat/char_a_p1_5hat_%s_v%02d.png" % [BASE_PATH, ch.id, ch_var])

	# Labels
	lbl_carnation.text = "Carnation   %d / %d"  % [carnation + 1, NB_CARNATIONS]
	lbl_coiffure.text  = "Coiffure    %s"        % NOMS_COIFFURES[coiffure]
	lbl_couleur.text   = "Couleur     %d / %d"   % [couleur_cheveux + 1, NB_COULEURS]
	lbl_tenue.text     = "Tenue       %s %d"     % [t.nom, t_var] if t.variantes > 1 else "Tenue       %s" % t.nom
	if ch.id == "":
		lbl_chapeau.text = "Chapeau     Aucun"
	else:
		lbl_chapeau.text = "Chapeau     %s %d" % [ch.nom, (chapeau_var % ch.variantes) + 1] if ch.variantes > 1 else "Chapeau     %s" % ch.nom


func _atlas_tex(path: String) -> AtlasTexture:
	if not ResourceLoader.exists(path):
		return null
	var a := AtlasTexture.new()
	a.atlas  = load(path)
	a.region = FRAME
	return a


# ── Callbacks ─────────────────────────────────────────────────

func _on_carnation(dir: int) -> void:
	carnation = (carnation + dir + NB_CARNATIONS) % NB_CARNATIONS
	_update_preview()

func _on_coiffure(dir: int) -> void:
	coiffure = (coiffure + dir + COIFFURES.size()) % COIFFURES.size()
	_update_preview()

func _on_couleur(dir: int) -> void:
	couleur_cheveux = (couleur_cheveux + dir + NB_COULEURS) % NB_COULEURS
	_update_preview()

func _on_tenue(dir: int) -> void:
	# Change le type de tenue, remet la variante à 0
	tenue_type = (tenue_type + dir + TENUES.size()) % TENUES.size()
	tenue_var = 0
	_update_preview()

func _on_chapeau(dir: int) -> void:
	chapeau_type = (chapeau_type + dir + CHAPEAUX.size()) % CHAPEAUX.size()
	chapeau_var = 0
	_update_preview()


func _on_commencer() -> void:
	if village_input.text.strip_edges() == "":
		lbl_erreur.text = "Donne un nom à ton village !"
		return
	if perso_input.text.strip_edges() == "":
		lbl_erreur.text = "Donne un nom à ton personnage !"
		return

	GameData.nom_village     = village_input.text.strip_edges()
	GameData.nom_joueur      = perso_input.text.strip_edges()
	GameData.carnation       = carnation
	GameData.coiffure        = coiffure
	GameData.couleur_cheveux = couleur_cheveux
	GameData.tenue           = tenue_type * 100 + tenue_var  # encode type+var

	GameData.sauvegarder()
	get_tree().change_scene_to_file("res://monde.tscn")


func _on_retour() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
