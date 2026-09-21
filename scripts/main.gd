extends Control
## 薄编排器：只做回合流转与信号接线；UI 细节在各子场景，数值在 GameConfig / .tres

@export var enemy_configs: Array[EnemyConfig] = []

@export_group("战斗节奏")
@export var enemy_turn_delay: float = 0.5
@export var next_enemy_delay: float = 0.8

@export_group("美术占位（拖入 Texture2D 即替换色块）")
@export var player_art: Texture2D
@export var enemy_art: Texture2D
@export var player_placeholder_text: String = "玩家"
@export_group("玩家死亡处理", "revive_")
@export var revive_on_death: bool = true

var player: Player
var enemy: Enemy
var busy := false
var defeated_count := 0

@onready var top_bar: TopStatusBar = $BattleRoot/Column/TopBar
@onready var enemy_view: CombatantView = $BattleRoot/Column/EnemyView
@onready var battle_log: BattleLog = $BattleRoot/Column/Log
@onready var player_view: CombatantView = $BattleRoot/Column/PlayerView
@onready var action_bar: ActionBar = $BattleRoot/Column/Actions
@onready var float_layer: Control = $FloatLayer
@onready var class_select_panel: ClassSelectPanel = $ClassSelect
@onready var stats_panel: StatsPanel = $Stats
@onready var equip_panel: EquipmentPanel = $Equip
@onready var alloc_panel: StatAllocPanel = $Alloc
@onready var level_up_popup: LevelUpPopup = $LevelUp
@onready var world_map: WorldMap = $WorldMap
@onready var dialog_box: DialogBox = $DialogBox
@onready var combat_sim: CombatSimPanel = $CombatSim

func _ready() -> void:
	_connect()
	class_select_panel.open()

func _connect() -> void:
	class_select_panel.class_picked.connect(_on_class_picked)
	action_bar.attack_pressed.connect(_on_attack)
	action_bar.skill_pressed.connect(_on_skill)
	action_bar.hp_potion_pressed.connect(func(): _use_potion(true))
	action_bar.mp_potion_pressed.connect(func(): _use_potion(false))
	action_bar.stats_pressed.connect(func(): stats_panel.update_panel(player); stats_panel.open())
	action_bar.equip_pressed.connect(func(): equip_panel.update_panel(player); equip_panel.open())
	action_bar.alloc_pressed.connect(func(): alloc_panel.update_panel(player); alloc_panel.open())
	top_bar.buy_hp_potion_pressed.connect(func(): player.buy_hp_potion(); _refresh())
	top_bar.buy_mp_potion_pressed.connect(func(): player.buy_mp_potion(); _refresh())
	alloc_panel.allocate.connect(_on_allocate)
	equip_panel.equip_requested.connect(_on_equip_item)
	equip_panel.unequip_requested.connect(_on_unequip_slot)
	equip_panel.sell_requested.connect(_on_sell_item)
	world_map.battle_requested.connect(_start_battle)
	world_map.sim_requested.connect(_open_sim_dialog)
	dialog_box.choice_made.connect(_on_dialog_choice)
	combat_sim.closed.connect(func(): world_map.set_active(true))

# ===== 开局 =====
func _on_class_picked(cfg: ClassConfig) -> void:
	player = Player.new(cfg)
	player_view.setup("%s Lv.%d" % [cfg.display_name, player.level], player_placeholder_text, player_art)
	action_bar.set_skill("%s(%dMP)" % [cfg.skill_name, cfg.skill_mp])
	battle_log.push_line("选择了职业：%s（%s）" % [cfg.display_name, cfg.role_desc], battle_log.player_color)
	world_map.setup(cfg.display_name, player_art, enemy_art)
	_refresh()
	_enter_map()

# ===== 地图 =====
func _enter_map() -> void:
	enemy_view.visible = false
	battle_log.visible = false
	player_view.visible = false
	action_bar.visible = false
	world_map.visible = true
	world_map.set_active(true)
	busy = false
	action_bar.set_locked(false)
	_refresh()

func _start_battle() -> void:
	world_map.visible = false
	enemy_view.visible = true
	battle_log.visible = true
	player_view.visible = true
	action_bar.visible = true
	_next_enemy()

func _open_sim_dialog() -> void:
	dialog_box.show_dialog("练功师父",
		"想看看自己的输出？我这有各种木桩，数值随你调——选个怪，改改数值，打一轮就知道伤害成色了。",
		["开始打桩模拟", "先不了，谢谢"])

