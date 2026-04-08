extends CanvasLayer

# ─────────────────────────────────────────────────────────────
#  HUD – Pixels en Provence  (design moderne / pill / minimal)
# ─────────────────────────────────────────────────────────────

const VITESSE_HEURE := 1.0 / 60.0   # 1h de jeu = 60s réelles
const VITESSE_FAIM  := 1.0 / 1800.0
const VITESSE_SOIF  := 1.0 / 1200.0

const SAISONS := ["Printemps", "Été", "Automne", "Hiver"]

const SLOTS := [
	{"cle": "bois",   "nom": "Bois",   "col": Color("#c87830")},
	{"cle": "pierre", "nom": "Pierre", "col": Color("#9a9a9a")},
	{"cle": "herbes", "nom": "Herbes", "col": Color("#50c040")},
	{"cle": "baies",  "nom": "Baies",  "col": Color("#d040d0")},
	{"cle": "eau",    "nom": "Eau",    "col": Color("#30a0f0")},
	{"cle": "viande", "nom": "Viande", "col": Color("#e04040")},
]

var _fill_faim:  ColorRect
var _fill_soif:  ColorRect
var _arc:        Control
var _lbl_heure:  Label
var _lbl_jour:   Label
var _qtys:       Array
var _lbl_alerts: Array   # [faim_alert, soif_alert]


# ── Arc jour/nuit ─────────────────────────────────────────────

class _ArcTemps extends Control:
	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		if size.x == 0 or size.y == 0:
			return
		var cx    := size.x * 0.5
		var cy    := size.y * 0.76
		var r     := minf(size.x * 0.38, size.y * 0.52)
		var ctr   := Vector2(cx, cy)
		var h     := GameData.heure
		var is_day := h >= 6.0 and h < 18.0

		# Prairie sous l'horizon
		draw_rect(Rect2(cx - r - 4, cy, (r + 4) * 2.0, size.y - cy + 4), Color("#1e4a16"))

		# Arc principal (demi-cercle)
		var arc_col := Color("#c8922a", 0.55) if is_day else Color("#6070c0", 0.45)
		draw_arc(ctr, r, PI, TAU, 64, arc_col, 1.5, true)

		# Ligne d'horizon
		draw_line(Vector2(cx - r - 4, cy), Vector2(cx + r + 4, cy),
				arc_col.darkened(0.2), 1.0)

		if is_day:
			var t     := (h - 6.0) / 12.0
			var angle := PI + t * PI
			var sp    := ctr + Vector2(cos(angle), sin(angle)) * r
			var sun_col := _sun_color(h)
			# Halos concentriques
			draw_circle(sp, 14.0, Color(sun_col, 0.08))
			draw_circle(sp, 10.0, Color(sun_col, 0.15))
			draw_circle(sp,  6.5, Color(sun_col, 0.50))
			draw_circle(sp,  4.0, sun_col)
		else:
			# Étoiles
			var rng := RandomNumberGenerator.new()
			rng.seed = 91
			for i in 7:
				var ex := rng.randf_range(cx - r * 0.82, cx + r * 0.82)
				var ey := rng.randf_range(cy - r * 0.90, cy - r * 0.12)
				var ea := rng.randf_range(0.4, 0.9)
				draw_circle(Vector2(ex, ey), rng.randf_range(0.8, 1.8),
						Color(1, 1, 0.9, ea))
			# Lune croissant
			var mp := ctr + Vector2(r * 0.44, -r * 0.58)
			draw_circle(mp, 6.5, Color(0.80, 0.85, 1.00, 0.12))
			draw_circle(mp, 5.5, Color("#c8d4f8"))
			draw_circle(mp + Vector2(3.0, -1.5), 4.0, _sky_bg(h))

	static func _sun_color(h: float) -> Color:
		if h < 8.0 or h > 17.0:
			return Color("#f09020")  # lever/coucher – orange
		return Color("#f8e040")      # journée – jaune

	static func _sky_bg(h: float) -> Color:
		if h < 5.5 or h >= 20.5: return Color("#04080f")
		if h < 7.0:  return Color("#04080f").lerp(Color("#3a1808"), (h - 5.5) / 1.5)
		if h < 9.0:  return Color("#3a1808").lerp(Color("#0e2a44"), (h - 7.0) / 2.0)
		if h < 17.0: return Color("#0e2a44")
		if h < 18.5: return Color("#0e2a44").lerp(Color("#3a1808"), (h - 17.0) / 1.5)
		if h < 20.5: return Color("#3a1808").lerp(Color("#04080f"), (h - 18.5) / 2.0)
		return Color("#04080f")


