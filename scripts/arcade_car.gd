class_name ArcadeCar
extends VehicleBody3D

const MAX_ENGINE_FORCE := 1600.0
const MAX_BRAKE_FORCE := 80.0
const MAX_STEERING := deg_to_rad(20.0)
const STEERING_INPUT_SPEED := deg_to_rad(24.0)
const STEERING_RETURN_SPEED := deg_to_rad(45.0)

var throttle_input := 0.0
var brake_input := 0.0
var steering_input := 0.0
var spawn_transform := Transform3D.IDENTITY
var wheels: Array[VehicleWheel3D] = []
var reset_requested := false


func _ready() -> void:
	mass = 920.0
	continuous_cd = true
	linear_damp = 0.12
	angular_damp = 0.7
	_build_chassis()
	_build_wheels()
	spawn_transform = global_transform


func _physics_process(delta: float) -> void:
	var forward_speed := linear_velocity.dot(global_transform.basis.z)
	var requested_engine := throttle_input
	var requested_brake := 0.0

	if brake_input > 0.0:
		if forward_speed > 1.0:
			requested_brake = brake_input
		else:
			requested_engine = -brake_input * 0.62

	engine_force = requested_engine * MAX_ENGINE_FORCE
	brake = requested_brake * MAX_BRAKE_FORCE
	var steering_target := -steering_input * MAX_STEERING
	var steering_speed := STEERING_INPUT_SPEED if absf(steering_input) > 0.01 else STEERING_RETURN_SPEED
	steering = move_toward(steering, steering_target, steering_speed * delta)

	if global_position.y < -8.0 or abs(global_position.x) > 55.0:
		reset_to_spawn()


func set_controls(new_throttle: float, new_brake: float, new_steering: float) -> void:
	throttle_input = clampf(new_throttle, 0.0, 1.0)
	brake_input = clampf(new_brake, 0.0, 1.0)
	steering_input = clampf(new_steering, -1.0, 1.0)


func reset_to_spawn() -> void:
	reset_requested = true
	engine_force = 0.0
	brake = 0.0
	sleeping = false


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not reset_requested:
		return
	state.transform = spawn_transform
	state.linear_velocity = Vector3.ZERO
	state.angular_velocity = Vector3.ZERO
	steering = 0.0
	reset_requested = false
	reset_physics_interpolation()


func speed_kmh() -> float:
	return linear_velocity.length() * 3.6


func grounded_wheels() -> int:
	var total := 0
	for wheel in wheels:
		if wheel.is_in_contact():
			total += 1
	return total


func _build_chassis() -> void:
	var collision := CollisionShape3D.new()
	var chassis_shape := BoxShape3D.new()
	chassis_shape.size = Vector3(2.0, 0.62, 4.1)
	collision.shape = chassis_shape
	collision.position = Vector3(0.0, 0.62, 0.0)
	add_child(collision)

	var white := Color("f4f5f4")
	var white_shadow := Color("d8dcdf")
	var glass := Color("182838")
	var trim := Color("15191d")
	var red := Color("d51f2a")

	# Compact five-door hatchback body, based on the Golf GTI Mk7 proportions.
	_add_body_part(Vector3(1.98, 0.60, 4.18), Vector3(0.0, 0.68, 0.0), white, Vector3.ZERO, 0.32)
	_add_body_part(Vector3(1.88, 0.18, 1.34), Vector3(0.0, 1.06, 1.25), white, Vector3(deg_to_rad(-3.0), 0.0, 0.0), 0.28)
	_add_body_part(Vector3(1.58, 0.16, 1.63), Vector3(0.0, 1.69, -0.34), white, Vector3.ZERO, 0.28)
	_add_body_part(Vector3(1.68, 0.16, 0.62), Vector3(0.0, 1.58, -1.14), white, Vector3(deg_to_rad(-18.0), 0.0, 0.0), 0.30)

	# Windows and pillars give the characteristic squared-off Mk7 greenhouse.
	_add_body_part(Vector3(1.64, 0.58, 0.07), Vector3(0.0, 1.40, 0.54), glass, Vector3(deg_to_rad(-23.0), 0.0, 0.0), 0.16)
	_add_body_part(Vector3(1.65, 0.53, 0.07), Vector3(0.0, 1.39, -1.13), glass, Vector3(deg_to_rad(20.0), 0.0, 0.0), 0.16)
	for side_value in [-1.0, 1.0]:
		var side: float = float(side_value)
		_add_body_part(Vector3(0.055, 0.50, 1.40), Vector3(side * 0.815, 1.40, -0.30), glass, Vector3.ZERO, 0.16)
		_add_body_part(Vector3(0.065, 0.55, 0.11), Vector3(side * 0.845, 1.42, -0.20), trim, Vector3.ZERO, 0.65)
		_add_body_part(Vector3(0.07, 0.10, 3.28), Vector3(side * 1.005, 0.40, -0.10), trim, Vector3.ZERO, 0.72)
		_add_body_part(Vector3(0.075, 0.18, 0.38), Vector3(side * 0.99, 1.05, 0.42), white_shadow, Vector3.ZERO, 0.34)

	# GTI-style front fascia: twin headlights, black honeycomb area and red stripe.
	_add_body_part(Vector3(1.92, 0.45, 0.16), Vector3(0.0, 0.70, 2.08), white_shadow, Vector3.ZERO, 0.36)
	_add_body_part(Vector3(1.12, 0.26, 0.035), Vector3(0.0, 0.66, 2.17), trim, Vector3.ZERO, 0.78)
	_add_body_part(Vector3(0.78, 0.15, 0.040), Vector3(0.0, 0.91, 2.17), trim, Vector3.ZERO, 0.74)
	_add_body_part(Vector3(1.62, 0.035, 0.045), Vector3(0.0, 0.98, 2.19), red, Vector3.ZERO, 0.38)
	_add_body_part(Vector3(0.48, 0.16, 0.045), Vector3(-0.65, 1.00, 2.18), Color("eaf4f6"), Vector3.ZERO, 0.10)
	_add_body_part(Vector3(0.48, 0.16, 0.045), Vector3(0.65, 1.00, 2.18), Color("eaf4f6"), Vector3.ZERO, 0.10)
	_add_body_part(Vector3(0.26, 0.045, 0.047), Vector3(-0.65, 1.04, 2.205), Color("ffffff"), Vector3.ZERO, 0.05)
	_add_body_part(Vector3(0.26, 0.045, 0.047), Vector3(0.65, 1.04, 2.205), Color("ffffff"), Vector3.ZERO, 0.05)

	# Rear hatch, spoiler, dark diffuser and angular red tail lamps.
	_add_body_part(Vector3(1.92, 0.38, 0.14), Vector3(0.0, 0.78, -2.09), white_shadow, Vector3.ZERO, 0.38)
	_add_body_part(Vector3(1.08, 0.16, 0.035), Vector3(0.0, 0.54, -2.18), trim, Vector3.ZERO, 0.80)
	_add_body_part(Vector3(0.53, 0.20, 0.045), Vector3(-0.64, 1.03, -2.17), red, Vector3.ZERO, 0.22)
	_add_body_part(Vector3(0.53, 0.20, 0.045), Vector3(0.64, 1.03, -2.17), red, Vector3.ZERO, 0.22)
	_add_body_part(Vector3(1.76, 0.10, 0.34), Vector3(0.0, 1.72, -1.22), white, Vector3(deg_to_rad(-4.0), 0.0, 0.0), 0.28)


