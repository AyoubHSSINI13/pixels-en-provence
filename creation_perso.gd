extends Control

# ─────────────────────────────────────────────────────────────
#  Écran de création du personnage
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
	{"id": "",     "nom": "Aucun",     "variantes": 0},
	{"id": "pfht", "nom": "Chapeau paysan", "variantes": 5},
	{"id": "pnty", "nom": "Bandana",    "variantes": 5},
]

var carnation      := 0
var coiffure       := 0
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

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var font_body  := _charger_font("res://assets/fonts/ManaSeedBody.ttf")
	var font_titre := _charger_font("res://assets/fonts/ManaSeedTitle.ttf")

	_construire_fond()
	_construire_carte(font_titre, font_body)
	_update_preview()


# ── Fond avec Image ───────────────────────────────────────────

func _construire_fond() -> void:
	# Utilisation de ton image spécifique
	var bg := TextureRect.new()
	bg.texture = load("res://assets/fonts/ecranAcceuil.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Voile sombre légèrement bleuté pour la lisibilité
	var voile := ColorRect.new()
	voile.color = Color(0.05, 0.05, 0.1, 0.5)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(voile)


# ── Carte centrée ─────────────────────────────────────────────

func _construire_carte(font_titre: Font, font_body: Font) -> void:
	var carte := Panel.new()
	var s_carte := StyleBoxFlat.new()
	s_carte.bg_color     = Color("#151a16f2") # Sombre translucide
	s_carte.border_color = Color("#e8b953") # Or plus brillant
	s_carte.border_width_left   = 3
	s_carte.border_width_right  = 3
	s_carte.border_width_top    = 3
	s_carte.border_width_bottom = 3
	s_carte.corner_radius_top_left     = 12
	s_carte.corner_radius_top_right    = 12
	s_carte.corner_radius_bottom_left  = 12
	s_carte.corner_radius_bottom_right = 12
	s_carte.shadow_color = Color(0, 0, 0, 0.7)
	s_carte.shadow_size  = 20
	carte.add_theme_stylebox_override("panel", s_carte)
	
	carte.custom_minimum_size = Vector2(900, 600) # Légèrement agrandi
	carte.set_anchor(SIDE_LEFT,   0.5)
	carte.set_anchor(SIDE_RIGHT,  0.5)
	carte.set_anchor(SIDE_TOP,    0.5)
	carte.set_anchor(SIDE_BOTTOM, 0.5)
	carte.offset_left   = -450
	carte.offset_right  =  450
	carte.offset_top    = -300
	carte.offset_bottom =  300
	add_child(carte)

	# Barre de titre
	var titre_bar := Panel.new()
	var s_bar := StyleBoxFlat.new()
	s_bar.bg_color     = Color("#244a16")
	s_bar.border_color = Color("#e8b953")
	s_bar.border_width_bottom = 2
	s_bar.corner_radius_top_left  = 10
	s_bar.corner_radius_top_right = 10
	titre_bar.add_theme_stylebox_override("panel", s_bar)
	titre_bar.set_anchor(SIDE_LEFT,   0.0)
	titre_bar.set_anchor(SIDE_RIGHT,  1.0)
	titre_bar.set_anchor(SIDE_TOP,    0.0)
	titre_bar.offset_bottom = 60
	carte.add_child(titre_bar)

	var lbl_titre := Label.new()
	lbl_titre.text = "CREATION DU PERSONNAGE" # Correction : Majuscule + Sans accent
	lbl_titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_titre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if font_titre:
		lbl_titre.add_theme_font_override("font", font_titre)
	lbl_titre.add_theme_font_size_override("font_size", 34) # Police agrandie
	lbl_titre.add_theme_color_override("font_color", Color("#ffffff"))
	lbl_titre.add_theme_color_override("font_shadow_color", Color("#000000"))
	lbl_titre.add_theme_constant_override("shadow_offset_x", 3)
	lbl_titre.add_theme_constant_override("shadow_offset_y", 3)
	titre_bar.add_child(lbl_titre)

	var contenu := HBoxContainer.new()
	contenu.add_theme_constant_override("separation", 30)
	contenu.set_anchor(SIDE_LEFT,   0.0)
	contenu.set_anchor(SIDE_RIGHT,  1.0)
	contenu.set_anchor(SIDE_TOP,    0.0)
	contenu.set_anchor(SIDE_BOTTOM, 1.0)
	contenu.offset_top    = 80
	contenu.offset_left   = 30
	contenu.offset_right  = -30
	contenu.offset_bottom = -20
	carte.add_child(contenu)

	_construire_preview(contenu)
	_construire_form(contenu, font_body)


# ── Aperçu personnage ────────────────────────────────────────

func _construire_preview(parent: Control) -> void:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(220, 0)
	parent.add_child(col)

	var preview := Panel.new()
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var s := StyleBoxFlat.new()
	s.bg_color     = Color("#0a1208")
	s.border_color = Color("#e8b953")
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left     = 8
	s.corner_radius_top_right    = 8
	s.corner_radius_bottom_left  = 8
	s.corner_radius_bottom_right = 8
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


# ── Formulaire ───────────────────────────────────────────────

func _construire_form(parent: Control, font: Font) -> void:
	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 10)
	parent.add_child(form)

	_champ_label(form, "Nom du village / forêt", font)
	village_input = _creer_input("Ex : La Forêt des Maules", font)
	form.add_child(village_input)

	_champ_label(form, "Nom du personnage", font)
	perso_input = _creer_input("Ex : Camille", font)
	form.add_child(perso_input)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color("#e8b953", 0.3))
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
	lbl_erreur.add_theme_color_override("font_color", Color("#ff4d4d"))
	if font:
		lbl_erreur.add_theme_font_override("font", font)
	lbl_erreur.add_theme_font_size_override("font_size", 18)
	form.add_child(lbl_erreur)

	var hbox_btns := HBoxContainer.new()
	hbox_btns.add_theme_constant_override("separation", 15)
	form.add_child(hbox_btns)

	var btn_retour := _creer_bouton("< Retour", font, Color("#3d1a08"), Color("#8b4513"), 140, 50)
	btn_retour.add_theme_color_override("font_color", Color("#ffcb8b"))
	btn_retour.pressed.connect(_on_retour)
	hbox_btns.add_child(btn_retour)

	var btn_start := _creer_bouton("Commencer l'aventure", font, Color("#1a3d10"), Color("#e8b953"), 0, 50)
	btn_start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_start.pressed.connect(_on_commencer)
	hbox_btns.add_child(btn_start)


