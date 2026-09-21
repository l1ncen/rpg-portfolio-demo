class_name Player
extends RefCounted

var class_config: ClassConfig
var level: int = 1
var cur_hp: float = 0.0
var cur_mp: float = 0.0
var gold: int = GameConfig.START_GOLD
var cur_exp: int = 0
var free_points: int = 0

var con_points: int = 0
var int_points: int = 0
var lck_points: int = 0
var str_points: int = 0

var equipped: Dictionary = {}
var inventory: Array = []

var hp_potions: int = 2
var mp_potions: int = 2

var reduce_buff: float = 0.0
var reduce_buff_turns: int = 0

func _init(cfg: ClassConfig) -> void:
	class_config = cfg
	cur_hp = max_hp()
	cur_mp = max_mp()

# ===== 派生属性（乘区来源在此汇聚）=====
func max_hp() -> float:
	return round(class_config.base_hp + class_config.con_growth * (level - 1) + con_points * GameConfig.HP_PER_CON + _equip_bonus("生命"))

func max_mp() -> float:
	return round(class_config.base_mp + class_config.int_growth * (level - 1) + int_points * GameConfig.MP_PER_INT + _equip_bonus("法力"))

func atk() -> float:
	return round((class_config.base_atk + class_config.str_growth * (level - 1) + str_points * GameConfig.ATK_PER_STR + _equip_bonus("攻击")) * 10.0) / 10.0

func def_value() -> float:
	return class_config.base_def + _equip_bonus("防御")

func crit_rate() -> float:
	return minf(class_config.base_crit_rate + lck_points * GameConfig.CRIT_RATE_PER_10_LCK + _equip_bonus("暴击率"), GameConfig.CRIT_RATE_CAP)

func crit_dmg() -> float:
	return minf(class_config.base_crit_dmg + lck_points * GameConfig.CRIT_DMG_PER_10_LCK + _equip_bonus("暴击伤害"), GameConfig.CRIT_DMG_CAP)

func mp_regen() -> int:
	return int(int_points / 10.0) + int(_equip_special("法力回复"))

func skill_dmg_bonus() -> float:
	return _equip_special("技能伤害")

func lifesteal() -> float:
	return _equip_special("生命偷取")

func exp_bonus() -> float:
	return _equip_special("经验增长") + _equip_bonus("经验获取")

func attack_name() -> String:
	return "物攻" if class_config.damage_type == "物理" else "法攻"

# ===== 装备 =====
func equip(item: Equipment) -> Equipment:
	inventory.erase(item)
	var old: Equipment = null
	if equipped.has(item.slot):
		old = equipped[item.slot]
		inventory.append(old)
	equipped[item.slot] = item
	return old

func unequip(slot: int) -> Equipment:
	if not equipped.has(slot):
		return null
	var item: Equipment = equipped[slot]
	equipped.erase(slot)
	inventory.append(item)
	return item

func sell_item(item: Equipment) -> void:
	if equipped.has(item.slot) and equipped[item.slot] == item:
		equipped.erase(item.slot)
	else:
		inventory.erase(item)
	gold += item.sell_price()

# ===== 加点 =====
func add_con() -> void:
	if free_points > 0:
		con_points += 1
		free_points -= 1
		cur_hp = minf(cur_hp + GameConfig.HP_PER_CON, max_hp())

func add_int() -> void:
	if free_points > 0:
		int_points += 1
		free_points -= 1
		cur_mp = minf(cur_mp + GameConfig.MP_PER_INT, max_mp())

func add_lck() -> void:
	if free_points > 0:
		lck_points += 1
		free_points -= 1

func add_str() -> void:
	if free_points > 0:
		str_points += 1
		free_points -= 1

# ===== 升级 =====
func gain_exp(amount: int) -> Array:
	var levels: Array = []
	cur_exp += int(round(amount * (1.0 + exp_bonus())))
	while level < GameConfig.MAX_LEVEL and cur_exp >= GameConfig.exp_to_next(level):
		cur_exp -= int(GameConfig.exp_to_next(level))
		level += 1
		free_points += GameConfig.FREE_POINTS_PER_LEVEL
		cur_hp = max_hp()
		cur_mp = max_mp()
		levels.append(level)
	return levels

# ===== 战斗 =====
func take_damage(raw: float) -> int:
	var dmg := raw * (1.0 - reduce_buff)
	var applied := int(round(dmg))
	cur_hp = maxf(cur_hp - applied, 0.0)
	return applied

func regen_mp() -> void:
	cur_mp = minf(cur_mp + mp_regen(), max_mp())

func heal_hp(amount: float) -> void:
	cur_hp = minf(cur_hp + amount, max_hp())

func heal_mp(amount: float) -> void:
	cur_mp = minf(cur_mp + amount, max_mp())

func apply_reduce_buff(value: float, turns: int) -> void:
	reduce_buff = value
	reduce_buff_turns = turns

func tick_buff() -> void:
	if reduce_buff_turns > 0:
		reduce_buff_turns -= 1
		if reduce_buff_turns == 0:
			reduce_buff = 0.0

func is_dead() -> bool:
	return cur_hp <= 0.0

func use_hp_potion() -> bool:
	if hp_potions <= 0 or cur_hp >= max_hp():
		return false
	hp_potions -= 1
	heal_hp(GameConfig.HP_POTION_RESTORE)
	return true

func use_mp_potion() -> bool:
	if mp_potions <= 0 or cur_mp >= max_mp():
		return false
	mp_potions -= 1
	heal_mp(GameConfig.MP_POTION_RESTORE)
	return true

func buy_hp_potion() -> bool:
	if gold < GameConfig.HP_POTION_PRICE or hp_potions >= GameConfig.HP_POTION_MAX:
		return false
	gold -= GameConfig.HP_POTION_PRICE
	hp_potions += 1
	return true

func buy_mp_potion() -> bool:
	if gold < GameConfig.MP_POTION_PRICE or mp_potions >= GameConfig.MP_POTION_MAX:
		return false
	gold -= GameConfig.MP_POTION_PRICE
	mp_potions += 1
	return true

# ===== 装备词条聚合 =====
func _equip_bonus(stat: String) -> float:
	var total := 0.0
	for slot in equipped:
		var item: Equipment = equipped[slot]
		if item.primary_stat == stat:
			total += item.primary_value
		if item.secondary_stats.has(stat):
			total += item.secondary_stats[stat]
	return total

func _equip_special(key: String) -> float:
	var total := 0.0
	for slot in equipped:
		var item: Equipment = equipped[slot]
		if item.special_affixes.has(key):
			total += item.special_affixes[key]
	return total
