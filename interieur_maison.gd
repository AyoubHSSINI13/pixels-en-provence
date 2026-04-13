extends Node2D

# L'intérieur contient une Area2D "Sortie" placée sur le paillasson.
# Dès que le joueur y entre, on revient dans monde.tscn et on laisse
# porte_maison.gd le soin de placer le joueur devant la maison.

@onready var _sortie: Area2D = $Sortie


func _ready() -> void:
	_sortie.body_entered.connect(_on_sortie_entered)


func _on_sortie_entered(body: Node) -> void:
	if body is CharacterBody2D:
		get_tree().change_scene_to_file("res://monde.tscn")
