extends Node3D

const CAMERA_PRESETS := [0.0, PI * 0.5, PI, -PI * 0.5]

var car: ArcadeCar
var camera: Camera3D
var hud: GameHud
var camera_yaw := 0.0
var camera_pitch := deg_to_rad(14.0)
var camera_distance := 8.8
var camera_preset := 0
var touch_actions: Dictionary = {}
var camera_touch := -1
var camera_touch_origin := Vector2.ZERO
var camera_touch_distance := 0.0


func _ready() -> void:
	_build_environment()
	_build_track()
	_build_car()
	_build_camera()
	_build_hud()


func _process(delta: float) -> void:
	var throttle := maxf(Input.get_action_strength("accelerate"), _touch_strength("accelerate"))
	var brake_value := maxf(Input.get_action_strength("brake"), _touch_strength("brake"))
	var steer := Input.get_axis("steer_left", "steer_right")
	steer += _touch_strength("right") - _touch_strength("left")
	steer = clampf(steer, -1.0, 1.0)
	car.set_controls(throttle, brake_value, steer)

	if Input.is_action_just_pressed("reset_car"):
		car.reset_to_spawn()
	if Input.is_action_just_pressed("cycle_camera"):
		_cycle_camera()
	if Input.is_action_just_pressed("toggle_debug"):
		hud.toggle_debug()

	_update_camera(delta)
	hud.set_telemetry(car.speed_kmh(), car.grounded_wheels(), throttle, brake_value, steer, rad_to_deg(car.steering), touch_actions.size(), rad_to_deg(camera_yaw))


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag and event.index == camera_touch:
		camera_touch_distance += event.relative.length()
		camera_yaw -= event.relative.x * 0.008
		camera_pitch = clampf(camera_pitch - event.relative.y * 0.006, deg_to_rad(-6.0), deg_to_rad(46.0))
		get_viewport().set_input_as_handled()


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		var action := hud.action_at(event.position)
		if action == "reset":
			car.reset_to_spawn()
			get_viewport().set_input_as_handled()
		elif action != "":
			touch_actions[event.index] = action
			hud.set_action_active(action, true)
			get_viewport().set_input_as_handled()
		elif hud.is_bottom_control_area(event.position):
			# A faixa inferior é exclusiva dos controles e não movimenta a câmera.
			get_viewport().set_input_as_handled()
		elif camera_touch == -1:
			camera_touch = event.index
			camera_touch_origin = event.position
			camera_touch_distance = 0.0
	else:
		if touch_actions.has(event.index):
			var action: String = touch_actions[event.index]
			touch_actions.erase(event.index)
			hud.set_action_active(action, _is_action_touched(action))
			get_viewport().set_input_as_handled()
		elif event.index == camera_touch:
			if camera_touch_distance < 14.0 and event.position.distance_to(camera_touch_origin) < 18.0:
				_cycle_camera()
			camera_touch = -1


func _touch_strength(action: String) -> float:
	return 1.0 if _is_action_touched(action) else 0.0


func _is_action_touched(action: String) -> bool:
	return touch_actions.values().has(action)


func _cycle_camera() -> void:
	camera_preset = (camera_preset + 1) % CAMERA_PRESETS.size()
	camera_yaw = CAMERA_PRESETS[camera_preset]


func _update_camera(delta: float) -> void:
	var car_transform := car.get_global_transform_interpolated()
	var target := car_transform.origin + Vector3.UP * 1.1
	var local_offset := Vector3(sin(camera_yaw) * camera_distance, 3.1 + sin(camera_pitch) * 3.0, -cos(camera_yaw) * camera_distance)
	var world_offset := car_transform.basis * local_offset
	var desired := target + world_offset
	camera.global_position = camera.global_position.lerp(desired, 1.0 - exp(-7.0 * delta))
	camera.look_at(target, Vector3.UP)


func _build_car() -> void:
	car = ArcadeCar.new()
	car.name = "PlayerCar"
	car.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	car.position = Vector3(0.0, 0.42, -30.0)
	add_child(car)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "FollowCamera"
	camera.fov = 62.0
	camera.near = 0.08
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.position = car.position + Vector3(0.0, 4.0, -9.0)
	add_child(camera)
	camera.current = true


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = GameHud.new()
	layer.add_child(hud)


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("78a9d8")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b9d2ee")
	environment.ambient_light_energy = 0.48
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	add_child(sun)


