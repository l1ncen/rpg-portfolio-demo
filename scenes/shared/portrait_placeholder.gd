class_name PortraitPlaceholder
extends Control
## 美术占位组件：无美术资源时显示色块+文字，拖入 Texture2D 后自动切换为立绘

@export var art_texture: Texture2D:
	set(v):
		art_texture = v
		_apply_art()
@export var placeholder_color: Color = Color(0.35, 0.38, 0.45):
	set(v):
		placeholder_color = v
		_apply_art()
@export var placeholder_text: String = "占位":
	set(v):
		placeholder_text = v
		_apply_art()
## 有美术后是否仍显示文字标签
@export var keep_label_with_art: bool = false

@onready var color_rect: ColorRect = $ColorRect
@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label

func _ready() -> void:
	_apply_art()

func set_art(tex: Texture2D) -> void:
	art_texture = tex

func _apply_art() -> void:
	if not is_inside_tree():
		return
	var has_art := art_texture != null
	color_rect.color = placeholder_color
	label.text = placeholder_text
	texture_rect.texture = art_texture
	texture_rect.visible = has_art
	color_rect.visible = not has_art
	label.visible = not has_art or keep_label_with_art
