extends Area2D

# ─────────────────────────────────────────────────────────────
#  Porte de maison – entrée automatique quand le joueur marche
#  dans la zone. Mémorise un spawn de retour devant la porte.
# ─────────────────────────────────────────────────────────────

@export_file("*.tscn") var scene_cible: String = "res://interieur_maison.tscn"

# Décalage sud sous l'Area2D où le joueur réapparaîtra en sortant
@export var retour_offset: Vector2 = Vector2(0, 35)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body is CharacterBody2D:
		return
	if not ResourceLoader.exists(scene_cible):
		push_error("Scène cible introuvable : " + scene_cible)
		return
	# Position de retour : devant la porte (en global, car l'Area2D
	# peut être placée n'importe où dans la scène)
	var shape := $CollisionShape2D as CollisionShape2D
	var retour := shape.global_position + retour_offset if shape else global_position + retour_offset
	GameData.spawn_override = retour
	GameData.spawn_override_actif = true
	get_tree().change_scene_to_file(scene_cible)
