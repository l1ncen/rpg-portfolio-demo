class_name StatBar
extends VBoxContainer
## 数值条：Label(文字) + ProgressBar，颜色/字号 Inspector 可调

@export var bar_color: Color = Color(0.88, 0.24, 0.24):
	set(v):
		bar_color = v
		_apply_color()
@export var text_color: Color = Color.WHITE:
	set(v):
		text_color = v
		if label:
			label.add_theme_color_override("font_color", v)
@export var font_size: int = 14:
	set(v):
		font_size = v
		if label:
			label.add_theme_font_size_override("font_size", v)
@export var bar_height: int = 14:
	set(v):
		bar_height = v
		if bar:
			bar.custom_minimum_size = Vector2(0, v)
## 显示数值还是百分比
@export var show_percent: bool = false

@onready var label: Label = $Label
@onready var bar: ProgressBar = $ProgressBar

func _ready() -> void:
	_apply_color()

func set_value(cur: float, max_value: float, prefix: String = "") -> void:
	bar.max_value = maxf(max_value, 1.0)
	bar.value = clampf(cur, 0.0, max_value)
	if show_percent and max_value > 0.0:
		label.text = "%s %d%%" % [prefix, round(cur / max_value * 100.0)]
	else:
		label.text = "%s %d/%d" % [prefix, round(cur), round(max_value)]

func _apply_color() -> void:
	if not is_inside_tree():
		return
	if bar:
		bar.modulate = bar_color
	if label:
		label.add_theme_color_override("font_color", text_color)
		label.add_theme_font_size_override("font_size", font_size)
