class_name TrafficCar
extends RigidBody3D

signal crash_involved(vehicle: TrafficCar)

var cruise_direction := 1.0
var cruise_speed := 9.0
var body_color := Color("3d78c5")
var spawn_position := Vector3.ZERO
var crashed := false


func _ready() -> void:
	mass = 1050.0
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 8
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	linear_damp = 0.22
	angular_damp = 0.42
	rotation.y = PI * 0.5 * cruise_direction
	spawn_position = global_position
	_build_model()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if crashed:
		return
	global_position.x += cruise_direction * cruise_speed * delta
	if cruise_direction > 0.0 and global_position.x > 38.0:
		global_position.x = -38.0
		reset_physics_interpolation()
	elif cruise_direction < 0.0 and global_position.x < -38.0:
		global_position.x = 38.0
		reset_physics_interpolation()


func reset_traffic() -> void:
	crashed = false
	freeze = true
	global_position = spawn_position
	rotation = Vector3(0.0, PI * 0.5 * cruise_direction, 0.0)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = false
	reset_physics_interpolation()


func _on_body_entered(body: Node) -> void:
	if crashed:
		return
	var causes_crash := body is ArcadeCar
	if body is TrafficCar:
		causes_crash = body.crashed
	if not causes_crash:
		return

	crashed = true
	freeze = false
	sleeping = false
	linear_velocity = Vector3(cruise_direction * cruise_speed, 0.0, 0.0)
	if body is ArcadeCar:
		var player_car := body as ArcadeCar
		linear_velocity += player_car.linear_velocity * 0.38
	elif body is TrafficCar:
		var other_traffic := body as TrafficCar
		linear_velocity += other_traffic.linear_velocity * 0.38
	var spin_sign := -1.0 if get_instance_id() % 2 == 0 else 1.0
	angular_velocity = Vector3(0.0, spin_sign * 0.8, spin_sign * 0.25)
	crash_involved.emit(self)


func _build_model() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.82, 0.76, 3.72)
	collision.shape = shape
	add_child(collision)

	_add_box(Vector3(1.86, 0.68, 3.78), Vector3.ZERO, body_color)
	_add_box(Vector3(1.54, 0.58, 1.72), Vector3(0.0, 0.59, -0.18), body_color.lightened(0.08))
	_add_box(Vector3(1.57, 0.40, 0.055), Vector3(0.0, 0.61, 0.68), Color("203141"), Vector3(deg_to_rad(-18.0), 0.0, 0.0))
	_add_box(Vector3(1.58, 0.36, 0.055), Vector3(0.0, 0.60, -1.03), Color("203141"), Vector3(deg_to_rad(17.0), 0.0, 0.0))
	_add_box(Vector3(0.44, 0.14, 0.045), Vector3(-0.57, 0.20, 1.91), Color("f2f5df"))
	_add_box(Vector3(0.44, 0.14, 0.045), Vector3(0.57, 0.20, 1.91), Color("f2f5df"))
	_add_box(Vector3(0.48, 0.16, 0.045), Vector3(-0.58, 0.18, -1.91), Color("c62e32"))
	_add_box(Vector3(0.48, 0.16, 0.045), Vector3(0.58, 0.18, -1.91), Color("c62e32"))
	for side_value in [-1.0, 1.0]:
		var side: float = float(side_value)
		for axle_z in [-1.18, 1.18]:
			_add_wheel(Vector3(side * 0.94, -0.28, float(axle_z)))


func _add_wheel(wheel_position: Vector3) -> void:
	var tire := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.37
	mesh.bottom_radius = 0.37
	mesh.height = 0.24
	mesh.radial_segments = 12
	mesh.material = _material(Color("17191d"), 0.86)
	tire.mesh = mesh
	tire.position = wheel_position
	tire.rotation.z = PI * 0.5
	add_child(tire)


func _add_box(size: Vector3, box_position: Vector3, color: Color, box_rotation := Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(color, 0.58)
	instance.mesh = mesh
	instance.position = box_position
	instance.rotation = box_rotation
	add_child(instance)


func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	return material
