class_name CombatSimPanel
extends PanelBase
## 战斗模拟器（打桩）：选怪物 → 可视化调整数值（HP/攻/防） → 自动打桩统计
## 玩家用当前真实属性输出；技能优先、蓝不足转普攻、含回蓝与 DoT 逐跳（与实战公式一致）

@export var default_turns: int = 30
@export var turns_min: int = 5
@export var turns_max: int = 100
@export_group("数值调整范围")
@export var hp_min: float = 10.0
@export var hp_max: float = 5000.0
@export var atk_min: float = 0.0
@export var atk_max: float = 300.0
@export var def_min: float = 0.0
@export var def_max: float = 300.0
@export_group("样式")
@export var label_width: float = 96.0
@export var row_font_size: int = 15
@export var result_font_size: int = 15
@export var log_font_size: int = 12
@export var value_color: Color = Color(0.95, 0.85, 0.4)
@export var highlight_color: Color = Color(0.45, 0.9, 0.55)

var player: Player
var enemy_configs: Array[EnemyConfig] = []

var _enemy_option: OptionButton
var _level_spin: SpinBox
var _hp_spin: SpinBox
var _atk_spin: SpinBox
var _def_spin: SpinBox
var _turns_spin: SpinBox
var _run_btn: Button
var _result_label: RichTextLabel
var _log_label: Label

func _ready() -> void:
	super._ready()
	_build_ui()

func _build_ui() -> void:
	_enemy_option = OptionButton.new()
	_enemy_option.item_selected.connect(func(_i): _on_level_or_enemy_changed(false))
	content.add_child(_make_row("木桩", _enemy_option))

	_level_spin = _make_spin(1, 30, 1)
	_level_spin.value_changed.connect(func(_v): _on_level_or_enemy_changed(true))
	content.add_child(_make_row("等级", _level_spin))

	_hp_spin = _make_spin(hp_min, hp_max, 10)
	content.add_child(_make_row("生命 HP", _hp_spin))
	_atk_spin = _make_spin(atk_min, atk_max, 1)
	content.add_child(_make_row("攻击", _atk_spin))
	_def_spin = _make_spin(def_min, def_max, 1)
	content.add_child(_make_row("防御", _def_spin))

	_turns_spin = _make_spin(turns_min, turns_max, 5)
	_turns_spin.value = default_turns
	content.add_child(_make_row("打桩回合", _turns_spin))

	_run_btn = Button.new()
	_run_btn.text = "开始打桩"
	_run_btn.custom_minimum_size = Vector2(0, 42)
	_run_btn.add_theme_font_size_override("font_size", 16)
	_run_btn.pressed.connect(_on_run)
	content.add_child(_run_btn)

	_result_label = RichTextLabel.new()
	_result_label.bbcode_enabled = true
	_result_label.fit_content = true
	_result_label.add_theme_font_size_override("normal_font_size", result_font_size)
	_result_label.add_theme_font_size_override("bold_font_size", result_font_size)
	content.add_child(_result_label)
	_log_label = Label.new()
	_log_label.add_theme_font_size_override("font_size", log_font_size)
	_log_label.add_theme_color_override("font_color", Color(0.7, 0.72, 0.75))
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_log_label)

func _make_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(label_width, 0)
	lbl.add_theme_font_size_override("font_size", row_font_size)
	row.add_child(lbl)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.add_theme_font_size_override("font_size", row_font_size)
	row.add_child(control)
	return row

