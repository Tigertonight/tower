class_name ThemeFactory
extends RefCounted


static func build_theme() -> Theme:
	var theme := Theme.new()
	var font_color := Color(0.91, 0.86, 0.76)
	var muted := Color(0.66, 0.62, 0.55)
	var panel := Color(0.15, 0.16, 0.17)
	var panel_hover := Color(0.22, 0.20, 0.16)
	var accent := Color(0.78, 0.58, 0.25)
	var disabled := Color(0.18, 0.18, 0.18)

	theme.set_color("font_color", "Label", font_color)
	theme.set_color("font_disabled_color", "Button", muted)
	theme.set_color("font_color", "Button", font_color)
	theme.set_color("font_hover_color", "Button", Color(1.0, 0.91, 0.68))
	theme.set_color("font_pressed_color", "Button", Color(1.0, 0.85, 0.48))

	theme.set_stylebox("normal", "PanelContainer", _flat_box(panel, accent, 1))
	theme.set_stylebox("normal", "Button", _flat_box(Color(0.13, 0.14, 0.15), Color(0.38, 0.31, 0.20), 1))
	theme.set_stylebox("hover", "Button", _flat_box(panel_hover, accent, 2))
	theme.set_stylebox("pressed", "Button", _flat_box(Color(0.26, 0.20, 0.12), accent, 2))
	theme.set_stylebox("disabled", "Button", _flat_box(disabled, Color(0.28, 0.27, 0.25), 1))
	theme.set_stylebox("background", "ProgressBar", _flat_box(Color(0.09, 0.08, 0.07), Color(0.25, 0.20, 0.14), 1))
	theme.set_stylebox("fill", "ProgressBar", _flat_box(Color(0.60, 0.12, 0.10), Color(0.92, 0.28, 0.18), 0))
	theme.set_color("font_color", "ProgressBar", font_color)
	return theme


static func _flat_box(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
