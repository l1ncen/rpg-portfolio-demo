class_name StatsPanel
extends PanelBase
## 角色属性面板：实时显示全维度属性，字号/行距 Inspector 可调

@export var row_font_size: int = 15:
	set(v):
		row_font_size = v
		_apply_style()
@export var row_separation: int = 6

var rows: Dictionary = {}

const ROW_KEYS := [
	"职业", "等级", "生命", "法力", "攻击", "防御",
	"暴击率", "暴击伤害", "法力回复", "技能增伤", "生命偷取",
	"经验加成", "自由点", "金币", "血药", "蓝药",
]

func _ready() -> void:
	super._ready()
	content.add_theme_constant_override("separation", row_separation)
	for key in ROW_KEYS:
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.custom_minimum_size = Vector2(110, 0)
		var value_lbl := Label.new()
		row.add_child(name_lbl)
		row.add_child(value_lbl)
		content.add_child(row)
		rows[key] = {"name": name_lbl, "value": value_lbl}
	_apply_style()

func update_panel(player: Player) -> void:
	var cfg := player.class_config
	var pct := func(v: float): return "%.1f%%" % (v * 100.0)
	_set_row("职业", "%s（%s）" % [cfg.display_name, cfg.role_desc])
	_set_row("等级", "Lv.%d" % player.level)
	_set_row("生命", "%d / %d" % [player.cur_hp, player.max_hp()])
	_set_row("法力", "%d / %d" % [player.cur_mp, player.max_mp()])
	_set_row("攻击", "%s %s（%s）" % [player.attack_name(), "%.1f" % player.atk(), cfg.damage_type])
	_set_row("防御", "%.0f" % player.def_value())
	_set_row("暴击率", pct.call(player.crit_rate()))
	_set_row("暴击伤害", "%.1fx" % player.crit_dmg())
	_set_row("法力回复", "%d/回合" % player.mp_regen())
	_set_row("技能增伤", pct.call(player.skill_dmg_bonus()))
	_set_row("生命偷取", pct.call(player.lifesteal()))
	_set_row("经验加成", pct.call(player.exp_bonus()))
	_set_row("自由点", "%d 点" % player.free_points)
	_set_row("金币", "%d" % player.gold)
	_set_row("血药", "%d（+%d HP）" % [player.hp_potions, GameConfig.HP_POTION_RESTORE])
	_set_row("蓝药", "%d（+%d MP）" % [player.mp_potions, GameConfig.MP_POTION_RESTORE])

func _set_row(key: String, value: String) -> void:
	rows[key].name.text = key
	rows[key].value.text = value

func _apply_style() -> void:
	if not is_inside_tree():
		return
	for key in rows:
		rows[key].name.add_theme_font_size_override("font_size", row_font_size)
		rows[key].value.add_theme_font_size_override("font_size", row_font_size)
