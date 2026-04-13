extends CanvasLayer

# ─────────────────────────────────────────────────────────────
#  HUD – Pixels en Provence
# ─────────────────────────────────────────────────────────────

const VITESSE_HEURE := 1.0 / 60.0
const VITESSE_FAIM  := 1.0 / 1800.0
const VITESSE_SOIF  := 1.0 / 1200.0
const SAISONS       := ["Printemps", "Été", "Automne", "Hiver"]

const SLOT_SIZE := 42
const SLOT_GAP  := 4

var _fill_faim:  ColorRect
var _fill_soif:  ColorRect
var _arc:        Control
var _lbl_heure:  Label
var _lbl_jour:   Label
var _lbl_alerts: Array

var _hotbar_panels:   Array   # 9 Panels (hotbar toujours visible)
var _inv_panels:      Array   # 27 Panels (grille inventaire)
var _inv_hb_panels:   Array   # 9 Panels (hotbar miroir dans l'inventaire)
var _inv_panel:       Control # overlay inventaire

var _curseur_item             # null ou {"id": String, "qty": int}
var _curseur_ctrl:   Control


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

		draw_rect(Rect2(cx - r - 4, cy, (r + 4) * 2.0, size.y - cy + 4), Color("#1e4a16"))
		var arc_col := Color("#c8922a", 0.55) if is_day else Color("#6070c0", 0.45)
		draw_arc(ctr, r, PI, TAU, 64, arc_col, 1.5, true)
		draw_line(Vector2(cx - r - 4, cy), Vector2(cx + r + 4, cy),
				arc_col.darkened(0.2), 1.0)

		if is_day:
			var t     := (h - 6.0) / 12.0
			var angle := PI + t * PI
			var sp    := ctr + Vector2(cos(angle), sin(angle)) * r
			var sun_col := _sun_color(h)
			draw_circle(sp, 14.0, Color(sun_col, 0.08))
			draw_circle(sp, 10.0, Color(sun_col, 0.15))
			draw_circle(sp,  6.5, Color(sun_col, 0.50))
			draw_circle(sp,  4.0, sun_col)
		else:
			var rng := RandomNumberGenerator.new()
			rng.seed = 91
			for i in 7:
				var ex := rng.randf_range(cx - r * 0.82, cx + r * 0.82)
				var ey := rng.randf_range(cy - r * 0.90, cy - r * 0.12)
				var ea := rng.randf_range(0.4, 0.9)
				draw_circle(Vector2(ex, ey), rng.randf_range(0.8, 1.8),
						Color(1, 1, 0.9, ea))
			var mp := ctr + Vector2(r * 0.44, -r * 0.58)
			draw_circle(mp, 6.5, Color(0.80, 0.85, 1.00, 0.12))
			draw_circle(mp, 5.5, Color("#c8d4f8"))
			draw_circle(mp + Vector2(3.0, -1.5), 4.0, _sky_bg(h))

	static func _sun_color(h: float) -> Color:
		if h < 8.0 or h > 17.0: return Color("#f09020")
		return Color("#f8e040")

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
	_build_inventaire(root, ft, fb)
	_build_curseur(root, fb)


# ── Panel perso – haut-gauche ─────────────────────────────────