func _make_spin(min_v: float, max_v: float, step_v: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_v
	spin.max_value = max_v
	spin.step = step_v
	spin.allow_greater = false
	spin.allow_lesser = false
	return spin

## 注入玩家与怪物配置并刷新选项（main 调用）
func setup(p: Player, configs: Array[EnemyConfig]) -> void:
	player = p
	enemy_configs = configs
	_enemy_option.clear()
	for cfg in configs:
		var lv_text := ("Lv.%d" % cfg.level_min) if cfg.is_boss else ("Lv.%d-%d" % [cfg.level_min, cfg.level_max])
		_enemy_option.add_item("%s %s" % [lv_text, cfg.display_name])
	_sync_from_config()

func _current_config() -> EnemyConfig:
	var idx := _enemy_option.selected
	if idx < 0 or idx >= enemy_configs.size():
		return null
	return enemy_configs[idx]

## 选择怪物或手动改等级时：等级联动 + 数值重置为 .tres 基础值
func _on_level_or_enemy_changed(from_level: bool) -> void:
	var cfg := _current_config()
	if cfg == null:
		return
	if not from_level:
		_level_spin.min_value = cfg.level_min
		_level_spin.max_value = maxi(cfg.level_max, cfg.level_min)
		_level_spin.value = clampi(int(_level_spin.value), cfg.level_min, cfg.level_max)
	_sync_from_config()

func _sync_from_config() -> void:
	var cfg := _current_config()
	if cfg == null:
		return
	var lv := clampi(int(_level_spin.value), cfg.level_min, cfg.level_max)
	_level_spin.value = lv
	_hp_spin.value = cfg.hp_at(lv)
	_atk_spin.value = cfg.atk_at(lv)
	_def_spin.value = cfg.def
	_result_label.text = ""
	_log_label.text = ""

## 打桩主逻辑：木桩不还手，玩家技能优先、蓝不足普攻，每回合回蓝
func _on_run() -> void:
	if player == null or _current_config() == null:
		return
	var cfg := player.class_config
	var dummy_hp := int(round(_hp_spin.value))
	var dummy_def := _def_spin.value
	var turns := int(_turns_spin.value)

	var mp := int(player.cur_mp)
	var max_mp := int(player.max_mp())
	var total := 0
	var crit_count := 0
	var crit_chances := 0
	var kill_turn := -1
	var dot_ticks := 0
	var dot_per_tick := 0
	var dmg_seq: Array[int] = []

	for i in range(1, turns + 1):
		var turn_dmg := 0
		# 1) DoT 逐跳结算（与实战节奏一致）
		if dot_ticks > 0:
			turn_dmg += dot_per_tick
			dot_ticks -= 1
		# 2) 行动：技能优先
		if mp >= cfg.skill_mp:
			mp -= cfg.skill_mp
			if cfg.skill_type == "DoT":
				var dot_total := DamageCalculator.base_damage(player.atk(), cfg.skill_multiplier) * DamageCalculator.def_multiplier(dummy_def)
				dot_per_tick = int(round(dot_total / cfg.skill_dot_turns))
				turn_dmg += dot_per_tick
				dot_ticks = cfg.skill_dot_turns - 1
			else:
				var r := DamageCalculator.calc_damage(player.atk(), cfg.skill_multiplier, dummy_def, player.skill_dmg_bonus(), player.crit_rate(), player.crit_dmg())
				turn_dmg += r.damage
				crit_count += 1 if r.is_crit else 0
				crit_chances += 1
		else:
			var r := DamageCalculator.calc_damage(player.atk(), 1.0, dummy_def, player.skill_dmg_bonus(), player.crit_rate(), player.crit_dmg())
			turn_dmg += r.damage
			crit_count += 1 if r.is_crit else 0
			crit_chances += 1
		# 3) 回蓝
		mp = mini(int(max_mp), mp + int(player.mp_regen()))
		total += turn_dmg
		dmg_seq.append(turn_dmg)
		if kill_turn < 0 and total >= dummy_hp:
			kill_turn = i

	# ===== 统计展示 =====
	var avg := float(total) / float(turns)
	var crit_pct := (float(crit_count) / float(crit_chances) * 100.0) if crit_chances > 0 else 0.0
	var exp_skill := _expected_damage(cfg.skill_multiplier)
	var exp_normal := _expected_damage(1.0)

	var lines: Array[String] = []
	lines.append("木桩：Lv.%d %s" % [int(_level_spin.value), _current_config().display_name])
	lines.append("数值：HP %d · 攻击 %d · 防御 %d" % [dummy_hp, int(round(_atk_spin.value)), int(round(dummy_def))])
	lines.append("玩家：%s Lv.%d（攻 %.1f · 暴击 %.1f%% / %.1fx）" % [
		cfg.display_name, player.level, player.atk(), player.crit_rate() * 100.0, player.crit_dmg()])
	lines.append("[color=#%s]打桩 %d 回合：总伤害 %d（平均 %.1f/回合）[/color]" % [
		highlight_color.to_html(false), turns, total, avg])
	lines.append("暴击：%d 次（%.1f%%）" % [crit_count, crit_pct])
	if kill_turn > 0:
		lines.append("[color=#%s]击杀：第 %d 回合击杀木桩[/color]" % [highlight_color.to_html(false), kill_turn])
	else:
		lines.append("未击杀：剩 %d HP（还需约 %d 回合）" % [
			maxi(dummy_hp - total, 0), ceili(float(dummy_hp - total) / maxf(avg, 1.0))])
	lines.append("理论期望：技能 %.1f · 普攻 %.1f（每回合，含暴击）" % [exp_skill, exp_normal])
	_result_label.text = "[b]%s[/b]" % "\n".join(lines)
	_result_label.custom_minimum_size = Vector2(0, 0)

	# 战报：每 10 回合一行
	var log_lines: Array[String] = []
	for start in range(0, dmg_seq.size(), 10):
		var chunk: Array[String] = []
		for j in range(start, mini(start + 10, dmg_seq.size())):
			chunk.append("R%d:%d" % [j + 1, dmg_seq[j]])
		log_lines.append(" ".join(chunk))
	_log_label.text = "\n".join(log_lines)

func _expected_damage(mult: float) -> float:
	## 期望伤害 = 攻×倍率×减防×增伤×(1+暴击率×(暴伤-1))
	var cfg := _current_config()
	var def_v := _def_spin.value if cfg else 0.0
	return DamageCalculator.base_damage(player.atk(), mult) \
		* DamageCalculator.def_multiplier(def_v) \
		* DamageCalculator.damage_bonus_multiplier(player.skill_dmg_bonus()) \
		* (1.0 + player.crit_rate() * (player.crit_dmg() - 1.0))
