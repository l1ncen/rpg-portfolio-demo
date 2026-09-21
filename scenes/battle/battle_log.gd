class_name BattleLog
extends PanelContainer
## 战斗日志：保留最近 N 条战报，Inspector 可调条数/字号/颜色

@export var max_lines: int = 5:
	set(v):
		max_lines = max(1, v)
		_trim()
@export var font_size: int = 13:
	set(v):
		font_size = v
		if label:
			label.add_theme_font_size_override("font_size", v)
@export var default_color: Color = Color(0.9, 0.9, 0.9)
@export var player_color: Color = Color(0.5, 0.9, 1.0)
@export var enemy_color: Color = Color(1.0, 0.55, 0.4)
@export var reward_color: Color = Color(1.0, 0.85, 0.3)

@onready var label: Label = $MarginContainer/Label

func _ready() -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", default_color)

func push_line(text: String, color: Color = Color(0, 0, 0, 0)) -> void:
	if color.a <= 0.01:
		color = default_color
	label.text += text + "\n"
	var lines := label.text.split("\n", false)
	if lines.size() > max_lines:
		label.text = "\n".join(lines.slice(lines.size() - max_lines)) + "\n"

func clear() -> void:
	label.text = ""

func _trim() -> void:
	if not is_inside_tree() or not label:
		return
	var lines := label.text.split("\n", false)
	if lines.size() > max_lines:
		label.text = "\n".join(lines.slice(lines.size() - max_lines)) + "\n"
