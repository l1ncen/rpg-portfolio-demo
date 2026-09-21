class_name TopStatusBar
extends PanelContainer
## 顶部状态栏：等级 / 金币 / 经验条 / 药水快捷购买，参数 Inspector 可调

@export var font_size: int = 15:
	set(v):
		font_size = v
		_apply_style()
@export var gold_color: Color = Color(1.0, 0.85, 0.3)
@export var exp_bar_color: Color = Color(0.75, 0.55, 1.0)
@export var exp_bar_height: int = 12
@export var show_potion_shop: bool = true

signal buy_hp_potion_pressed
signal buy_mp_potion_pressed

@onready var level_label: Label = $MarginContainer/HBox/LevelLabel
@onready var gold_label: Label = $MarginContainer/HBox/GoldLabel
@onready var buy_hp_btn: Button = $MarginContainer/HBox/BuyHpBtn
@onready var buy_mp_btn: Button = $MarginContainer/HBox/BuyMpBtn
@onready var exp_bar: ProgressBar = $MarginContainer/ExpBar

func _ready() -> void:
	_apply_style()
	buy_hp_btn.visible = show_potion_shop
	buy_mp_btn.visible = show_potion_shop
	buy_hp_btn.pressed.connect(func(): buy_hp_potion_pressed.emit())
	buy_mp_btn.pressed.connect(func(): buy_mp_potion_pressed.emit())

func update_status(level: int, gold: int, cur_exp: int, exp_next: int, player: Player = null) -> void:
	level_label.text = "Lv.%d" % level
	gold_label.text = "%d 金币" % gold
	exp_bar.max_value = maxf(exp_next, 1.0)
	exp_bar.value = cur_exp
	if player:
		buy_hp_btn.disabled = player.gold < GameConfig.HP_POTION_PRICE or player.hp_potions >= GameConfig.HP_POTION_MAX
		buy_mp_btn.disabled = player.gold < GameConfig.MP_POTION_PRICE or player.mp_potions >= GameConfig.MP_POTION_MAX
		buy_hp_btn.text = "买血药(%d)" % player.hp_potions
		buy_mp_btn.text = "买蓝药(%d)" % player.mp_potions

func _apply_style() -> void:
	if not is_inside_tree():
		return
	for lbl: Label in [level_label, gold_label]:
		if lbl:
			lbl.add_theme_font_size_override("font_size", font_size)
	if gold_label:
		gold_label.add_theme_color_override("font_color", gold_color)
	if exp_bar:
		exp_bar.custom_minimum_size = Vector2(0, exp_bar_height)
		exp_bar.modulate = exp_bar_color
	if buy_hp_btn:
		buy_hp_btn.add_theme_font_size_override("font_size", font_size)
		buy_mp_btn.add_theme_font_size_override("font_size", font_size)