func _build_wheels() -> void:
	_add_wheel("FrontLeft", Vector3(-1.02, 0.55, 1.36), true, true)
	_add_wheel("FrontRight", Vector3(1.02, 0.55, 1.36), true, true)
	_add_wheel("RearLeft", Vector3(-1.02, 0.55, -1.36), false, true)
	_add_wheel("RearRight", Vector3(1.02, 0.55, -1.36), false, true)


func _add_wheel(wheel_name: String, wheel_position: Vector3, steers: bool, drives: bool) -> void:
	var wheel := VehicleWheel3D.new()
	wheel.name = wheel_name
	wheel.position = wheel_position
	wheel.use_as_steering = steers
	wheel.use_as_traction = drives
	wheel.wheel_radius = 0.43
	wheel.wheel_rest_length = 0.26
	wheel.suspension_travel = 0.22
	wheel.suspension_stiffness = 38.0
	wheel.suspension_max_force = 7200.0
	wheel.damping_compression = 0.90
	wheel.damping_relaxation = 1.15
	wheel.wheel_friction_slip = 5.0
	wheel.wheel_roll_influence = 0.08
	add_child(wheel)
	wheels.append(wheel)

	var tire := MeshInstance3D.new()
	var tire_mesh := CylinderMesh.new()
	tire_mesh.top_radius = 0.43
	tire_mesh.bottom_radius = 0.43
	tire_mesh.height = 0.28
	tire_mesh.radial_segments = 16
	tire_mesh.material = _material(Color("17191f"), 0.88)
	tire.mesh = tire_mesh
	tire.rotation.z = PI * 0.5
	wheel.add_child(tire)

	var hub := MeshInstance3D.new()
	var hub_mesh := CylinderMesh.new()
	hub_mesh.top_radius = 0.19
	hub_mesh.bottom_radius = 0.19
	hub_mesh.height = 0.30
	hub_mesh.radial_segments = 12
	hub_mesh.material = _material(Color("d7dbe3"), 0.45)
	hub.mesh = hub_mesh
	hub.rotation.z = PI * 0.5
	wheel.add_child(hub)


func _add_body_part(size: Vector3, part_position: Vector3, color: Color, part_rotation := Vector3.ZERO, roughness_value := 0.60) -> MeshInstance3D:
	var part := _box_mesh(size, color, roughness_value)
	part.position = part_position
	part.rotation = part_rotation
	add_child(part)
	return part


func _box_mesh(size: Vector3, color: Color, roughness_value := 0.72) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(color, roughness_value)
	instance.mesh = mesh
	return instance


func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	return material
