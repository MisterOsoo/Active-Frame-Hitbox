@tool
@icon ("res://addons/activeFrameHitbox/icons/hitbox.svg")
extends Area2D
class_name activeFrameHitbox


#region Collision Shape Settings

enum ShapeType {
	RECTANGLE,
	CIRCLE,
	CAPSULE
}

@export var shape_type: ShapeType = ShapeType.RECTANGLE

@export_tool_button("Add Collision Shape")
var add_shape_button = add_collision_shape

#endregion


#region Hitbox Settings

@export var character: CharacterBody2D

@export var animated_sprite: AnimatedSprite2D:
	set(value):
		animated_sprite = value
		notify_property_list_changed()

@export_custom(PROPERTY_HINT_ENUM, "")
var attack_animation: String = "attack"

@export var active_frames: Array[int] = [0]

@export_group("Attack Properties")
@export var damage: int = 0

@onready var collision: CollisionShape2D = get_node_or_null("HitboxCollision")

var hit_targets: Array[Hurtbox] = []
var attack_started: bool = false

#endregion


#region Collision Shape Functions

func add_collision_shape() -> void:
	if not Engine.is_editor_hint():
		return

	if get_node_or_null("HitboxCollision"):
		push_warning("A collision shape already exists!")
		return

	var new_collision = CollisionShape2D.new()
	new_collision.name = "HitboxCollision"
	new_collision.debug_color = Color(1.0, 1.0, 0.0, 0.3)

	match shape_type:
		ShapeType.RECTANGLE:
			new_collision.shape = RectangleShape2D.new()

		ShapeType.CIRCLE:
			new_collision.shape = CircleShape2D.new()

		ShapeType.CAPSULE:
			new_collision.shape = CapsuleShape2D.new()

	add_child(new_collision)
	new_collision.owner = owner

#endregion


#region Animation Dropdown

func _validate_property(property: Dictionary) -> void:
	if property.name == "attack_animation":
		if animated_sprite and animated_sprite.sprite_frames:
			var animations: PackedStringArray = (
				animated_sprite.sprite_frames.get_animation_names()
			)

			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = ",".join(animations)

#endregion


#region Initialization

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if not collision:
		push_warning("Hitbox needs a CollisionShape2D!")
		return

	collision.set_deferred("disabled", true)

	area_entered.connect(_on_area_entered)

	if animated_sprite:
		animated_sprite.frame_changed.connect(_update_hitbox)
		animated_sprite.animation_changed.connect(_update_hitbox)
		animated_sprite.animation_finished.connect(_on_animation_finished)

		_update_hitbox()

#endregion


#region Hitbox Logic

func _update_hitbox() -> void:
	if not animated_sprite or not collision:
		return

	var is_attack_playing := (
		animated_sprite.animation == attack_animation
		and animated_sprite.is_playing()
	)

	if is_attack_playing and not attack_started:
		hit_targets.clear()
		attack_started = true

	if not is_attack_playing:
		attack_started = false

	var is_active := (
		is_attack_playing
		and animated_sprite.frame in active_frames
	)

	collision.set_deferred("disabled", not is_active)


func _on_animation_finished() -> void:
	if animated_sprite.animation == attack_animation:
		attack_started = false
		collision.set_deferred("disabled", true)


func _on_area_entered(area: Area2D) -> void:
	if not area is Hurtbox:
		return

	if character == null or area.character == null:
		return

	# Prevent self-damage
	if area.character == character:
		return

	# Prevent multiple hits per attack
	if area in hit_targets:
		return

	hit_targets.append(area)
	
	# Send damage to the Hurtbox
	area.receive_hit(damage)

#endregion
