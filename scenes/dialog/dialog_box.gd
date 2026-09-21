class_name DialogBox
extends PanelBase
## 对话框：NPC 名做标题 + 台词 + 选项按钮；选择后发 choice_made(index)

signal choice_made(index: int)

@export var line_font_size: int = 16
@export var line_color: Color = Color(0.94, 0.94, 0.90)
@export var choice_font_size: int = 15
@export var choice_min_width: float = 200.0

var _line_label: Label
var _choices_box: VBoxContainer

func _ready() -> void:
	super._ready()
	_line_label = Label.new()
	_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_label.add_theme_font_size_override("font_size", line_font_size)
	_line_label.add_theme_color_override("font_color", line_color)
	_line_label.custom_minimum_size = Vector2(0, 54)
	content.add_child(_line_label)
	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 8)
	content.add_child(_choices_box)

## 显示对话：npc 名为标题，line 为台词，choices 为选项文本
func show_dialog(npc: String, line: String, choices: Array[String]) -> void:
	title_text = npc
	_line_label.text = line
	for c in _choices_box.get_children():
		c.queue_free()
	for i in choices.size():
		var btn := Button.new()
		btn.text = choices[i]
		btn.custom_minimum_size = Vector2(choice_min_width, 40)
		btn.add_theme_font_size_override("font_size", choice_font_size)
		btn.pressed.connect(_on_choice.bind(i))
		_choices_box.add_child(btn)
	open()

func _on_choice(index: int) -> void:
	close()
	choice_made.emit(index)
