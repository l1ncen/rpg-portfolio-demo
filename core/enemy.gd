class_name Enemy
extends RefCounted

var config: EnemyConfig
var level: int = 1
var cur_hp: float = 0.0
var dots: Array = []

func _init(cfg: EnemyConfig, lv: int) -> void:
	config = cfg
	level = lv
	cur_hp = max_hp()

func max_hp() -> float:
	return round(config.hp_at(level))

func atk() -> float:
	return config.atk_at(level)

func def_value() -> float:
	return config.def

func exp_reward() -> int:
	return config.exp_at(level)

func gold_reward() -> int:
	return config.gold_at(level)

func take_damage(raw: float) -> int:
	var applied := int(round(raw))
	cur_hp = maxf(cur_hp - applied, 0.0)
	return applied

func is_dead() -> bool:
	return cur_hp <= 0.0

func add_dot(dmg_per_tick: int, total_ticks: int) -> int:
	if total_ticks <= 0:
		return 0
	dots.append({"dmg": dmg_per_tick, "ticks": total_ticks})
	return dmg_per_tick

func tick_dots() -> Array:
	var ticks: Array = []
	for i in range(dots.size() - 1, -1, -1):
		var d: Dictionary = dots[i]
		cur_hp = maxf(cur_hp - d.dmg, 0.0)
		ticks.append(d.dmg)
		d.ticks -= 1
		if d.ticks <= 0:
			dots.remove_at(i)
	return ticks