func _build_perso(root: Control, ft: Font, fb: Font) -> void:
	var p := _pill(Color("#050d04e0"), 16)
	p.custom_minimum_size = Vector2(215, 78)
	p.set_anchor(SIDE_LEFT,   0.0); p.set_anchor(SIDE_RIGHT,  0.0)
	p.set_anchor(SIDE_TOP,    0.0); p.set_anchor(SIDE_BOTTOM, 0.0)
	p.offset_left = 12; p.offset_top = 12
	p.offset_right = 227; p.offset_bottom = 90
	root.add_child(p)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 12; vb.offset_right = -12
	vb.offset_top = 8;   vb.offset_bottom = -8
	p.add_child(vb)

	var nom := Label.new()
	nom.text = GameData.nom_joueur if GameData.nom_joueur != "" else "Aventurier"
	if ft: nom.add_theme_font_override("font", ft)
	nom.add_theme_font_size_override("font_size", 15)
	nom.add_theme_color_override("font_color", Color("#ffecd2"))
	nom.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	nom.add_theme_constant_override("shadow_offset_x", 1)
	nom.add_theme_constant_override("shadow_offset_y", 1)
	vb.add_child(nom)

	_fill_faim = _barre(vb, fb, "Faim", Color("#e08820"), Color("#f8d040"))
	_fill_soif = _barre(vb, fb, "Soif", Color("#1878c8"), Color("#40b8f0"))

	_lbl_alerts = []
	for info in [["! Faim critique", 94], ["! Soif critique", 110]]:
		var a := Label.new()
		a.text = info[0]
		a.set_anchor(SIDE_LEFT, 0.0); a.set_anchor(SIDE_RIGHT,  0.0)
		a.set_anchor(SIDE_TOP,  0.0); a.set_anchor(SIDE_BOTTOM, 0.0)
		a.offset_left = 14; a.offset_right  = 220
		a.offset_top  = info[1]; a.offset_bottom = info[1] + 16
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

	var bg := Panel.new()
	bg.custom_minimum_size = Vector2(0, 8)
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.12, 0.04, 0.9)
	s.corner_radius_top_left     = 4; s.corner_radius_top_right    = 4
	s.corner_radius_bottom_left  = 4; s.corner_radius_bottom_right = 4
	bg.add_theme_stylebox_override("panel", s)
	hb.add_child(bg)

	var fill := ColorRect.new()
	fill.color = col_a
	fill.set_anchor(SIDE_LEFT,   0.0); fill.set_anchor(SIDE_TOP,    0.0)
	fill.set_anchor(SIDE_RIGHT,  1.0); fill.set_anchor(SIDE_BOTTOM, 1.0)
	bg.add_child(fill)

	var shine := ColorRect.new()
	shine.color = Color(1, 1, 1, 0.12)
	shine.set_anchor(SIDE_LEFT,   0.0); shine.set_anchor(SIDE_RIGHT,  1.0)
	shine.set_anchor(SIDE_TOP,    0.0); shine.set_anchor(SIDE_BOTTOM, 0.0)
	shine.offset_bottom = 3
	bg.add_child(shine)

	return fill


# ── Village – haut-centre ─────────────────────────────────────

func _build_village(root: Control, ft: Font) -> void:
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

	_arc = _ArcTemps.new()
	_arc.custom_minimum_size = Vector2(82, 68)
	_arc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hb.add_child(_arc)

	var sep := VSeparator.new()
	sep.add_theme_color_override("color", Color("#c8922a", 0.3))
	sep.add_theme_constant_override("separation", 0)
	hb.add_child(sep)

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


# ── Hotbar – bas-centre ───────────────────────────────────────

func _build_hotbar(root: Control, fb: Font) -> void:
	var nb      := GameData.TAILLE_HOTBAR
	var total_w := nb * SLOT_SIZE + (nb - 1) * SLOT_GAP
	var pill_w  := total_w + 24   # 12 px padding de chaque côté

	var p := _pill(Color("#050d04e0"), 12)
	p.set_anchor(SIDE_LEFT,   0.5); p.set_anchor(SIDE_RIGHT,  0.5)
	p.set_anchor(SIDE_TOP,    1.0); p.set_anchor(SIDE_BOTTOM, 1.0)
	p.offset_left   = -pill_w / 2; p.offset_right  = pill_w / 2
	p.offset_top    = -58;          p.offset_bottom = -10
	root.add_child(p)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", SLOT_GAP)
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 12; hb.offset_right = -12
	hb.offset_top  =  6; hb.offset_bottom = -6
	p.add_child(hb)

	_hotbar_panels = []
	for i in nb:
		var slot := _creer_slot(fb)
		hb.add_child(slot)
		_hotbar_panels.append(slot)


