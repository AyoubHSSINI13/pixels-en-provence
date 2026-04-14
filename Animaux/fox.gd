class_name Fox
extends CharacterBody2D

const SPEED = 150.0
const CLICK_RADIUS = 16.0

var is_moving: bool = false
var is_selected: bool = false
var target_position: Vector2

static var selected_animal: CharacterBody2D = null

func _ready() -> void:
	collision_layer = 2
	collision_mask  = 1
	target_position = global_position

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_global_mouse_position()
		if global_position.distance_to(mouse_pos) <= CLICK_RADIUS:
			if Fox.selected_animal and Fox.selected_animal != self:
				Fox.selected_animal.is_selected = false
				Fox.selected_animal.modulate = Color.WHITE
			Fox.selected_animal = self
			is_selected = true
			modulate = Color(1.5, 1.5, 0.5)
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		if Fox.selected_animal:
			Fox.selected_animal.is_selected = false
			Fox.selected_animal.modulate    = Color.WHITE
			Fox.selected_animal             = null
			get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_LEFT:
		if is_selected:
			move_to(get_global_mouse_position())

func move_to(new_target: Vector2) -> void:
	target_position = new_target
	$NavigationAgent2D.target_position = new_target
	is_moving = true

func _physics_process(_delta: float) -> void:
	if not is_moving:
		return

	if global_position.distance_to(target_position) <= 5.0:
		global_position = target_position
		velocity = Vector2.ZERO
		$AnimatedSprite2D.stop()
		is_moving = false
		return

	var next_pos = target_position
	if not $NavigationAgent2D.is_navigation_finished():
		var nav_next = $NavigationAgent2D.get_next_path_position()
		if nav_next.distance_to(global_position) > 1.0:
			next_pos = nav_next

	var direction = global_position.direction_to(next_pos)
	velocity = direction * SPEED
	_play_animation(direction)
	move_and_slide()

func _play_animation(direction: Vector2) -> void:
	var sprite = $AnimatedSprite2D
	if abs(direction.x) >= abs(direction.y):
		sprite.flip_h = direction.x < 0
		sprite.play("run")
	elif direction.y < 0:
		sprite.flip_h = false
		sprite.play("run up")
	else:
		sprite.flip_h = false
		sprite.play("run down")
