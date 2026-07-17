class_name FlockfallBird
extends RigidBody2D

signal launched
signal peg_hit(impact_strength: float)

const RADIUS := 25.0

var bird_color: Color = Color.WHITE
var color_index: int = 0
var has_launched: bool = false
var launch_position: Vector2
var _last_velocity: Vector2 = Vector2.ZERO

func setup(new_color_index: int, new_color: Color, spawn_position: Vector2) -> void:
	color_index = new_color_index
	bird_color = new_color
	launch_position = spawn_position
	global_position = spawn_position
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	queue_redraw()

func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	contact_monitor = true
	max_contacts_reported = 8
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	gravity_scale = 1.15
	linear_damp = 0.08
	angular_damp = 0.6

	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

	var material := PhysicsMaterial.new()
	material.bounce = 0.72
	material.friction = 0.06
	physics_material_override = material

	body_entered.connect(_on_body_entered)

func launch(velocity: Vector2) -> void:
	if has_launched:
		return
	has_launched = true
	freeze = false
	linear_velocity = velocity
	angular_velocity = velocity.x * 0.018
	launched.emit()

func _physics_process(_delta: float) -> void:
	_last_velocity = linear_velocity

func _on_body_entered(_body: Node) -> void:
	if not has_launched:
		return
	var impact := _last_velocity.length()
	peg_hit.emit(impact)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.18, 0.82), 0.045)
	tween.tween_property(self, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_BACK)

func _draw() -> void:
	draw_circle(Vector2(4.0, 7.0), RADIUS + 3.0, Color(0.0, 0.0, 0.0, 0.22))
	draw_circle(Vector2.ZERO, RADIUS, bird_color)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 48, Color("#322f3d"), 4.0, true)
	draw_circle(Vector2(-8.0, -5.0), 5.5, Color.WHITE)
	draw_circle(Vector2(8.0, -5.0), 5.5, Color.WHITE)
	draw_circle(Vector2(-7.0, -4.0), 2.4, Color("#1b1b25"))
	draw_circle(Vector2(7.0, -4.0), 2.4, Color("#1b1b25"))
	var beak := PackedVector2Array([Vector2(-7.0, 6.0), Vector2(13.0, 8.0), Vector2(-5.0, 14.0)])
	draw_colored_polygon(beak, Color("#ffd166"))
	draw_circle(Vector2(-8.0, -12.0), 6.0, Color(1.0, 1.0, 1.0, 0.24))