func _on_dialog_choice(index: int) -> void:
	if index == 0:
		combat_sim.setup(player, enemy_configs)
		combat_sim.open()
	else:
		world_map.set_active(true)

# ===== 敌人生成 =====
func _next_enemy() -> void:
	var candidates: Array[EnemyConfig] = []
	for cfg in enemy_configs:
		if player.level >= cfg.level_min and player.level <= cfg.level_max + 4:
			candidates.append(cfg)
	if candidates.is_empty():
		candidates = [enemy_configs[0]]
	var cfg: EnemyConfig = candidates.pick_random()
	var lv := cfg.level_max if cfg.is_boss else clampi(player.level, cfg.level_min, cfg.level_max)
	enemy = Enemy.new(cfg, lv)
	enemy_view.setup("Lv.%d %s" % [lv, cfg.display_name], cfg.display_name, enemy_art)
	battle_log.push_line("遭遇 Lv.%d %s：%s" % [lv, cfg.display_name, cfg.desc], battle_log.enemy_color)
	_refresh()

# ===== 玩家行动 =====
func _on_attack() -> void:
	if busy or not _can_act():
		return
	var r := DamageCalculator.calc_damage(player.atk(), 1.0, enemy.def_value(), player.skill_dmg_bonus(), player.crit_rate(), player.crit_dmg())
	var applied := enemy.take_damage(r.damage)
	_show_float(enemy_view, str(applied), r.is_crit)
	battle_log.push_line("普攻造成 %d 伤害%s" % [applied, "（暴击！）" if r.is_crit else ""], battle_log.player_color)
	_apply_lifesteal(applied)
	_after_player_action()

func _on_skill() -> void:
	if busy or not _can_act():
		return
	var cfg := player.class_config
	if player.cur_mp < cfg.skill_mp:
		battle_log.push_line("法力不足，无法释放 %s" % cfg.skill_name)
		return
	player.cur_mp -= cfg.skill_mp
	if cfg.skill_type == "DoT":
		var total := DamageCalculator.base_damage(player.atk(), cfg.skill_multiplier) * DamageCalculator.def_multiplier(enemy.def_value())
		var first := enemy.add_dot(int(round(total / cfg.skill_dot_turns)), cfg.skill_dot_turns)
		var applied := enemy.take_damage(first)
		_show_float(enemy_view, str(applied), false)
		battle_log.push_line("%s：毒雾弥漫，每回合结算 %d 伤害" % [cfg.skill_name, applied], battle_log.player_color)
	else:
		var r := DamageCalculator.calc_damage(player.atk(), cfg.skill_multiplier, enemy.def_value(), player.skill_dmg_bonus(), player.crit_rate(), player.crit_dmg())
		var applied := enemy.take_damage(r.damage)
		_show_float(enemy_view, str(applied), r.is_crit)
		battle_log.push_line("%s造成 %d 伤害%s" % [cfg.skill_name, applied, "（暴击！）" if r.is_crit else ""], battle_log.player_color)
		_apply_lifesteal(applied)
		if cfg.skill_effect == "减伤" and cfg.skill_effect_turns > 0:
			player.apply_reduce_buff(cfg.skill_effect_value, cfg.skill_effect_turns)
			battle_log.push_line("获得 %d%% 减伤，持续 %d 回合" % [int(cfg.skill_effect_value * 100.0), cfg.skill_effect_turns])
	_after_player_action()

func _use_potion(is_hp: bool) -> void:
	if busy or player == null:
		return
	var ok := player.use_hp_potion() if is_hp else player.use_mp_potion()
	if ok:
		var view := player_view
		_show_float(view, "+%d" % (GameConfig.HP_POTION_RESTORE if is_hp else GameConfig.MP_POTION_RESTORE), false, true)
		_refresh()

# ===== 敌人回合 =====
func _after_player_action() -> void:
	busy = true
	action_bar.set_locked(true)
	_refresh()
	if enemy.is_dead():
		_on_enemy_defeated()
		return
	_enemy_turn()