# ── Inventaire – overlay ──────────────────────────────────────

func _build_inventaire(root: Control, ft: Font, fb: Font) -> void:
	_inv_panels    = []
	_inv_hb_panels = []

	# Fond semi-transparent (capture tous les clics)
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.62)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay)

	# Calcul de la taille du panneau central
	var nb_cols := GameData.TAILLE_HOTBAR
	var inner_w := nb_cols * SLOT_SIZE + (nb_cols - 1) * SLOT_GAP
	var panel_w := inner_w + 40   # 20 px padding de chaque côté

	var p := _pill(Color("#050d04f2"), 20)
	p.set_anchor(SIDE_LEFT,   0.5); p.set_anchor(SIDE_RIGHT,  0.5)
	p.set_anchor(SIDE_TOP,    0.5); p.set_anchor(SIDE_BOTTOM, 0.5)
	p.offset_left   = -panel_w / 2; p.offset_right  = panel_w / 2
	p.offset_top    = -190;          p.offset_bottom =  190
	overlay.add_child(p)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 20; vb.offset_right  = -20
	vb.offset_top  = 14; vb.offset_bottom = -14
	p.add_child(vb)

	# En-tête titre + bouton X
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 0)
	vb.add_child(header)

	var titre := Label.new()
	titre.text = "Inventaire"
	titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if ft: titre.add_theme_font_override("font", ft)
	titre.add_theme_font_size_override("font_size", 20)
	titre.add_theme_color_override("font_color", Color("#ffecd2"))
	header.add_child(titre)

	var close_btn := Button.new()
	close_btn.text = "X"
	if fb: close_btn.add_theme_font_override("font", fb)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color",        Color("#ffecd2"))
	close_btn.add_theme_color_override("font_hover_color",  Color("#ff6644"))
	for state in ["normal", "hover", "pressed", "focus"]:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0, 0, 0, 0)
		close_btn.add_theme_stylebox_override(state, s)
	close_btn.pressed.connect(_toggle_inventaire)
	header.add_child(close_btn)

	# Séparateur haut
	var sep1 := HSeparator.new()
	sep1.add_theme_color_override("color", Color("#c8922a", 0.35))
	vb.add_child(sep1)

	# Grille inventaire (3 lignes × 9 colonnes)
	var grid := GridContainer.new()
	grid.columns = nb_cols
	grid.add_theme_constant_override("h_separation", SLOT_GAP)
	grid.add_theme_constant_override("v_separation", SLOT_GAP)
	vb.add_child(grid)

	for i in GameData.TAILLE_INV:
		var idx := i
		var slot := _creer_slot(fb)
		slot.gui_input.connect(func(ev): _on_inv_click(ev, idx))
		grid.add_child(slot)
		_inv_panels.append(slot)

	# Séparateur bas (avant hotbar miroir)
	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("color", Color("#c8922a", 0.22))
	vb.add_child(sep2)

	# Hotbar miroir
	var hb_row := HBoxContainer.new()
	hb_row.add_theme_constant_override("separation", SLOT_GAP)
	vb.add_child(hb_row)

	for i in GameData.TAILLE_HOTBAR:
		var idx := i
		var slot := _creer_slot(fb)
		slot.gui_input.connect(func(ev): _on_hotbar_click(ev, idx))
		hb_row.add_child(slot)
		_inv_hb_panels.append(slot)

	# Légende de contrôles
	var hint := Label.new()
	hint.text = "[ I ] fermer  ·  clic gauche : déplacer  ·  clic droit : poser 1  ·  1–9 : sélectionner"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if fb: hint.add_theme_font_override("font", fb)
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color("#c8922a", 0.60))
	vb.add_child(hint)

	overlay.visible = false
	_inv_panel = overlay


# ── Création d'un slot ────────────────────────────────────────

