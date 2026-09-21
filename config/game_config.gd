class_name GameConfig
extends RefCounted

# ===== 属性点收益（需求 §4）=====
const HP_PER_CON := 20.0
const MP_PER_INT := 10.0
const MP_REGEN_PER_10_INT := 1.0
const ATK_PER_STR := 3.0
const CRIT_RATE_PER_10_LCK := 0.01
const CRIT_DMG_PER_10_LCK := 0.02

# ===== 升级（需求 §7）=====
const FREE_POINTS_PER_LEVEL := 5
const MAX_LEVEL := 20

# ===== 乘区上限（需求 §2.1）=====
const CRIT_RATE_CAP := 0.5
const CRIT_DMG_CAP := 2.5
const DMG_BONUS_CAP := 1.0
const DEF_MULTIPLIER_FLOOR := 0.5

# ===== 经验曲线（需求 §7.2）=====
const EXP_BASE := 60.0
const EXP_GROWTH := 0.3

static func exp_to_next(level: int) -> float:
	return round(EXP_BASE * level * (1.0 + EXP_GROWTH * (level - 1)))

# ===== 经济（需求 §9）=====
const HP_POTION_PRICE := 30
const MP_POTION_PRICE := 30
const HP_POTION_RESTORE := 80
const MP_POTION_RESTORE := 40
const EQUIP_SELL_PRICE_MULT := 10.0
const START_GOLD := 0

# ===== 药水（需求 §9.1 购买药水）=====
const HP_POTION_MAX := 5
const MP_POTION_MAX := 5