func _build_track() -> void:
	var asphalt := Color("343b49")
	var sidewalk := Color("aeb2b5")
	var curb := Color("e3e1d8")
	_add_static_box("Ground", Vector3(80.0, 0.2, 190.0), Vector3(0.0, -0.22, 35.0), Color("76a85b"))
	_add_static_box("Road", Vector3(13.0, 0.20, 180.0), Vector3(0.0, -0.10, 35.0), asphalt)
	_add_static_box("CrossRoad", Vector3(70.0, 0.20, 13.0), Vector3(0.0, -0.09, 22.0), asphalt)

	for z in range(-42, 105, 8):
		if z < 15 or z > 29:
			_add_visual_box(Vector3(0.18, 0.025, 4.0), Vector3(0.0, 0.025, float(z)), Color("f5f3e8"))

	for side in [-1.0, 1.0]:
		_add_visual_box(Vector3(0.14, 0.027, 70.0), Vector3(side * 6.05, 0.029, -19.5), Color("e8bd43"))
		_add_visual_box(Vector3(0.14, 0.027, 96.0), Vector3(side * 6.05, 0.029, 77.0), Color("e8bd43"))
		_add_static_box("SidewalkSouth", Vector3(1.75, 0.18, 70.0), Vector3(side * 7.45, 0.09, -19.5), sidewalk)
		_add_static_box("SidewalkNorth", Vector3(1.75, 0.18, 96.0), Vector3(side * 7.45, 0.09, 77.0), sidewalk)
		_add_visual_box(Vector3(0.16, 0.24, 70.0), Vector3(side * 6.58, 0.12, -19.5), curb)
		_add_visual_box(Vector3(0.16, 0.24, 96.0), Vector3(side * 6.58, 0.12, 77.0), curb)

		for z in range(-52, 126, 5):
			if z < 15 or z > 29:
				_add_visual_box(Vector3(1.64, 0.016, 0.045), Vector3(side * 7.45, 0.19, float(z)), Color("7e848b"))

	for stripe in range(-5, 6, 2):
		_add_visual_box(Vector3(0.75, 0.028, 2.4), Vector3(float(stripe), 0.032, 14.4), Color("f1efe5"))
		_add_visual_box(Vector3(0.75, 0.028, 2.4), Vector3(float(stripe), 0.032, 29.6), Color("f1efe5"))

	var ramp := _add_static_box("Ramp", Vector3(4.8, 0.38, 9.0), Vector3(0.0, 0.72, 49.0), Color("66707e"), Vector3(deg_to_rad(-10.0), 0.0, 0.0))
	_add_box_child(ramp, Vector3(0.20, 0.035, 8.4), Vector3(0.0, 0.21, 0.0), Color("f1c84b"))
	_add_box_child(ramp, Vector3(0.20, 0.42, 9.0), Vector3(-2.30, 0.35, 0.0), Color("db6338"))
	_add_box_child(ramp, Vector3(0.20, 0.42, 9.0), Vector3(2.30, 0.35, 0.0), Color("db6338"))
	for ramp_mark in [-3.2, -1.6, 0.0, 1.6, 3.2]:
		_add_box_child(ramp, Vector3(4.35, 0.025, 0.08), Vector3(0.0, 0.215, ramp_mark), Color("8994a1"))

	var building_colors := [Color("916f62"), Color("5d6b82"), Color("866f86"), Color("657b72"), Color("9a8064")]
	for side in [-1.0, 1.0]:
		var building_index := 0
		for z in range(-25, 92, 16):
			var height := 5.0 + float((building_index * 3 + (1 if side > 0.0 else 0)) % 6)
			var color: Color = building_colors[(building_index + (2 if side > 0.0 else 0)) % building_colors.size()]
			var building := _add_static_box("Building", Vector3(5.4, height, 10.5), Vector3(side * 11.1, height * 0.5, float(z)), color)
			_add_box_child(building, Vector3(5.65, 0.30, 10.75), Vector3(0.0, height * 0.5 + 0.15, 0.0), color.lightened(0.13))
			var road_face_x: float = -float(side) * 2.72
			for floor_index in range(maxi(2, int(height / 1.45))):
				var window_y := -height * 0.5 + 1.0 + floor_index * 1.30
				for window_z in [-3.1, 0.0, 3.1]:
					_add_box_child(building, Vector3(0.055, 0.62, 1.35), Vector3(road_face_x, window_y, window_z), Color("b9d9e8"))
			building_index += 1

	_add_static_box("BarrierLeft", Vector3(2.8, 0.75, 1.0), Vector3(-3.2, 0.38, 18.0), Color("ef6b32"))
	_add_static_box("BarrierRight", Vector3(2.8, 0.75, 1.0), Vector3(3.2, 0.38, 26.0), Color("be4338"))


func _add_static_box(node_name: String, box_size: Vector3, box_position: Vector3, color: Color, box_rotation := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = box_position
	body.rotation = box_rotation
	add_child(body)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)

	var visual := _mesh_box(box_size, color)
	body.add_child(visual)
	return body


func _add_visual_box(box_size: Vector3, box_position: Vector3, color: Color) -> void:
	var visual := _mesh_box(box_size, color)
	visual.position = box_position
	add_child(visual)


func _add_box_child(parent: Node3D, box_size: Vector3, box_position: Vector3, color: Color) -> MeshInstance3D:
	var visual := _mesh_box(box_size, color)
	visual.position = box_position
	parent.add_child(visual)
	return visual


func _mesh_box(box_size: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.94
	material.metallic_specular = 0.18
	mesh.material = material
	instance.mesh = mesh
	return instance
