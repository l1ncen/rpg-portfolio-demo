class_name Equipment
extends RefCounted

enum Slot { WEAPON, ARMOR, HELMET, ACCESSORY }
enum Quality { COMMON, UNCOMMON, RARE, EPIC }

var slot: int = Slot.WEAPON
var quality: int = Quality.COMMON
var display_name: String = ""
var level: int = 1
var primary_stat: String = ""
var primary_value: float = 0.0
var secondary_stats: Dictionary = {}
var special_affixes: Dictionary = {}

const PERCENT_KEYS := ["经验获取", "经验增长", "生命偷取", "暴击率", "技能伤害"]

func summary() -> String:
	var parts: Array[String] = ["[%s] %s" % [slot_name(), display_name]]
	parts.append(_fmt_entry(primary_stat, primary_value))
	for k in secondary_stats:
		parts.append(_fmt_entry(k, secondary_stats[k]))
	for k in special_affixes:
		parts.append(_fmt_entry(k, special_affixes[k]))
	return " | ".join(parts)

func sell_price() -> int:
	return int(round((quality + 1) * GameConfig.EQUIP_SELL_PRICE_MULT + level))

func slot_name() -> String:
	return ["武器", "护具", "头饰", "手饰"][slot]

func quality_name() -> String:
	return ["普通", "优秀", "精良", "史诗"][quality]

func quality_color() -> Color:
	match quality:
		Quality.COMMON: return Color.WHITE
		Quality.UNCOMMON: return Color(0.4, 0.9, 0.45)
		Quality.RARE: return Color(0.35, 0.6, 1.0)
		_: return Color(0.85, 0.45, 1.0)

func _fmt(v: float) -> String:
	if absf(v) >= 10.0 or v == roundf(v):
		return str(int(round(v)))
	return "%.1f" % v

func _fmt_entry(key: String, v: float) -> String:
	if PERCENT_KEYS.has(key):
		return "%s +%.1f%%" % [key, v * 100.0]
	if key == "暴击伤害":
		return "%s +%.1fx" % [key, v]
	if key == "法力回复":
		return "%s +%d/回合" % [key, int(v)]
	return "%s +%s" % [key, _fmt(v)]
