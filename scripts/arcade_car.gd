class_name ArcadeCar
extends VehicleBody3D

const MAX_ENGINE_FORCE := 1800.0
const MAX_BRAKE_FORCE := 90.0
const MAX_STEERING := deg_to_rad(28.0)
const STEERING_SPEED := 4.5

var throttle_input := 0.0
var brake_input := 0.0
var steering_input := 0.0
var spawn_transform := Transform3D.IDENTITY
var wheels: Array[VehicleWheel3D] = []


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
	# VehicleBody3D usa o sinal oposto ao sentido visual dos controles.
	steering = move_toward(steering, -steering_input * MAX_STEERING, STEERING_SPEED * delta)

	if global_position.y < -8.0 or abs(global_position.x) > 55.0:
		reset_to_spawn()


func set_controls(new_throttle: float, new_brake: float, new_steering: float) -> void:
	throttle_input = clampf(new_throttle, 0.0, 1.0)
	brake_input = clampf(new_brake, 0.0, 1.0)
	steering_input = clampf(new_steering, -1.0, 1.0)


func reset_to_spawn() -> void:
	global_transform = spawn_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	engine_force = 0.0
	brake = 0.0
	sleeping = false


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

	var body := _box_mesh(Vector3(2.08, 0.72, 4.25), Color("f26a38"))
	body.position = Vector3(0.0, 0.66, 0.0)
	add_child(body)

	var hood := _box_mesh(Vector3(1.92, 0.20, 1.45), Color("ffe477"))
	hood.position = Vector3(0.0, 1.06, 1.18)
	add_child(hood)

	var cabin := _box_mesh(Vector3(1.70, 0.72, 1.72), Color("40588e"))
	cabin.position = Vector3(0.0, 1.35, -0.35)
	add_child(cabin)

	var windshield := _box_mesh(Vector3(1.73, 0.48, 0.08), Color("172239"))
	windshield.position = Vector3(0.0, 1.34, 0.54)
	windshield.rotation.x = deg_to_rad(-18.0)
	add_child(windshield)


func _build_wheels() -> void:
	_add_wheel("FrontLeft", Vector3(-1.02, 0.55, 1.36), true, false)
	_add_wheel("FrontRight", Vector3(1.02, 0.55, 1.36), true, false)
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
	wheel.wheel_friction_slip = 2.1
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


func _box_mesh(size: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(color, 0.72)
	instance.mesh = mesh
	return instance


func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	return material
