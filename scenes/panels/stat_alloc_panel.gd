class_name StatAllocPanel
extends PanelBase
## 加点面板：4 属性行各带 +1 按钮，剩余点不足时自动禁用；收益文案 Inspector 可调

@export var stat_names: Array[String] = ["体质", "智慧", "幸运", "统御"]
@export var stat_effects: Array[String] = [
	"+%d 生命/点" % int(GameConfig.HP_PER_CON),
	"+%d 法力/点，每10点+1回蓝" % int(GameConfig.MP_PER_INT),
	"每10点 +%d%%暴击 +%.0f%%暴伤" % [GameConfig.CRIT_RATE_PER_10_LCK * 100.0, GameConfig.CRIT_DMG_PER_10_LCK * 100.0],
	"+%d 攻击/点" % int(GameConfig.ATK_PER_STR),
]
@export var font_size: int = 15:
	set(v):
		font_size = v
		_apply_style()

signal allocate(stat_index: int)

var rows: Array = []
var points_label: Label

func _ready() -> void:
	super._ready()
	points_label = Label.new()
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(points_label)
	for i in stat_names.size():
		var idx := i
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.custom_minimum_size = Vector2(56, 0)
		var value_lbl := Label.new()
		value_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var add_btn := Button.new()
		add_btn.text = "+1"
		add_btn.pressed.connect(func(): allocate.emit(idx))
		row.add_child(name_lbl)
		row.add_child(value_lbl)
		row.add_child(add_btn)
		content.add_child(row)
		rows.append({"name": name_lbl, "value": value_lbl, "btn": add_btn})
	var hint := Label.new()
	hint.text = "效果：" + "；".join(stat_effects)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	content.add_child(hint)
	_apply_style()

func update_panel(player: Player) -> void:
	points_label.text = "剩余自由点：%d" % player.free_points
	var values := [
		"%d 点 → 生命 %d" % [player.con_points, player.max_hp()],
		"%d 点 → 法力 %d（回蓝 %d/回合）" % [player.int_points, player.max_mp(), player.mp_regen()],
		"%d 点 → 暴击 %.1f%% / 暴伤 %.1fx" % [player.lck_points, player.crit_rate() * 100.0, player.crit_dmg()],
		"%d 点 → %s %.1f" % [player.str_points, player.attack_name(), player.atk()],
	]
	for i in rows.size():
		rows[i].name.text = stat_names[i]
		rows[i].value.text = values[i]
		rows[i].btn.disabled = player.free_points <= 0

func _apply_style() -> void:
	if not is_inside_tree():
		return
	if points_label:
		points_label.add_theme_font_size_override("font_size", font_size + 2)
	for row: Dictionary in rows:
		row.name.add_theme_font_size_override("font_size", font_size)
		row.value.add_theme_font_size_override("font_size", font_size)
		row.btn.add_theme_font_size_override("font_size", font_size)
