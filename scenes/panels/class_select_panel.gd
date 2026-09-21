class_name ClassSelectPanel
extends PanelBase
## 职业选择面板：职业卡从 @export class_configs 数组生成（Inspector 拖 .tres 即可增删职业）

@export var class_configs: Array[ClassConfig] = []
@export var button_height: float = 64.0
@export var button_font_size: int = 16

signal class_picked(cfg: ClassConfig)

func _ready() -> void:
	super._ready()
	for cfg in class_configs:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, button_height)
		btn.add_theme_font_size_override("font_size", button_font_size)
		btn.text = "%s  %s\n%s | 技能：%s" % [cfg.display_name, cfg.role_desc, cfg.damage_type, cfg.skill_name]
		btn.pressed.connect(func(): _pick(cfg))
		content.add_child(btn)

func _pick(cfg: ClassConfig) -> void:
	close()
	class_picked.emit(cfg)
