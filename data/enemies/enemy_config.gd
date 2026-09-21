class_name EnemyConfig
extends Resource

# 怪物数值配置（数值在 level_min 起始，按 per_level 线性成长）
@export var id: String = ""
@export var display_name: String = ""
@export var desc: String = ""
@export var level_min: int = 1
@export var level_max: int = 3
@export var base_hp: float = 40.0
@export var hp_per_level: float = 10.0
@export var base_atk: float = 6.0
@export var atk_per_level: float = 2.0
@export var def: float = 5.0
@export var exp_coeff: float = 1.0
@export var gold: int = 5
@export var is_boss: bool = false

func hp_at(level: int) -> float:
	return base_hp + hp_per_level * (level - 1)

func atk_at(level: int) -> float:
	return base_atk + atk_per_level * (level - 1)

func exp_at(level: int) -> int:
	return int(round(20.0 * level * exp_coeff))

func gold_at(level: int) -> int:
	return gold + int(level * 0.5)
