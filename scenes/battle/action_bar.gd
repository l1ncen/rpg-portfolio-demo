class_name ActionBar
extends VBoxContainer
## 动作栏：上行战斗指令（普攻/技能/药水），下行功能入口（角色/装备/加点）
## 按钮布局参数、字号全部 Inspector 可调

@export var button_min_width: float = 120.0:
	set(v):
		button_min_width = v
		_apply_buttons()
@export var button_height: float = 44.0:
	set(v):
		button_height = v
		_apply_buttons()
@export var font_size: int = 16:
	set(v):
		font_size = v
		_apply_buttons()
@export var attack_text: String = "普攻":
	set(v):
		attack_text = v
		if attack_btn: attack_btn.text = v
@export var hp_potion_text: String = "血药":
	set(v):
		hp_potion_text = v
		if hp_potion_btn: hp_potion_btn.text = v
@export var mp_potion_text: String = "蓝药":
	set(v):
		mp_potion_text = v
		if mp_potion_btn: mp_potion_btn.text = v

signal attack_pressed
signal skill_pressed
signal hp_potion_pressed
signal mp_potion_pressed
signal stats_pressed
signal equip_pressed
signal alloc_pressed

@onready var attack_btn: Button = $ActionRow/AttackBtn
@onready var skill_btn: Button = $ActionRow/SkillBtn
@onready var hp_potion_btn: Button = $ActionRow/HpPotionBtn
@onready var mp_potion_btn: Button = $ActionRow/MpPotionBtn
@onready var stats_btn: Button = $MenuRow/StatsBtn
@onready var equip_btn: Button = $MenuRow/EquipBtn
@onready var alloc_btn: Button = $MenuRow/AllocBtn

func _ready() -> void:
	_apply_buttons()
	attack_btn.pressed.connect(func(): attack_pressed.emit())
	skill_btn.pressed.connect(func(): skill_pressed.emit())
	hp_potion_btn.pressed.connect(func(): hp_potion_pressed.emit())
	mp_potion_btn.pressed.connect(func(): mp_potion_pressed.emit())
	stats_btn.pressed.connect(func(): stats_pressed.emit())
	equip_btn.pressed.connect(func(): equip_pressed.emit())
	alloc_btn.pressed.connect(func(): alloc_pressed.emit())

func set_skill(label_text: String) -> void:
	skill_btn.text = label_text

func set_potions(hp_count: int, mp_count: int) -> void:
	hp_potion_btn.text = "%s(%d)" % [hp_potion_text, hp_count]
	mp_potion_btn.text = "%s(%d)" % [mp_potion_text, mp_count]
	hp_potion_btn.disabled = hp_count <= 0
	mp_potion_btn.disabled = mp_count <= 0

func set_skill_enabled(enabled: bool) -> void:
	skill_btn.disabled = not enabled

func set_locked(locked: bool) -> void:
	attack_btn.disabled = locked
	skill_btn.disabled = locked
	hp_potion_btn.disabled = locked or hp_potion_btn.text.ends_with("(0)")
	mp_potion_btn.disabled = locked or mp_potion_btn.text.ends_with("(0)")

func _apply_buttons() -> void:
	if not is_inside_tree():
		return
	for btn: Button in [attack_btn, skill_btn, hp_potion_btn, mp_potion_btn, stats_btn, equip_btn, alloc_btn]:
		if btn:
			btn.custom_minimum_size = Vector2(button_min_width, button_height)
			btn.add_theme_font_size_override("font_size", font_size)
	if attack_btn:
		attack_btn.text = attack_text
