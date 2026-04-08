extends CharacterBody2D

# ─────────────────────────────────────────────────────────────
#  Joueur – Pixels en Provence
#  Spritesheet Mana Seed p1 (512×512, frames 64×64) :
#    Lignes 0-3  → idle  (col 0)  : sud / ouest / est / nord
#    Lignes 4-7  → walk  (col 0-5): sud / ouest / est / nord
# ─────────────────────────────────────────────────────────────

const BASE_PATH  := "res://assets/personnage/mana_seed_demo/char_a_p1/"
const VITESSE    := 90.0    # px/s — ajuster selon la taille de la map
const FPS_MARCHE := 7.4     # 135 ms/frame (specs Mana Seed)

# direction -> ligne dans le spritesheet
const LIGNE_IDLE := { "south": 0, "west": 1, "east": 2, "north": 3 }
const LIGNE_WALK := { "south": 4, "west": 5, "east": 6, "north": 7 }

var spr_corps:   AnimatedSprite2D
var spr_tenue:   AnimatedSprite2D
var spr_cheveux: AnimatedSprite2D

var _dir := "south"


func _ready() -> void:
	_creer_sprites()
	_ajouter_camera()
	# Z-index dynamique (Y-sort manuel)
	z_as_relative = false


func _physics_process(_delta: float) -> void:
	var input := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up",   "ui_down")
	).normalized()

	velocity = input * VITESSE
	move_and_slide()

	# Y-sort : le perso passe devant/derrière selon sa position verticale
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
	for spr: AnimatedSprite2D in [spr_corps, spr_tenue, spr_cheveux]:
		if spr.animation != anim:
			spr.play(anim)


# ── Construction des sprites ──────────────────────────────────

func _creer_sprites() -> void:
	var hair_name: String = (["bob1", "dap1"] as Array)[GameData.coiffure]
	var corps_path   := BASE_PATH + "char_a_p1_0bas_humn_v%02d.png"      % GameData.carnation
	var tenue_path   := BASE_PATH + "1out/char_a_p1_1out_fstr_v%02d.png" % (GameData.tenue + 1)
	var cheveux_path := BASE_PATH + "4har/char_a_p1_4har_%s_v%02d.png"   % [hair_name, GameData.couleur_cheveux]

	spr_corps   = _construire_sprite(corps_path,   0)
	spr_tenue   = _construire_sprite(tenue_path,   1)
	spr_cheveux = _construire_sprite(cheveux_path, 2)

	add_child(spr_corps)
	add_child(spr_tenue)
	add_child(spr_cheveux)


func _construire_sprite(tex_path: String, z: int) -> AnimatedSprite2D:
	var tex := load(tex_path) as Texture2D
	var sf  := SpriteFrames.new()
	sf.remove_animation("default")

	# ── Idle : 1 frame par direction (col 0, lignes 0-3) ──────
	for dir: String in LIGNE_IDLE:
		var row: int  = LIGNE_IDLE[dir]
		var anim      := "idle_" + dir
		sf.add_animation(anim)
		sf.set_animation_loop(anim, true)
		sf.set_animation_speed(anim, 1.0)
		sf.add_frame(anim, _atlas(tex, 0, row))

	# ── Walk : 6 frames par direction (lignes 4-7, cols 0-5) ──
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


func _ajouter_camera() -> void:
	var cam                        := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed   = 5.0
	cam.zoom                       = Vector2(2, 2)
	# Pas de limites pour l'instant — à remettre quand la map sera redessinée :
	# cam.limit_left   = 0
	# cam.limit_top    = 0
	# cam.limit_right  = LARGEUR_MAP_EN_PX
	# cam.limit_bottom = HAUTEUR_MAP_EN_PX
	add_child(cam)
