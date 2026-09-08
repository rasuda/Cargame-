class_name GameHud
extends Control

const VERSION := "v0.2.1 GODOT"

var title_label: Label
var speed_label: Label
var debug_label: Label
var reset_label: Label
var debug_visible := true
var control_rects: Dictionary = {}
var control_panels: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_labels()
	_build_controls()
	resized.connect(_layout)
	_layout()


func set_telemetry(speed: float, ground_count: int, throttle: float, brake_value: float, steer: float, touches: int, camera_degrees: float) -> void:
	speed_label.text = "%d\nkm/h" % roundi(speed)
	debug_label.text = "DEBUG  |  touch:%d\nentrada  T:%.0f  B:%.0f  S:%+.0f\nrodas no chão: %d/4\nvelocidade: %.2f km/h\ncâmera: %.0f°" % [touches, throttle, brake_value, steer, ground_count, speed, camera_degrees]


func action_at(point: Vector2) -> String:
	if control_rects.get("reset", Rect2()).has_point(point):
		return "reset"
	for action in ["left", "right", "brake", "accelerate"]:
		if control_rects.get(action, Rect2()).has_point(point):
			return action
	return ""


func set_action_active(action: String, active: bool) -> void:
	var panel: Panel = control_panels.get(action)
	if panel == null:
		return
	var color := _action_color(action)
	if active:
		color = color.lightened(0.18)
	panel.add_theme_stylebox_override("panel", _panel_style(color, 20.0, 2.0))


func toggle_debug() -> void:
	debug_visible = not debug_visible
	debug_label.visible = debug_visible


func _build_labels() -> void:
	title_label = Label.new()
	title_label.text = "CRASH CIRCUIT\n%s" % VERSION
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(title_label)

	speed_label = Label.new()
	speed_label.text = "0\nkm/h"
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speed_label.add_theme_font_size_override("font_size", 28)
	speed_label.add_theme_stylebox_override("normal", _panel_style(Color(0.04, 0.08, 0.15, 0.78), 18.0, 2.0))
	add_child(speed_label)

	debug_label = Label.new()
	debug_label.add_theme_font_size_override("font_size", 16)
	debug_label.add_theme_color_override("font_color", Color("bfffd8"))
	debug_label.add_theme_stylebox_override("normal", _panel_style(Color(0.02, 0.07, 0.12, 0.82), 14.0, 2.0, Color("39a66b")))
	add_child(debug_label)

	reset_label = Label.new()
	reset_label.text = "REINICIAR"
	reset_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reset_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reset_label.add_theme_font_size_override("font_size", 17)
	reset_label.add_theme_stylebox_override("normal", _panel_style(Color(0.04, 0.08, 0.15, 0.78), 14.0, 2.0))
	add_child(reset_label)


func _build_controls() -> void:
	for action in ["left", "right", "brake", "accelerate"]:
		var panel := Panel.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_stylebox_override("panel", _panel_style(_action_color(action), 22.0, 2.0))
		add_child(panel)
		control_panels[action] = panel

		var glyph := Label.new()
		glyph.text = {"left": "◀", "right": "▶", "brake": "▼", "accelerate": "▲"}[action]
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glyph.add_theme_font_size_override("font_size", 34)
		panel.add_child(glyph)


func _layout() -> void:
	var viewport_size := size
	var margin := clampf(viewport_size.x * 0.035, 18.0, 38.0)
	var button_size := clampf(viewport_size.x * 0.11, 72.0, 104.0)
	var gap := clampf(button_size * 0.22, 14.0, 22.0)
	var bottom := viewport_size.y - margin

	title_label.position = Vector2(margin, margin)
	title_label.size = Vector2(260, 70)
	speed_label.position = Vector2(viewport_size.x * 0.5 - 72, margin)
	speed_label.size = Vector2(144, 96)
	reset_label.position = Vector2(viewport_size.x - margin - 132, margin)
	reset_label.size = Vector2(132, 58)
	control_rects["reset"] = Rect2(reset_label.position, reset_label.size)

	var left_rect := Rect2(Vector2(margin, bottom - button_size), Vector2.ONE * button_size)
	var right_rect := Rect2(Vector2(margin + button_size + gap, bottom - button_size), Vector2.ONE * button_size)
	var accel_rect := Rect2(Vector2(viewport_size.x - margin - button_size, bottom - button_size), Vector2.ONE * button_size)
	var brake_rect := Rect2(Vector2(viewport_size.x - margin - button_size * 2.0 - gap, bottom - button_size), Vector2.ONE * button_size)

	control_rects["left"] = left_rect
	control_rects["right"] = right_rect
	control_rects["accelerate"] = accel_rect
	control_rects["brake"] = brake_rect
	for action in ["left", "right", "brake", "accelerate"]:
		var rect: Rect2 = control_rects[action]
		control_panels[action].position = rect.position
		control_panels[action].size = rect.size

	debug_label.position = Vector2(margin, margin + 86)
	debug_label.size = Vector2(minf(370.0, viewport_size.x - margin * 2.0), 138)


func _action_color(action: String) -> Color:
	match action:
		"accelerate": return Color(0.12, 0.58, 0.31, 0.80)
		"brake": return Color(0.70, 0.20, 0.24, 0.80)
		_: return Color(0.06, 0.10, 0.18, 0.78)


func _panel_style(color: Color, radius: float, border_width: float, border_color := Color(0.7, 0.78, 0.9, 0.35)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(int(border_width))
	style.set_corner_radius_all(int(radius))
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style