func _creer_slot(fb: Font) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	p.mouse_filter = Control.MOUSE_FILTER_STOP

	var s_normal := _style_slot(false)
	var s_sel    := _style_slot(true)
	p.set_meta("sn", s_normal)
	p.set_meta("ss", s_sel)
	p.add_theme_stylebox_override("panel", s_normal)

	# Icône colorée (centré dans le slot)
	var icon := ColorRect.new()
	icon.name = "icon"
	icon.custom_minimum_size = Vector2(24, 24)
	icon.set_anchor(SIDE_LEFT,   0.5); icon.set_anchor(SIDE_RIGHT,  0.5)
	icon.set_anchor(SIDE_TOP,    0.5); icon.set_anchor(SIDE_BOTTOM, 0.5)
	icon.offset_left = -12; icon.offset_right  = 12
	icon.offset_top  = -12; icon.offset_bottom = 12
	icon.visible = false
	p.add_child(icon)

	# Quantité (bas-droite du slot)
	var qty := Label.new()
	qty.name = "qty"
	qty.set_anchor(SIDE_LEFT,   0.0); qty.set_anchor(SIDE_RIGHT,  1.0)
	qty.set_anchor(SIDE_TOP,    0.0); qty.set_anchor(SIDE_BOTTOM, 1.0)
	qty.offset_left = 2; qty.offset_right  = -2
	qty.offset_top  = 2; qty.offset_bottom = -2
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
	if fb: qty.add_theme_font_override("font", fb)
	qty.add_theme_font_size_override("font_size", 10)
	qty.add_theme_color_override("font_color",        Color("#ffffff"))
	qty.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	qty.add_theme_constant_override("shadow_offset_x", 1)
	qty.add_theme_constant_override("shadow_offset_y", 1)
	qty.visible = false
	p.add_child(qty)

	return p


