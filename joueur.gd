extends CharacterBody2D

# ─────────────────────────────────────────────────────────────
#  Joueur – Pixels en Provence
#  Spritesheet Mana Seed p1 (512×512, frames 64×64) :
#    Lignes 0-3  → idle  (col 0)  : sud / ouest / est / nord
#    Lignes 4-7  → walk  (col 0-5): sud / ouest / est / nord
# ─────────────────────────────────────────────────────────────

const BASE_PATH      := "res://assets/personnage/mana_seed_demo/char_a_p1/"
const BASE_PATH_ONE3 := "res://assets/personnage/mana_seed_demo/char_a_pONE3/"
const VITESSE     := 90.0
const FPS_MARCHE  := 7.4
const FPS_ATTAQUE := 10.0

const LIGNE_IDLE   := { "south": 0, "north": 1, "east": 2, "west": 3 }
const LIGNE_WALK   := { "south": 4, "north": 5, "east": 6, "west": 7 }
const LIGNE_ATTACK := { "south": 0, "north": 1, "east": 2, "west": 3 }

# Timing slash 1 conseillé par Mana Seed : 160/65/65/200 ms
# Base 100 ms (10 FPS) → durations multipliés
const DUR_ATTAQUE := [1.6, 0.65, 0.65, 2.0]

const TENUE_IDS := ["fstr", "pfpn", "boxr", "undi"]
const TENUE_MAX := [5, 5, 1, 1]

var spr_corps:   AnimatedSprite2D
var spr_tenue:   AnimatedSprite2D
var spr_cheveux: AnimatedSprite2D
var spr_chapeau: AnimatedSprite2D
var spr_arme:    AnimatedSprite2D

var _armes_frames: Dictionary = {}   # { "ax01": SpriteFrames, "sw01": SpriteFrames, ... }
var _dir := "south"
var _attaque_en_cours := false


func _ready() -> void:
	collision_layer = 1
	collision_mask  = 1   # Uniquement le monde, pas les animaux (couche 2)
	_creer_sprites()
	_ajouter_camera()
	z_as_relative = false


func _physics_process(_delta: float) -> void:
	if GameData.inventaire_ouvert or _attaque_en_cours:
		velocity = Vector2.ZERO
		move_and_slide()
		z_index = int(global_position.y)
		return

	# Support fleches + ZQSD (AZERTY)
	var ix := 0.0
	var iy := 0.0
	if Input.is_action_pressed("ui_left")  or Input.is_key_pressed(KEY_Q):
		ix -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		ix += 1.0
	if Input.is_action_pressed("ui_up")    or Input.is_key_pressed(KEY_Z):
		iy -= 1.0
	if Input.is_action_pressed("ui_down")  or Input.is_key_pressed(KEY_S):
		iy += 1.0

	var input := Vector2(ix, iy).normalized()
	velocity = input * VITESSE
	move_and_slide()

	z_index = int(global_position.y)

	if input != Vector2.ZERO:
		if abs(input.x) >= abs(input.y):
			_dir = "east" if input.x > 0 else "west"
		else:
			_dir = "south" if input.y > 0 else "north"
		_jouer("walk_" + _dir)
	else:
		_jouer("idle_" + _dir)


func _jouer(anim: String) -> void:
	for spr: AnimatedSprite2D in [spr_corps, spr_tenue, spr_cheveux, spr_chapeau]:
		if spr != null and spr.sprite_frames != null:
			if spr.sprite_frames.has_animation(anim) and spr.animation != anim:
				spr.play(anim)


# ── Construction des sprites ──────────────────────────────────

