extends Control

const BASE_PATH := "res://assets/personnage/mana_seed_demo/char_a_p1/"
const FRAME := Rect2(0, 256, 64, 64)

const NB_CARNATIONS := 11
const NB_COIFFURES := 2
const NB_COULEURS := 28
const NB_TENUES := 5
const NOMS_COIFFURES := ["Bob", "Dreadlocks"]
const NOMS_TENUES := ["Forestier", "Forestier v2", "Forestier v3", "Forestier v4", "Forestier v5"]

var carnation := 0
var coiffure := 0
var couleur_cheveux := 0
var tenue := 0

var sprite_corps: TextureRect
var sprite_tenue: TextureRect
var sprite_cheveux: TextureRect

var village_input: LineEdit
var perso_input: LineEdit
var lbl_carnation: Label
var lbl_coiffure: Label
var lbl_couleur: Label
var lbl_tenue: Label
var lbl_erreur: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Fond
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.18, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Conteneur principal avec marges
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var vbox_main := VBoxContainer.new()
	vbox_main.add_theme_constant_override("separation", 16)
	margin.add_child(vbox_main)

	# Titre
	var titre := Label.new()
	titre.text = "~ Pixels en Provence ~"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_main.add_child(titre)

	var sep_titre := HSeparator.new()
	vbox_main.add_child(sep_titre)

	# Corps principal
	var hbox := HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 32)
	vbox_main.add_child(hbox)

	# ── Aperçu personnage ──
	var preview_panel := Panel.new()
	preview_panel.custom_minimum_size = Vector2(180, 280)
	hbox.add_child(preview_panel)

	for nom in ["corps", "tenue", "cheveux"]:
		var tr := TextureRect.new()
		tr.name = nom
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		preview_panel.add_child(tr)

	sprite_corps   = preview_panel.get_node("corps")
	sprite_tenue   = preview_panel.get_node("tenue")
	sprite_cheveux = preview_panel.get_node("cheveux")

	# ── Formulaire ──
	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 8)
	hbox.add_child(form)

	_label(form, "Nom du village / forêt")
	village_input = LineEdit.new()
	village_input.placeholder_text = "Ex : La Forêt des Maules"
	form.add_child(village_input)

	_label(form, "Nom du personnage")
	perso_input = LineEdit.new()
	perso_input.placeholder_text = "Ex : Camille"
	form.add_child(perso_input)

	var sep := HSeparator.new()
	form.add_child(sep)

	_label(form, "Apparence du personnage")

	lbl_carnation = _selector(form, _on_carnation.bind(-1), _on_carnation.bind(1))
	lbl_coiffure  = _selector(form, _on_coiffure.bind(-1),  _on_coiffure.bind(1))
	lbl_couleur   = _selector(form, _on_couleur.bind(-1),   _on_couleur.bind(1))
	lbl_tenue     = _selector(form, _on_tenue.bind(-1),     _on_tenue.bind(1))

	# Spacer + erreur + bouton
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	form.add_child(spacer)

	lbl_erreur = Label.new()
	lbl_erreur.text = ""
	lbl_erreur.modulate = Color.RED
	lbl_erreur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	form.add_child(lbl_erreur)

	var btn := Button.new()
	btn.text = "Commencer l'aventure"
	btn.pressed.connect(_on_commencer)
	form.add_child(btn)

	_update_preview()


# ── Helpers UI ────────────────────────────────────────────

func _label(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	parent.add_child(lbl)


func _selector(parent: Control, cb_prev: Callable, cb_next: Callable) -> Label:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)

	var btn_p := Button.new()
	btn_p.text = "<"
	btn_p.pressed.connect(cb_prev)
	hbox.add_child(btn_p)

	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(lbl)

	var btn_n := Button.new()
	btn_n.text = ">"
	btn_n.pressed.connect(cb_next)
	hbox.add_child(btn_n)

	return lbl


# ── Mise à jour de l'aperçu ───────────────────────────────

func _update_preview() -> void:
	sprite_corps.texture   = _atlas("%schar_a_p1_0bas_humn_v%02d.png" % [BASE_PATH, carnation])
	sprite_tenue.texture   = _atlas("%s1out/char_a_p1_1out_fstr_v%02d.png" % [BASE_PATH, tenue + 1])
	sprite_cheveux.texture = _atlas("%s4har/char_a_p1_4har_%s_v%02d.png" % [
		BASE_PATH,
		["bob1", "dap1"][coiffure],
		couleur_cheveux
	])

	lbl_carnation.text = "Carnation  %d / %d" % [carnation + 1, NB_CARNATIONS]
	lbl_coiffure.text  = "Coiffure   %s" % NOMS_COIFFURES[coiffure]
	lbl_couleur.text   = "Couleur cheveux  %d / %d" % [couleur_cheveux + 1, NB_COULEURS]
	lbl_tenue.text     = "Tenue  %d / %d" % [tenue + 1, NB_TENUES]


func _atlas(path: String) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = load(path)
	a.region = FRAME
	return a


# ── Callbacks sélecteurs ─────────────────────────────────

func _on_carnation(dir: int) -> void:
	carnation = (carnation + dir + NB_CARNATIONS) % NB_CARNATIONS
	_update_preview()

func _on_coiffure(dir: int) -> void:
	coiffure = (coiffure + dir + NB_COIFFURES) % NB_COIFFURES
	_update_preview()

func _on_couleur(dir: int) -> void:
	couleur_cheveux = (couleur_cheveux + dir + NB_COULEURS) % NB_COULEURS
	_update_preview()

func _on_tenue(dir: int) -> void:
	tenue = (tenue + dir + NB_TENUES) % NB_TENUES
	_update_preview()


# ── Validation et lancement ──────────────────────────────

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
	GameData.tenue           = tenue

	get_tree().change_scene_to_file("res://monde.tscn")
