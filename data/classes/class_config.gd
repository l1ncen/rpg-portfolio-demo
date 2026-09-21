class_name ClassConfig
extends Resource

# 职业数值配置（基础值 + 成长系数 + 技能），全部 Inspector 可调
@export var id: String = ""
@export var display_name: String = ""
@export var role_desc: String = ""
@export var base_hp: float = 100.0
@export var base_mp: float = 50.0
@export var base_atk: float = 10.0
@export var base_def: float = 5.0
@export var base_crit_rate: float = 0.1
@export var base_crit_dmg: float = 1.2
@export var con_growth: float = 10.0
@export var int_growth: float = 4.0
@export var str_growth: float = 3.0
@export var damage_type: String = "物理"

@export_group("技能")
@export var skill_name: String = ""
@export var skill_desc: String = ""
@export var skill_multiplier: float = 2.0
@export var skill_mp: int = 15
@export var skill_type: String = "即时"
@export var skill_dot_turns: int = 3
@export var skill_effect: String = ""
@export var skill_effect_value: float = 0.0
@export var skill_effect_turns: int = 0
