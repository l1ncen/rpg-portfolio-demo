class_name LevelUpPopup
extends PanelBase
## 升级弹窗：文案模板 Inspector 可调（{levels} 为占位符）

@export var body_template: String = "等级提升至 {levels}！\n获得 {points} 点自由属性点，可在「加点」中分配。"
@export var body_font_size: int = 16
@export var confirm_text: String = "太棒了"

var body_label: Label
var confirm_btn: Button

func _ready() -> void:
	super._ready()
	title_font_size = 24
	title_label.add_theme_font_size_override("font_size", title_font_size)
	body_label = Label.new()
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.add_theme_font_size_override("font_size", body_font_size)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(body_label)
	confirm_btn = Button.new()
	confirm_btn.text = confirm_text
	confirm_btn.custom_minimum_size = Vector2(0, 44)
	confirm_btn.pressed.connect(close)
	content.add_child(confirm_btn)

func show_levels(new_levels: Array) -> void:
	var lv_text := "、".join(new_levels.map(func(v): return "Lv.%d" % v))
	body_label.text = body_template.format({"levels": lv_text, "points": new_levels.size() * GameConfig.FREE_POINTS_PER_LEVEL})
	open()