func _style_slot(selected: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#0c1a08") if not selected else Color("#1e3010")
	if selected:
		s.border_color        = Color("#f0d060")
		s.border_width_left   = 2; s.border_width_right  = 2
		s.border_width_top    = 2; s.border_width_bottom = 2
	else:
		s.border_color        = Color("#3a4a30", 0.7)
		s.border_width_left   = 1; s.border_width_right  = 1
		s.border_width_top    = 1; s.border_width_bottom = 1
	s.corner_radius_top_left     = 4; s.corner_radius_top_right    = 4
	s.corner_radius_bottom_left  = 4; s.corner_radius_bottom_right = 4
	return s


func _maj_slot(panel: Panel, slot_data, selected: bool = false) -> void:
	var icon: ColorRect = panel.find_child("icon", true, false)
	var qty:  Label     = panel.find_child("qty",  true, false)

	panel.add_theme_stylebox_override("panel",
			panel.get_meta("ss") if selected else panel.get_meta("sn"))

	if slot_data != null and GameData.ITEMS.has(slot_data["id"]):
		var info: Dictionary = GameData.ITEMS[slot_data["id"]]
		icon.color   = info["col"]
		icon.visible = true
		var q: int   = slot_data["qty"]
		qty.text    = str(q) if q > 1 else ""
		qty.visible = q > 1
	else:
		icon.visible = false
		qty.visible  = false


# ── Curseur (item tenu par la souris pendant le déplacement) ──

func _build_curseur(root: Control, fb: Font) -> void:
	_curseur_item = null

	_curseur_ctrl = Control.new()
	_curseur_ctrl.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	_curseur_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curseur_ctrl.z_index = 100
	_curseur_ctrl.visible = false
	root.add_child(_curseur_ctrl)

	var icon := ColorRect.new()
	icon.name = "icon"
	icon.color = Color.WHITE
	icon.set_anchor(SIDE_LEFT,   0.0); icon.set_anchor(SIDE_RIGHT,  0.0)
	icon.set_anchor(SIDE_TOP,    0.0); icon.set_anchor(SIDE_BOTTOM, 0.0)
	icon.offset_right  = 28
	icon.offset_bottom = 28
	_curseur_ctrl.add_child(icon)

	var qty := Label.new()
	qty.name = "qty"
	qty.set_anchor(SIDE_LEFT,   0.0); qty.set_anchor(SIDE_RIGHT,  0.0)
	qty.set_anchor(SIDE_TOP,    0.0); qty.set_anchor(SIDE_BOTTOM, 0.0)
	qty.offset_left   = 14; qty.offset_right  = 14 + 24
	qty.offset_top    = 16; qty.offset_bottom = 16 + 14
	if fb: qty.add_theme_font_override("font", fb)
	qty.add_theme_font_size_override("font_size", 11)
	qty.add_theme_color_override("font_color",        Color("#ffffff"))
	qty.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	qty.add_theme_constant_override("shadow_offset_x", 1)
	qty.add_theme_constant_override("shadow_offset_y", 1)
	_curseur_ctrl.add_child(qty)


func _maj_curseur() -> void:
	if _curseur_item == null:
		_curseur_ctrl.visible = false
		return
	_curseur_ctrl.visible = true
	var icon: ColorRect = _curseur_ctrl.find_child("icon", true, false)
	var qty:  Label     = _curseur_ctrl.find_child("qty",  true, false)
	if GameData.ITEMS.has(_curseur_item["id"]):
		icon.color = GameData.ITEMS[_curseur_item["id"]]["col"]
	var q: int = _curseur_item["qty"]
	qty.text = str(q) if q > 1 else ""


# ── Interactions slots ────────────────────────────────────────

func _on_inv_click(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton and (event as InputEventMouseButton).pressed):
		return
	_interagir_slot(event as InputEventMouseButton, GameData.slots_inventaire, index)
	_maj_tous_slots()


func _on_hotbar_click(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton and (event as InputEventMouseButton).pressed):
		return
	_interagir_slot(event as InputEventMouseButton, GameData.slots_hotbar, index)
	_maj_tous_slots()


func _interagir_slot(mb: InputEventMouseButton, slots: Array, index: int) -> void:
	var cur = slots[index]

	if mb.button_index == MOUSE_BUTTON_LEFT:
		if _curseur_item == null:
			# Prendre tout le slot
			if cur != null:
				_curseur_item = cur.duplicate()
				slots[index]  = null
		else:
			if cur == null:
				# Poser tout
				slots[index]  = _curseur_item.duplicate()
				_curseur_item = null
			elif cur["id"] == _curseur_item["id"]:
				# Fusionner les stacks
				var ms: int  = GameData.ITEMS[cur["id"]]["max_stack"]
				var tot: int = cur["qty"] + _curseur_item["qty"]
				slots[index]["qty"] = mini(tot, ms)
				var reste: int = tot - slots[index]["qty"]
				_curseur_item = {"id": _curseur_item["id"], "qty": reste} if reste > 0 else null
			else:
				# Échanger
				slots[index]  = _curseur_item.duplicate()
				_curseur_item = cur.duplicate()

	elif mb.button_index == MOUSE_BUTTON_RIGHT:
		if _curseur_item == null:
			# Prendre la moitié (arrondi au-dessus)
			if cur != null:
				var half: int = ceili(cur["qty"] / 2.0)
				_curseur_item       = {"id": cur["id"], "qty": half}
				slots[index]["qty"] -= half
				if slots[index]["qty"] <= 0:
					slots[index] = null
		else:
			# Poser 1 seule unité
			if cur == null:
				slots[index]  = {"id": _curseur_item["id"], "qty": 1}
				_curseur_item["qty"] -= 1
				if _curseur_item["qty"] <= 0:
					_curseur_item = null
			elif cur["id"] == _curseur_item["id"]:
				var ms: int = GameData.ITEMS[cur["id"]]["max_stack"]
				if cur["qty"] < ms:
					slots[index]["qty"] += 1
					_curseur_item["qty"] -= 1
					if _curseur_item["qty"] <= 0:
						_curseur_item = null


# ── Toggle inventaire ─────────────────────────────────────────

func _toggle_inventaire() -> void:
	GameData.inventaire_ouvert = not GameData.inventaire_ouvert
	_inv_panel.visible = GameData.inventaire_ouvert

	# Si on ferme avec un item en main → le remettre dans l'inventaire
	if not GameData.inventaire_ouvert and _curseur_item != null:
		GameData.ajouter_item(_curseur_item["id"], _curseur_item["qty"])
		_curseur_item = null
		_maj_curseur()

	if GameData.inventaire_ouvert:
		_maj_tous_slots()


func _maj_tous_slots() -> void:
	for i in _inv_panels.size():
		_maj_slot(_inv_panels[i], GameData.slots_inventaire[i])
	for i in _inv_hb_panels.size():
		_maj_slot(_inv_hb_panels[i], GameData.slots_hotbar[i], i == GameData.slot_actif)
	_maj_hotbar()
	_maj_curseur()


func _maj_hotbar() -> void:
	for i in _hotbar_panels.size():
		_maj_slot(_hotbar_panels[i], GameData.slots_hotbar[i], i == GameData.slot_actif)


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

	# Le curseur-item suit la souris (inventaire ouvert uniquement)
	if GameData.inventaire_ouvert and _curseur_item != null:
		var mp := get_viewport().get_mouse_position()
		_curseur_ctrl.position = mp - Vector2(14, 14)


func _update() -> void:
	# Barres faim / soif
	var pw_faim: float = (_fill_faim.get_parent() as Control).size.x
	var pw_soif: float = (_fill_soif.get_parent() as Control).size.x
	_fill_faim.size.x = pw_faim * GameData.faim
	_fill_soif.size.x = pw_soif * GameData.soif

	var crit_faim := GameData.faim < 0.25
	var crit_soif := GameData.soif < 0.25
	_fill_faim.color = Color("#ff3010") if crit_faim else Color("#e08820")
	_fill_soif.color = Color("#ff3010") if crit_soif else Color("#1878c8")
	_lbl_alerts[0].visible = crit_faim
	_lbl_alerts[1].visible = crit_soif

	# Arc + heure + saison
	_arc.queue_redraw()
	var h := int(GameData.heure)
	var m := int(fmod(GameData.heure, 1.0) * 60.0)
	_lbl_heure.text = "%02d:%02d" % [h, m]
	_lbl_jour.text  = "Jour %d  ·  %s" % [GameData.jour, SAISONS[GameData.saison]]

	# Hotbar (toujours à jour)
	_maj_hotbar()


# ── Input ─────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	# physical_keycode = position physique de la touche (fonctionne sur AZERTY)
	var phys := (event as InputEventKey).physical_keycode

	match phys:
		KEY_I:
			_toggle_inventaire()
			get_viewport().set_input_as_handled()

		KEY_ESCAPE:
			if GameData.inventaire_ouvert:
				_toggle_inventaire()
				get_viewport().set_input_as_handled()

		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
			GameData.slot_actif = phys - KEY_1
			_maj_hotbar()
			if GameData.inventaire_ouvert:
				for i in _inv_hb_panels.size():
					_maj_slot(_inv_hb_panels[i], GameData.slots_hotbar[i],
							  i == GameData.slot_actif)
			get_viewport().set_input_as_handled()


# ── Helpers ───────────────────────────────────────────────────

func _pill(bg: Color, radius: int) -> Panel:
	var p := Panel.new()
	var s := StyleBoxFlat.new()
	s.bg_color     = bg
	s.border_color = Color("#c8922a", 0.28)
	s.border_width_left   = 1; s.border_width_right  = 1
	s.border_width_top    = 1; s.border_width_bottom = 1
	s.corner_radius_top_left     = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius; s.corner_radius_bottom_right = radius
	s.shadow_color  = Color(0, 0, 0, 0.45)
	s.shadow_size   = 8
	s.shadow_offset = Vector2(0, 3)
	p.add_theme_stylebox_override("panel", s)
	return p


func _font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path)
	return null