# ── _ready ────────────────────────────────────────────────────

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var fb := _font("res://assets/fonts/ManaSeedBody.ttf")
	var ft := _font("res://assets/fonts/ManaSeedTitle.ttf")

	_build_perso(root, ft, fb)
	_build_village(root, ft)
	_build_temps(root, fb)
	_build_hotbar(root, fb)


# ── Panel perso – haut-gauche ─────────────────────────────────

func _build_perso(root: Control, ft: Font, fb: Font) -> void:
	var p := _pill(Color("#050d04e0"), 16)
	p.custom_minimum_size = Vector2(215, 78)
	p.set_anchor(SIDE_LEFT,   0.0)
	p.set_anchor(SIDE_RIGHT,  0.0)
	p.set_anchor(SIDE_TOP,    0.0)
	p.set_anchor(SIDE_BOTTOM, 0.0)
	p.offset_left = 12; p.offset_top = 12
	p.offset_right = 227; p.offset_bottom = 90
	root.add_child(p)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 12; vb.offset_right = -12
	vb.offset_top = 8;   vb.offset_bottom = -8
	p.add_child(vb)

	# Nom du perso
	var nom := Label.new()
	nom.text = GameData.nom_joueur if GameData.nom_joueur != "" else "Aventurier"
	if ft: nom.add_theme_font_override("font", ft)
	nom.add_theme_font_size_override("font_size", 15)
	nom.add_theme_color_override("font_color", Color("#ffecd2"))
	nom.add_theme_color_override("font_shadow_color", Color(0,0,0,0.6))
	nom.add_theme_constant_override("shadow_offset_x", 1)
	nom.add_theme_constant_override("shadow_offset_y", 1)
	vb.add_child(nom)

	# Barre faim
	_fill_faim = _barre(vb, fb, "Faim", Color("#e08820"), Color("#f8d040"))

	# Barre soif
	_fill_soif = _barre(vb, fb, "Soif", Color("#1878c8"), Color("#40b8f0"))

	# Alertes (hors panel, juste dessous)
	_lbl_alerts = []
	for info in [["! Faim critique", 94], ["! Soif critique", 110]]:
		var a := Label.new()
		a.text = info[0]
		a.set_anchor(SIDE_LEFT, 0.0); a.set_anchor(SIDE_RIGHT, 0.0)
		a.set_anchor(SIDE_TOP, 0.0);  a.set_anchor(SIDE_BOTTOM, 0.0)
		a.offset_left = 14; a.offset_right = 220
		a.offset_top = info[1]; a.offset_bottom = info[1] + 16
		if fb: a.add_theme_font_override("font", fb)
		a.add_theme_font_size_override("font_size", 11)
		a.add_theme_color_override("font_color", Color("#ff4428"))
		a.visible = false
		root.add_child(a)
		_lbl_alerts.append(a)


func _barre(parent: Control, fb: Font, label: String,
		col_a: Color, col_b: Color) -> ColorRect:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 5)
	parent.add_child(hb)

	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(32, 0)
	if fb: lbl.add_theme_font_override("font", fb)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", col_b)
	hb.add_child(lbl)

	# Fond de barre (pill étroite)
	var bg := Panel.new()
	bg.custom_minimum_size = Vector2(0, 8)
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.12, 0.04, 0.9)
	s.corner_radius_top_left     = 4
	s.corner_radius_top_right    = 4
	s.corner_radius_bottom_left  = 4
	s.corner_radius_bottom_right = 4
	bg.add_theme_stylebox_override("panel", s)
	hb.add_child(bg)

	# Remplissage dégradé simulé (deux rect superposés)
	var fill := ColorRect.new()
	fill.color = col_a
	fill.set_anchor(SIDE_LEFT, 0.0); fill.set_anchor(SIDE_TOP, 0.0)
	fill.set_anchor(SIDE_RIGHT, 1.0); fill.set_anchor(SIDE_BOTTOM, 1.0)
	bg.add_child(fill)

	# Reflet (liseret clair en haut)
	var shine := ColorRect.new()
	shine.color = Color(1, 1, 1, 0.12)
	shine.set_anchor(SIDE_LEFT, 0.0); shine.set_anchor(SIDE_RIGHT, 1.0)
	shine.set_anchor(SIDE_TOP, 0.0);  shine.set_anchor(SIDE_BOTTOM, 0.0)
	shine.offset_bottom = 3
	bg.add_child(shine)

	return fill


