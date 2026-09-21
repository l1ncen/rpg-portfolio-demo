class_name FloatingText
extends Label
## 伤害飘字：出现 → 上浮渐隐 → 自动销毁；暴击放大变色，全部参数 Inspector 可调

@export var rise_distance: float = 60.0
@export var duration: float = 0.8
@export var normal_color: Color = Color.WHITE
@export var crit_color: Color = Color(1.0, 0.4, 0.15)
@export var heal_color: Color = Color(0.4, 0.95, 0.5)
@export var normal_scale: float = 1.0
@export var crit_scale: float = 1.6
@export var font_size: int = 22

var is_crit := false
var is_heal := false

func _ready() -> void:
	add_theme_font_size_override("font_size", font_size)
	if is_heal:
		add_theme_color_override("font_color", heal_color)
		scale = Vector2(normal_scale, normal_scale)
	elif is_crit:
		add_theme_color_override("font_color", crit_color)
		text += "!"
		scale = Vector2(crit_scale, crit_scale)
	else:
		add_theme_color_override("font_color", normal_color)
		scale = Vector2(normal_scale, normal_scale)
	z_index = 100

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - rise_distance, duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration).set_delay(duration * 0.4)
	tween.chain().tween_callback(queue_free)

static func spawn(parent: Node, pos: Vector2, label_text: String, crit: bool = false, heal: bool = false) -> FloatingText:
	var ft := FloatingText.new()
	ft.text = label_text
	ft.position = pos
	ft.is_crit = crit
	ft.is_heal = heal
	parent.add_child(ft)
	return ft