func _creer_sprites() -> void:
	var hair_names := ["bob1", "dap1"]
	var hair_name: String = hair_names[GameData.coiffure % hair_names.size()]

	# Decoder la tenue (type * 100 + variante)
	@warning_ignore("integer_division")
	var tenue_type := GameData.tenue / 100
	var tenue_var  := GameData.tenue % 100
	if tenue_type >= TENUE_IDS.size():
		tenue_type = 0
	var tenue_id: String = TENUE_IDS[tenue_type]
	var tenue_v: int = (tenue_var % int(TENUE_MAX[tenue_type])) + 1

	var corps_path   := BASE_PATH + "char_a_p1_0bas_humn_v%02d.png" % GameData.carnation
	var tenue_path   := BASE_PATH + "1out/char_a_p1_1out_%s_v%02d.png" % [tenue_id, tenue_v]
	var cheveux_path := BASE_PATH + "4har/char_a_p1_4har_%s_v%02d.png" % [hair_name, GameData.couleur_cheveux]

	spr_corps   = _construire_sprite(corps_path,   0)
	spr_tenue   = _construire_sprite(tenue_path,   1)
	spr_cheveux = _construire_sprite(cheveux_path, 2)

	add_child(spr_corps)
	add_child(spr_tenue)
	add_child(spr_cheveux)

	# Chapeau (optionnel) — TODO: stocker dans GameData si besoin
	spr_chapeau = null

	# Animations d'attaque (pages pONE3 - slash 1)
	var corps_one3_path   := BASE_PATH_ONE3 + "char_a_pONE3_0bas_humn_v%02d.png" % GameData.carnation
	var tenue_one3_path   := BASE_PATH_ONE3 + "1out/char_a_pONE3_1out_%s_v%02d.png" % [tenue_id, tenue_v]
	var cheveux_one3_path := BASE_PATH_ONE3 + "4har/char_a_pONE3_4har_%s_v%02d.png" % [hair_name, GameData.couleur_cheveux]
	_ajouter_anims_attaque(spr_corps,   corps_one3_path)
	_ajouter_anims_attaque(spr_tenue,   tenue_one3_path)
	_ajouter_anims_attaque(spr_cheveux, cheveux_one3_path)

	# Sprite d'arme (change de SpriteFrames selon l'outil)
	_preparer_armes_frames()
	spr_arme = AnimatedSprite2D.new()
	spr_arme.z_index = 3
	spr_arme.visible = false
	add_child(spr_arme)

	# Fin d'animation d'attaque → retour à l'idle
	spr_corps.animation_finished.connect(_on_anim_finished)


func _ajouter_anims_attaque(spr: AnimatedSprite2D, tex_path: String) -> void:
	if spr == null or not ResourceLoader.exists(tex_path):
		return
	var tex := load(tex_path) as Texture2D
	if tex == null:
		return
	for dir: String in LIGNE_ATTACK:
		var row: int = LIGNE_ATTACK[dir]
		var anim := "attack_" + dir
		if not spr.sprite_frames.has_animation(anim):
			spr.sprite_frames.add_animation(anim)
		spr.sprite_frames.set_animation_loop(anim, false)
		spr.sprite_frames.set_animation_speed(anim, FPS_ATTAQUE)
		for col in 4:
			spr.sprite_frames.add_frame(anim, _atlas(tex, col, row), DUR_ATTAQUE[col])


func _preparer_armes_frames() -> void:
	for arme in ["ax01", "sw01"]:
		var tex_path := BASE_PATH_ONE3 + "6tla/char_a_pONE3_6tla_%s_v01.png" % arme
		if not ResourceLoader.exists(tex_path):
			continue
		var tex := load(tex_path) as Texture2D
		if tex == null:
			continue
		var sf := SpriteFrames.new()
		sf.remove_animation("default")
		for dir: String in LIGNE_ATTACK:
			var row: int = LIGNE_ATTACK[dir]
			var anim := "attack_" + dir
			sf.add_animation(anim)
			sf.set_animation_loop(anim, false)
			sf.set_animation_speed(anim, FPS_ATTAQUE)
			for col in 4:
				sf.add_frame(anim, _atlas(tex, col, row), DUR_ATTAQUE[col])
		_armes_frames[arme] = sf


