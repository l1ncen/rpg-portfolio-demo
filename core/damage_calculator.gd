class_name DamageCalculator
extends RefCounted

# 多乘区伤害模型：总伤害 = 基础伤害 × 减防乘区 × 增伤乘区 × 双爆乘区（需求 §2.1）

static func base_damage(atk: float, multiplier: float) -> float:
	return atk * multiplier

static func def_multiplier(target_def: float) -> float:
	return maxf(GameConfig.DEF_MULTIPLIER_FLOOR, 100.0 / (target_def + 100.0))

static func damage_bonus_multiplier(bonus: float) -> float:
	return 1.0 + clampf(bonus, 0.0, GameConfig.DMG_BONUS_CAP)

static func roll_crit_multiplier(crit_rate: float, crit_dmg: float) -> Dictionary:
	var rate := clampf(crit_rate, 0.0, GameConfig.CRIT_RATE_CAP)
	var dmg := clampf(crit_dmg, 1.0, GameConfig.CRIT_DMG_CAP)
	if randf() < rate:
		return {"is_crit": true, "value": dmg}
	return {"is_crit": false, "value": 1.0}

static func calc_damage(atk: float, multiplier: float, target_def: float, bonus: float, crit_rate: float, crit_dmg: float) -> Dictionary:
	var base := base_damage(atk, multiplier)
	var def_mult := def_multiplier(target_def)
	var bonus_mult := damage_bonus_multiplier(bonus)
	var crit: Dictionary = roll_crit_multiplier(crit_rate, crit_dmg)
	var total: float = base * def_mult * bonus_mult * float(crit.value)
	return {
		"damage": int(round(total)),
		"is_crit": bool(crit.is_crit),
		"base": base,
		"def_mult": def_mult,
		"bonus_mult": bonus_mult,
		"crit_mult": crit.value,
	}