# ── Helpers UI ────────────────────────────────────────────────

func _champ_label(parent: Control, texte: String, font: Font) -> void:
	var lbl := Label.new()
	lbl.text = texte
	if font:
		lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 18) # Police agrandie
	lbl.add_theme_color_override("font_color", Color("#ffcb8b"))
	parent.add_child(lbl)


func _creer_input(placeholder: String, font: Font) -> LineEdit:
	var input := LineEdit.new()
	input.placeholder_text = placeholder
	if font:
		input.add_theme_font_override("font", font)
	input.add_theme_font_size_override("font_size", 20) # Police agrandie
	var s := StyleBoxFlat.new()
	s.bg_color     = Color("#000000", 0.4)
	s.border_color = Color("#e8b953", 0.5)
	s.border_width_bottom = 2
	s.content_margin_left = 12
	input.add_theme_stylebox_override("normal", s)
	input.add_theme_color_override("font_color", Color("#ffffff"))
	return input


func _selector(parent: Control, cb_prev: Callable, cb_next: Callable, font: Font) -> Label:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)

	var btn_p := _creer_bouton("<", font, Color("#222222"), Color("#e8b953"), 40, 35)
	btn_p.pressed.connect(cb_prev)
	hbox.add_child(btn_p)

	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 18) # Police agrandie
	lbl.add_theme_color_override("font_color", Color("#ffffff"))
	hbox.add_child(lbl)

	var btn_n := _creer_bouton(">", font, Color("#222222"), Color("#e8b953"), 40, 35)
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
	btn.add_theme_font_size_override("font_size", 20) # Police agrandie
	btn.add_theme_stylebox_override("normal",  _style_btn(bg, border))
	btn.add_theme_stylebox_override("hover",   _style_btn(bg.lightened(0.2), border.lightened(0.2)))
	btn.add_theme_stylebox_override("pressed", _style_btn(bg.darkened(0.2), border))
	return btn


