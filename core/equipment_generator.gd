class_name EquipmentGenerator
extends RefCounted

# 装备生成规则全部集中在 EquipmentData（data/equipment/equipment_data.gd）

static func generate(slot: int, quality: int, level: int) -> Equipment:
	var e := Equipment.new()
	e.slot = slot
	e.quality = quality
	e.level = level
	e.primary_stat = EquipmentData.SLOT_PRIMARY[slot]
	e.primary_value = _primary_value(slot, quality, level)
	if slot == Equipment.Slot.ACCESSORY:
		e.primary_stat = "暴击率" if randf() < 0.5 else "暴击伤害"
	var sub_count: int = EquipmentData.QUALITY_SUB_COUNT[quality]
	var pool: Array[String] = []
	pool.assign(EquipmentData.SUB_STAT_POOL)
	for i in sub_count:
		var key: String = pool.pick_random()
		pool.erase(key)
		e.secondary_stats[key] = _sub_value(key, level)
	var sp_count: int = EquipmentData.QUALITY_SPECIAL_COUNT[quality]
	var spool: Array[String] = []
	spool.assign(EquipmentData.SPECIAL_POOL)
	for i in sp_count:
		var key: String = spool.pick_random()
		spool.erase(key)
		e.special_affixes[key] = EquipmentData.SPECIAL_BASE[key]
	e.display_name = _make_name(e)
	return e

static func roll_quality(level: int, is_boss: bool) -> int:
	if is_boss:
		return Equipment.Quality.EPIC if randf() < 0.4 else Equipment.Quality.RARE
	var r := randf()
	var epic := 0.01 + 0.002 * level
	var rare := 0.08 + 0.004 * level
	if r < epic: return Equipment.Quality.EPIC
	if r < epic + rare: return Equipment.Quality.RARE
	if r < epic + rare + 0.25: return Equipment.Quality.UNCOMMON
	return Equipment.Quality.COMMON

static func roll_drop(level: int, is_boss: bool) -> Equipment:
	if not is_boss and randf() > EquipmentData.DEFAULT_DROP_CHANCE:
		return null
	return generate(Equipment.Slot.values().pick_random(), roll_quality(level, is_boss), level)

static func _primary_value(slot: int, quality: int, level: int) -> float:
	var base: float = EquipmentData.PRIMARY_BASE[slot]
	var mult: float = EquipmentData.QUALITY_VALUE_MULT[quality]
	var lvl_factor := 1.0 + EquipmentData.LEVEL_FACTOR * (level - 1)
	if slot == Equipment.Slot.ACCESSORY and randf() >= 0.5:
		return base * EquipmentData.CRIT_RATE_TO_DMG * mult * lvl_factor
	return base * mult * lvl_factor

static func _sub_value(key: String, level: int) -> float:
	var base: float = EquipmentData.SUB_STAT_BASE.get(key, 0.0)
	var lvl_factor := 1.0 + EquipmentData.LEVEL_FACTOR * (level - 1) * 0.5
	if base < 1.0:
		return base * lvl_factor
	return round(base * lvl_factor)

static func _make_name(e: Equipment) -> String:
	var prefix := ""
	if e.primary_stat == "暴击率" or e.primary_stat == "暴击伤害":
		prefix = "幸运"
	elif not e.secondary_stats.is_empty():
		prefix = EquipmentData.STAT_PREFIX.get(e.secondary_stats.keys()[0], "锋利")
	else:
		prefix = "锋利"
	return "%s之%s" % [prefix, EquipmentData.SLOT_SUFFIX[e.slot]]

static func _roll(p: float) -> bool:
	return randf() < p
