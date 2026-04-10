extends CharacterBody2D

# ─────────────────────────────────────────────────────────────
#  Joueur – Pixels en Provence
#  Spritesheet Mana Seed p1 (512×512, frames 64×64) :
#    Lignes 0-3  → idle  (col 0)  : sud / ouest / est / nord
#    Lignes 4-7  → walk  (col 0-5): sud / ouest / est / nord
# ─────────────────────────────────────────────────────────────

const BASE_PATH  := "res://assets/personnage/mana_seed_demo/char_a_p1/"
const VITESSE    := 90.0
const FPS_MARCHE := 7.4

const LIGNE_IDLE := { "south": 0, "north": 1, "east": 2, "west": 3 }
const LIGNE_WALK := { "south": 4, "north": 5, "east": 6, "west": 7 }

const TENUE_IDS := ["fstr", "pfpn", "boxr", "undi"]
const TENUE_MAX := [5, 5, 1, 1]

var spr_corps:   AnimatedSprite2D
var spr_tenue:   AnimatedSprite2D
var spr_cheveux: AnimatedSprite2D
var spr_chapeau: AnimatedSprite2D

var _dir := "south"


func _ready() -> void:
	_creer_sprites()
	_ajouter_camera()
	z_as_relative = false


func _physics_process(_delta: float) -> void:
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
			_cam.zoom = Vector2(z, z)