func _jouer_attaque(arme_code: String) -> void:
	if _attaque_en_cours:
		return
	_attaque_en_cours = true

	if _armes_frames.has(arme_code):
		spr_arme.sprite_frames = _armes_frames[arme_code]
		spr_arme.visible = true
	else:
		spr_arme.visible = false

	var anim := "attack_" + _dir
	for spr: AnimatedSprite2D in [spr_corps, spr_tenue, spr_cheveux, spr_chapeau, spr_arme]:
		if spr != null and spr.sprite_frames != null and spr.sprite_frames.has_animation(anim):
			spr.stop()
			spr.play(anim)


func _on_anim_finished() -> void:
	if not _attaque_en_cours:
		return
	_attaque_en_cours = false
	spr_arme.visible = false
	_jouer("idle_" + _dir)


func _construire_sprite(tex_path: String, z: int) -> AnimatedSprite2D:
	if not ResourceLoader.exists(tex_path):
		return null
	var tex := load(tex_path) as Texture2D
	if tex == null:
		return null
	var sf  := SpriteFrames.new()
	sf.remove_animation("default")

	# Idle : 1 frame par direction (col 0, lignes 0-3)
	for dir: String in LIGNE_IDLE:
		var row: int  = LIGNE_IDLE[dir]
		var anim      := "idle_" + dir
		sf.add_animation(anim)
		sf.set_animation_loop(anim, true)
		sf.set_animation_speed(anim, 1.0)
		sf.add_frame(anim, _atlas(tex, 0, row))

	# Walk : 6 frames par direction (lignes 4-7, cols 0-5)
	for dir: String in LIGNE_WALK:
		var row: int  = LIGNE_WALK[dir]
		var anim      := "walk_" + dir
		sf.add_animation(anim)
		sf.set_animation_loop(anim, true)
		sf.set_animation_speed(anim, FPS_MARCHE)
		for col in 6:
			sf.add_frame(anim, _atlas(tex, col, row))

	var spr             := AnimatedSprite2D.new()
	spr.sprite_frames   = sf
	spr.z_index         = z
	spr.play("idle_south")
	return spr


func _atlas(tex: Texture2D, col: int, row: int) -> AtlasTexture:
	var at    := AtlasTexture.new()
	at.atlas  = tex
	at.region = Rect2(col * 64, row * 64, 64, 64)
	return at


var _cam: Camera2D
const ZOOM_MIN := 0.5
const ZOOM_MAX := 4.0
const ZOOM_STEP := 0.1

func _ajouter_camera() -> void:
	_cam = Camera2D.new()
	_cam.position_smoothing_enabled = true
	_cam.position_smoothing_speed   = 5.0
	_cam.zoom                       = Vector2(2, 2)
	# Map 160×90 tuiles × 16px = 2560×1440px
	_cam.limit_left   = 0
	_cam.limit_top    = 0
	_cam.limit_right  = 2560
	_cam.limit_bottom = 1440
	add_child(_cam)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			var z := _cam.zoom.x
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				z = minf(z + ZOOM_STEP, ZOOM_MAX)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				z = maxf(z - ZOOM_STEP, ZOOM_MIN)
			elif mb.button_index == MOUSE_BUTTON_LEFT and not GameData.inventaire_ouvert:
				utiliser_item()
			_cam.zoom = Vector2(z, z)


# ── Utilisation de l'item actif ──────────────────────────────

func utiliser_item() -> void:
	if _attaque_en_cours:
		return
	var item: Dictionary = GameData.item_actif()
	if item.is_empty():
		return
	var id: String = item["id"]
	if not GameData.ITEMS.has(id):
		return
	var info: Dictionary = GameData.ITEMS[id]
	match info.get("type", ""):
		"outil":
			_jouer_attaque(info.get("arme_sprite", ""))
		"consommable":
			# TODO: consommer (faim/soif)
			pass
		"ressource":
			# Rien à faire, c'est juste une ressource
			pass
