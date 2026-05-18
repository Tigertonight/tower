class_name ToastLayer
extends Control

# Stacked toast queue for soft combat-log replacement.
# Max 3 visible, each auto-dismisses in 2 s, with fade-in / fade-out.

const MAX_TOASTS := 3
const TOAST_LIFETIME := 2.0
const TOAST_FADE := 0.18
const TOAST_HEIGHT := 32
const TOAST_PADDING := 6

var _toasts: Array[Control] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 60


func push_toast(message: String, color: Color = Color(0.94, 0.86, 0.72)) -> void:
	if message.is_empty():
		return
	if _toasts.size() >= MAX_TOASTS:
		var oldest: Control = _toasts.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	var bubble := PanelContainer.new()
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_theme_stylebox_override("panel", _bubble_box())
	bubble.modulate = Color(1, 1, 1, 0)

	var label := Label.new()
	label.text = message
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_child(label)

	add_child(bubble)
	_toasts.append(bubble)
	_layout_toasts()

	var tween := create_tween()
	tween.tween_property(bubble, "modulate:a", 1.0, TOAST_FADE)
	tween.tween_interval(TOAST_LIFETIME)
	tween.tween_property(bubble, "modulate:a", 0.0, TOAST_FADE)
	tween.tween_callback(func() -> void:
		_toasts.erase(bubble)
		if is_instance_valid(bubble):
			bubble.queue_free()
		_layout_toasts()
	)


func _layout_toasts() -> void:
	var viewport := get_viewport_rect().size
	var x: float = viewport.x - 430.0
	var y: float = min(viewport.y - 360.0, 360.0)
	for i in _toasts.size():
		var bubble := _toasts[i]
		if not is_instance_valid(bubble):
			continue
		bubble.position = Vector2(x, y - i * (TOAST_HEIGHT + TOAST_PADDING))
		bubble.custom_minimum_size = Vector2(400, TOAST_HEIGHT)
		bubble.size = Vector2(400, TOAST_HEIGHT)
		bubble.clip_contents = true


func _bubble_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.05, 0.9)
	style.border_color = Color(0.52, 0.38, 0.18, 0.85)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