# ── Village – haut-centre (floating) ─────────────────────────

func _build_village(root: Control, ft: Font) -> void:
	# Fond pill très discret
	var p := _pill(Color("#030804b0"), 14)
	p.set_anchor(SIDE_LEFT,   0.5); p.set_anchor(SIDE_RIGHT,  0.5)
	p.set_anchor(SIDE_TOP,    0.0); p.set_anchor(SIDE_BOTTOM, 0.0)
	p.offset_left = -150; p.offset_right  =  150
	p.offset_top  =   12; p.offset_bottom =   44
	root.add_child(p)

	var lbl := Label.new()
	lbl.text = GameData.nom_village if GameData.nom_village != "" else "Le Village"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ft: lbl.add_theme_font_override("font", ft)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color("#ffecd2"))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.add_theme_constant_override("shadow_outline_size", 1)
	p.add_child(lbl)


# ── Temps – haut-droite ───────────────────────────────────────

func _build_temps(root: Control, fb: Font) -> void:
	var p := _pill(Color("#050d04e0"), 16)
	p.set_anchor(SIDE_LEFT,   1.0); p.set_anchor(SIDE_RIGHT,  1.0)
	p.set_anchor(SIDE_TOP,    0.0); p.set_anchor(SIDE_BOTTOM, 0.0)
	p.offset_left = -196; p.offset_right  = -12
	p.offset_top  =   12; p.offset_bottom =  96
	root.add_child(p)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 10; hb.offset_right = -10
	hb.offset_top  =  6; hb.offset_bottom = -6
	p.add_child(hb)

	# Arc animé
	_arc = _ArcTemps.new()
	_arc.custom_minimum_size = Vector2(82, 68)
	_arc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hb.add_child(_arc)

	# Séparateur vertical
	var sep := VSeparator.new()
	sep.add_theme_color_override("color", Color("#c8922a", 0.3))
	sep.add_theme_constant_override("separation", 0)
	hb.add_child(sep)

	# Texte calendrier
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	hb.add_child(vb)

	_lbl_heure = _lbl_info(vb, fb, "08:00", 18, Color("#d8e8ff"))
	_lbl_jour  = _lbl_info(vb, fb, "Jour 1 · Printemps", 11, Color("#f0d070"))


func _lbl_info(parent: Control, fb: Font, text: String,
		size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	if fb: l.add_theme_font_override("font", fb)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l


# ── Hotbar – bas-centre (inline pill) ────────────────────────

func _build_hotbar(root: Control, fb: Font) -> void:
	var p := _pill(Color("#050d04e0"), 18)
	p.set_anchor(SIDE_LEFT,   0.5); p.set_anchor(SIDE_RIGHT,  0.5)
	p.set_anchor(SIDE_TOP,    1.0); p.set_anchor(SIDE_BOTTOM, 1.0)
	p.offset_left = -265; p.offset_right  =  265
	p.offset_top  =  -52; p.offset_bottom =  -10
	root.add_child(p)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 0)
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 14; hb.offset_right = -14
	p.add_child(hb)

	_qtys = []
	for i in SLOTS.size():
		var data: Dictionary = SLOTS[i]
		var item  := _slot_inline(data["nom"], data["col"], fb)
		hb.add_child(item)
		_qtys.append(item.find_child("qty", true, false))

		# Séparateur entre les slots (sauf le dernier)
		if i < SLOTS.size() - 1:
			var div := VSeparator.new()
			div.add_theme_color_override("color", Color("#c8922a", 0.18))
			div.add_theme_constant_override("separation", 0)
			hb.add_child(div)


