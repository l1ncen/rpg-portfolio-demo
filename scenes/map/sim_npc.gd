class_name SimNpc
extends Area2D
## 战斗模拟师 NPC：靠近显示提示，按交互键开始对话；色块占位可换立绘

@export var npc_color: Color = Color(0.40, 0.68, 0.92)
@export var body_size: int = 34
@export var art_texture: Texture2D:
	set(v):
		art_texture = v
		_apply_art()
@export var npc_name: String = "练功师父"
@export var name_font_size: int = 13
@export var hint_text: String = "按 E 对话"
@export var hint_font_size: int = 12
## 提示气泡相对身体中心的偏移（往下飘）
@export var hint_offset: Vector2 = Vector2(0.0, 30.0)

@onready var body_rect: ColorRect = $Body
@onready var art_rect: TextureRect = $Art
@onready var name_label: Label = $NameLabel
@onready var hint_label: Label = $HintLabel

func _ready() -> void:
	_apply_size()
	_apply_art()
	name_label.text = npc_name
	hint_label.text = hint_text
	hint_label.visible = false

func set_hint_visible(v: bool) -> void:
	hint_label.visible = v

func _apply_size() -> void:
	if body_rect == null:
		return
	var h := body_size * 0.5
	body_rect.offset_left = -h
	body_rect.offset_top = -h
	body_rect.offset_right = h
	body_rect.offset_bottom = h
	body_rect.color = npc_color
	var ah := h * 1.25
	art_rect.offset_left = -ah
	art_rect.offset_top = -ah
	art_rect.offset_right = ah
	art_rect.offset_bottom = ah
	name_label.offset_left = -60.0
	name_label.offset_right = 60.0
	name_label.offset_top = -h - 26.0
	name_label.offset_bottom = -h - 4.0
	name_label.add_theme_font_size_override("font_size", name_font_size)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.offset_left = hint_offset.x - 60.0
	hint_label.offset_right = hint_offset.x + 60.0
	hint_label.offset_top = hint_offset.y
	hint_label.offset_bottom = hint_offset.y + 20.0
	hint_label.add_theme_font_size_override("font_size", hint_font_size)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _apply_art() -> void:
	if body_rect == null or art_rect == null:
		return
	var has_art := art_texture != null
	body_rect.visible = not has_art
	art_rect.visible = has_art
	if has_art:
		art_rect.texture = art_texture
