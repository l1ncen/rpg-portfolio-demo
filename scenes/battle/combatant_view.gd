class_name CombatantView
extends VBoxContainer
## 战斗单位视图：立绘占位 + 名字 + HP/MP 条（玩家/怪物通用）

@export var portrait_size: Vector2 = Vector2(140, 140):
	set(v):
		portrait_size = v
		if portrait:
			portrait.custom_minimum_size = v
@export var show_mp: bool = true
@export var name_font_size: int = 18
@export var placeholder_color: Color = Color(0.35, 0.38, 0.45)
@export var hp_bar_color: Color = Color(0.88, 0.24, 0.24)
@export var mp_bar_color: Color = Color(0.3, 0.55, 0.95)

@onready var portrait: PortraitPlaceholder = $Portrait
@onready var name_label: Label = $NameLabel
@onready var hp_bar: StatBar = $HpBar
@onready var mp_bar: StatBar = $MpBar

func _ready() -> void:
	portrait.custom_minimum_size = portrait_size
	portrait.placeholder_color = placeholder_color
	name_label.add_theme_font_size_override("font_size", name_font_size)
	hp_bar.bar_color = hp_bar_color
	mp_bar.bar_color = mp_bar_color
	mp_bar.visible = show_mp

func setup(display_name: String, placeholder_text: String, art: Texture2D = null) -> void:
	name_label.text = display_name
	portrait.placeholder_text = placeholder_text
	if art:
		portrait.set_art(art)

func update_hp(cur: float, max_value: float) -> void:
	hp_bar.set_value(cur, max_value, "HP")

func update_mp(cur: float, max_value: float) -> void:
	mp_bar.set_value(cur, max_value, "MP")