func _enemy_turn() -> void:
	await get_tree().create_timer(enemy_turn_delay).timeout
	for dmg in enemy.tick_dots():
		_show_float(enemy_view, str(dmg), false)
		battle_log.push_line("毒雾造成 %d 伤害" % dmg, battle_log.player_color)
	if enemy.is_dead():
		_on_enemy_defeated()
		return
	var raw := enemy.atk() * DamageCalculator.def_multiplier(player.def_value())
	var applied := player.take_damage(raw)
	_show_float(player_view, str(applied), false)
	battle_log.push_line("%s 造成 %d 伤害" % [enemy.config.display_name, applied], battle_log.enemy_color)
	if player.is_dead():
		_on_player_defeated()
		return
	player.regen_mp()
	player.tick_buff()
	_refresh()
	busy = false
	action_bar.set_locked(false)

# ===== 结算 =====
func _on_enemy_defeated() -> void:
	defeated_count += 1
	var exp_reward := enemy.exp_reward()
	var gold_reward := enemy.gold_reward()
	player.gold += gold_reward
	var levels := player.gain_exp(exp_reward)
	battle_log.push_line("击败 %s！+%d 经验 +%d 金币" % [enemy.config.display_name, exp_reward, gold_reward], battle_log.reward_color)
	var drop := EquipmentGenerator.roll_drop(enemy.level, enemy.config.is_boss)
	if drop:
		player.inventory.append(drop)
		battle_log.push_line("掉落：%s" % drop.summary(), battle_log.reward_color)
	_refresh()
	if not levels.is_empty():
		level_up_popup.show_levels(levels)
	await get_tree().create_timer(next_enemy_delay).timeout
	_enter_map()

func _on_player_defeated() -> void:
	battle_log.push_line("你倒下了……", battle_log.enemy_color)
	if revive_on_death:
		player.cur_hp = player.max_hp()
		player.cur_mp = player.max_mp()
		battle_log.push_line("原地满状态复活（Demo 无死亡惩罚）")
	_refresh()
	await get_tree().create_timer(next_enemy_delay).timeout
	_enter_map()

# ===== 面板操作 =====
func _on_allocate(stat_index: int) -> void:
	match stat_index:
		0: player.add_con()
		1: player.add_int()
		2: player.add_lck()
		3: player.add_str()
	_refresh()
	alloc_panel.update_panel(player)

func _on_equip_item(index: int) -> void:
	if index < player.inventory.size():
		var item: Equipment = player.inventory[index]
		player.equip(item)
		battle_log.push_line("穿上：%s" % item.display_name)
		_refresh()
		equip_panel.update_panel(player)

func _on_unequip_slot(slot: int) -> void:
	if player.equipped.has(slot):
		var item: Equipment = player.unequip(slot)
		battle_log.push_line("脱下：%s" % item.display_name)
		_refresh()
		equip_panel.update_panel(player)

func _on_sell_item(index: int) -> void:
	if index < player.inventory.size():
		var item: Equipment = player.inventory[index]
		player.sell_item(item)
		battle_log.push_line("出售：%s（+%d 金币）" % [item.display_name, item.sell_price()], battle_log.reward_color)
		_refresh()
		equip_panel.update_panel(player)

# ===== 工具 =====
func _can_act() -> bool:
	return player != null and enemy != null and not player.is_dead()

func _apply_lifesteal(applied: int) -> void:
	if player.lifesteal() > 0.0:
		var heal := int(round(applied * player.lifesteal()))
		if heal > 0:
			player.heal_hp(heal)
			_show_float(player_view, "+%d" % heal, false, true)

func _show_float(view: CombatantView, text: String, crit: bool, heal: bool = false) -> void:
	var pos := view.global_position + view.size * 0.5 + Vector2(randf_range(-30.0, 30.0), -20.0)
	FloatingText.spawn(float_layer, pos, text, crit, heal)

func _refresh() -> void:
	if player:
		top_bar.update_status(player.level, player.gold, player.cur_exp, int(GameConfig.exp_to_next(player.level)), player)
		player_view.update_hp(player.cur_hp, player.max_hp())
		player_view.update_mp(player.cur_mp, player.max_mp())
		action_bar.set_potions(player.hp_potions, player.mp_potions)
		action_bar.set_skill_enabled(player.cur_mp >= player.class_config.skill_mp)
		var cfg := player.class_config
		player_view.name_label.text = "%s Lv.%d" % [cfg.display_name, player.level]
	if enemy:
		enemy_view.update_hp(enemy.cur_hp, enemy.max_hp())