func _slot_inline(nom: String, col: Color, fb: Font) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(72, 0)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 6; hb.offset_right = -6
	c.add_child(hb)

	# Point coloré (icône ressource)
	var dot_wrap := Control.new()
	dot_wrap.custom_minimum_size = Vector2(14, 0)
	dot_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(dot_wrap)

	var dot := ColorRect.new()
	dot.color = col
	dot.custom_minimum_size = Vector2(8, 8)
	dot.set_anchor(SIDE_LEFT, 0.5); dot.set_anchor(SIDE_RIGHT, 0.5)
	dot.set_anchor(SIDE_TOP, 0.5);  dot.set_anchor(SIDE_BOTTOM, 0.5)
	dot.offset_left = -4; dot.offset_right = 4
	dot.offset_top  = -4; dot.offset_bottom = 4
	dot_wrap.add_child(dot)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", -1)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	hb.add_child(vb)

	var lbl_nom := Label.new()
	lbl_nom.text = nom
	if fb: lbl_nom.add_theme_font_override("font", fb)
	lbl_nom.add_theme_font_size_override("font_size", 9)
	lbl_nom.add_theme_color_override("font_color", col.lightened(0.25))
	vb.add_child(lbl_nom)

	var lbl_qty := Label.new()
	lbl_qty.name = "qty"
	lbl_qty.text = "0"
	if fb: lbl_qty.add_theme_font_override("font", fb)
	lbl_qty.add_theme_font_size_override("font_size", 15)
	lbl_qty.add_theme_color_override("font_color", Color("#ffecd2"))
	vb.add_child(lbl_qty)

	return c


# ── _process ──────────────────────────────────────────────────

func _process(delta: float) -> void:
	GameData.heure += delta * VITESSE_HEURE * 24.0
	if GameData.heure >= 24.0:
		GameData.heure -= 24.0
		GameData.jour  += 1
		if GameData.jour > 90:
			GameData.jour   = 1
			GameData.saison = (GameData.saison + 1) % 4

	GameData.faim = maxf(0.0, GameData.faim - delta * VITESSE_FAIM)
	GameData.soif = maxf(0.0, GameData.soif - delta * VITESSE_SOIF)

	_update()


func _update() -> void:
	# Barres (resize direct)
	var pw_faim: float = (_fill_faim.get_parent() as Control).size.x
	var pw_soif: float = (_fill_soif.get_parent() as Control).size.x
	_fill_faim.size.x = pw_faim * GameData.faim
	_fill_soif.size.x = pw_soif * GameData.soif

	# Couleur critique
	var crit_faim := GameData.faim < 0.25
	var crit_soif := GameData.soif < 0.25
	_fill_faim.color = Color("#ff3010") if crit_faim else Color("#e08820")
	_fill_soif.color = Color("#ff3010") if crit_soif else Color("#1878c8")
	_lbl_alerts[0].visible = crit_faim
	_lbl_alerts[1].visible = crit_soif

	# Arc + calendrier
	_arc.queue_redraw()
	var h := int(GameData.heure)
	var m := int(fmod(GameData.heure, 1.0) * 60.0)
	_lbl_heure.text = "%02d:%02d" % [h, m]
	_lbl_jour.text  = "Jour %d  ·  %s" % [GameData.jour, SAISONS[GameData.saison]]

	# Hotbar
	for i in SLOTS.size():
		var qty: Label = _qtys[i]
		if qty:
			qty.text = str(GameData.ressources.get(SLOTS[i]["cle"], 0))


# ── Helpers ───────────────────────────────────────────────────

func _pill(bg: Color, radius: int) -> Panel:
	var p := Panel.new()
	var s := StyleBoxFlat.new()
	s.bg_color     = bg
	s.border_color = Color("#c8922a", 0.28)
	s.border_width_left   = 1; s.border_width_right  = 1
	s.border_width_top    = 1; s.border_width_bottom = 1
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	s.shadow_color  = Color(0, 0, 0, 0.45)
	s.shadow_size   = 8
	s.shadow_offset = Vector2(0, 3)
	p.add_theme_stylebox_override("panel", s)
	return p


func _font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path)
	return null