func _style_btn(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color     = bg
	s.border_color = border
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left     = 6
	s.corner_radius_top_right    = 6
	s.corner_radius_bottom_left  = 6
	s.corner_radius_bottom_right = 6
	return s


func _charger_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path)
	return null


# ── Logique Aperçu (Identique à l'original) ────────────────────

func _update_preview() -> void:
	sprite_corps.texture = _atlas_tex("%schar_a_p1_0bas_humn_v%02d.png" % [BASE_PATH, carnation])
	var t: Dictionary = TENUES[tenue_type]
	var t_var: int = (tenue_var % t.variantes) + 1 if t.variantes > 0 else 1
	sprite_tenue.texture = _atlas_tex("%s1out/char_a_p1_1out_%s_v%02d.png" % [BASE_PATH, t.id, t_var])
	sprite_cheveux.texture = _atlas_tex("%s4har/char_a_p1_4har_%s_v%02d.png" % [BASE_PATH, COIFFURES[coiffure], couleur_cheveux])
	var ch: Dictionary = CHAPEAUX[chapeau_type]
	if ch.id == "":
		sprite_chapeau.texture = null
	else:
		var ch_var: int = (chapeau_var % ch.variantes) + 1 if ch.variantes > 0 else 1
		sprite_chapeau.texture = _atlas_tex("%s5hat/char_a_p1_5hat_%s_v%02d.png" % [BASE_PATH, ch.id, ch_var])

	lbl_carnation.text = "Carnation   %d / %d"  % [carnation + 1, NB_CARNATIONS]
	lbl_coiffure.text  = "Coiffure    %s"        % NOMS_COIFFURES[coiffure]
	lbl_couleur.text   = "Couleur     %d / %d"   % [couleur_cheveux + 1, NB_COULEURS]
	lbl_tenue.text     = "Tenue       %s %d"     % [t.nom, t_var] if t.variantes > 1 else "Tenue       %s" % t.nom
	if ch.id == "":
		lbl_chapeau.text = "Chapeau     Aucun"
	else:
		lbl_chapeau.text = "Chapeau     %s %d" % [ch.nom, (chapeau_var % ch.variantes) + 1] if ch.variantes > 1 else "Chapeau     %s" % ch.nom

func _atlas_tex(path: String) -> AtlasTexture:
	if not ResourceLoader.exists(path): return null
	var a := AtlasTexture.new()
	a.atlas = load(path)
	a.region = FRAME
	return a

# ── Callbacks (Identique à l'original) ────────────────────────

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
	tenue_type = (tenue_type + dir + TENUES.size()) % TENUES.size()
	tenue_var = 0
	_update_preview()

func _on_chapeau(dir: int) -> void:
	chapeau_type = (chapeau_type + dir + CHAPEAUX.size()) % CHAPEAUX.size()
	chapeau_var = 0
	_update_preview()

func _on_commencer() -> void:
	if village_input.text.strip_edges() == "" or perso_input.text.strip_edges() == "":
		lbl_erreur.text = "Les champs ne peuvent pas être vides !"
		return
	GameData.nom_village = village_input.text.strip_edges()
	GameData.nom_joueur = perso_input.text.strip_edges()
	GameData.carnation = carnation
	GameData.coiffure = coiffure
	GameData.couleur_cheveux = couleur_cheveux
	GameData.tenue = tenue_type * 100 + tenue_var
	GameData.sauvegarder()
	get_tree().change_scene_to_file("res://monde.tscn")

func _on_retour() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
