@tool
@icon ("res://addons/activeFrameHitbox/icons/hurtbox.svg")
extends Area2D
class_name Hurtbox


#region Signals

signal damage_received(amount: int)
signal hitstun_received(duration: float)

#endregion


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


#region Hurtbox Settings

@export var character: CharacterBody2D
@export var health_component: HealthComponent

#endregion


#region Collision Shape Functions

func add_collision_shape() -> void:
	if not Engine.is_editor_hint():
		return

	if get_node_or_null("HurtboxCollision"):
		push_warning("A collision shape already exists!")
		return

	var new_collision = CollisionShape2D.new()
	new_collision.name = "HurtboxCollision"
	new_collision.debug_color = Color(1.0, 0.41, 0.71, 0.3)

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


#region Damage Handling

func receive_hit(damage: int) -> void:
	damage_received.emit(damage)

	if health_component:
		health_component.take_damage(damage)

#endregion
