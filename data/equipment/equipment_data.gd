class_name EquipmentData
extends RefCounted

# 装备数值规则集中配置（需求 §5）

const QUALITY_NAMES := ["普通", "优秀", "精良", "史诗"]
const QUALITY_COLORS := [
	Color.WHITE,
	Color(0.4, 0.9, 0.45),
	Color(0.35, 0.6, 1.0),
	Color(0.85, 0.45, 1.0),
]
const QUALITY_SUB_COUNT := [0, 1, 2, 3]
const QUALITY_SPECIAL_COUNT := [0, 0, 1, 2]
const QUALITY_VALUE_MULT := [1.0, 1.5, 2.0, 2.8]

const SLOT_NAMES := ["武器", "护具", "头饰", "手饰"]
const SLOT_SUFFIX := ["刃", "铠", "冠", "戒"]
const SLOT_PRIMARY := ["攻击", "生命", "法力", "暴击"]
const PRIMARY_BASE := [6.0, 40.0, 20.0, 0.04]

const CRIT_RATE_TO_DMG := 2.5

const SUB_STAT_POOL := ["幸运", "智慧", "体质", "统御", "经验获取"]
const SUB_STAT_BASE := {"幸运": 3.0, "智慧": 3.0, "体质": 5.0, "统御": 2.0, "经验获取": 0.05}

const SPECIAL_POOL := ["经验增长", "技能伤害", "法力回复", "生命偷取"]
const SPECIAL_BASE := {"经验增长": 0.02, "技能伤害": 0.05, "法力回复": 1.0, "生命偷取": 0.01}

const STAT_PREFIX := {"幸运": "幸运", "智慧": "智慧", "体质": "坚韧", "统御": "锋利", "经验获取": "贤者"}

const LEVEL_FACTOR := 0.15
const DEFAULT_DROP_CHANCE := 0.35
