class_name FlockfallPeg
extends StaticBody2D

## Simple circular bumper used in the launch field.
## Everything is drawn in code so the prototype has no external art dependency.

@export var radius: float = 21.0
@export var fill_color: Color = Color("#f4c95d")
@export var outline_color: Color = Color("#6a4c2b")

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1

	var shape := CircleShape2D.new()
	shape.radius = radius

	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

	var material := PhysicsMaterial.new()
	material.bounce = 0.82
	material.friction = 0.08
	physics_material_override = material

	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius + 5.0, Color(0.0, 0.0, 0.0, 0.18))
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, outline_color, 4.0, true)
	draw_circle(Vector2(-6.0, -6.0), radius * 0.28, Color(1.0, 1.0, 1.0, 0.32))
