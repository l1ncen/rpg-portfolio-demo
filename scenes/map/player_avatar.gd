class_name PlayerAvatar
extends Area2D
## 地图玩家角色：方向键/WASD 移动，色块美术占位（拖 Texture2D 入 art_texture 即替换）

@export var move_speed: float = 200.0
@export var body_color: Color = Color(0.95, 0.78, 0.30)
@export var body_size: int = 32
@export var art_texture: Texture2D:
	set(v):
		art_texture = v
		_apply_art()
@export var display_name: String = "勇者"
@export var name_font_size: int = 13

## 可行走判定回调（由 WorldMap 注入，参数为本地坐标，返回 bool）
var walkable_check: Callable
var input_enabled := true

@onready var body_rect: ColorRect = $Body
@onready var art_rect: TextureRect = $Art
@onready var name_label: Label = $NameLabel

func _ready() -> void:
	_apply_size()
	_apply_art()
	name_label.text = display_name

func _physics_process(delta: float) -> void:
	if not input_enabled:
		return
	var dir := _input_dir()
	if dir == Vector2.ZERO:
		return
	var step := dir * move_speed * delta
	# 分轴移动：撞墙时保留另一轴（贴墙滑动）
	_try_move(Vector2(step.x, 0.0))
	_try_move(Vector2(0.0, step.y))

func _input_dir() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		v.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		v.x += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		v.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		v.y += 1.0
	return v.normalized() if v.length_squared() > 1.0 else v

func _try_move(step: Vector2) -> void:
	if walkable_check.is_valid() and not walkable_check.call(position + step):
		return
	position += step

func _apply_size() -> void:
	if body_rect == null:
		return
	var h := body_size * 0.5
	body_rect.offset_left = -h
	body_rect.offset_top = -h
	body_rect.offset_right = h
	body_rect.offset_bottom = h
	body_rect.color = body_color
	var ah := h * 1.25
	art_rect.offset_left = -ah
	art_rect.offset_top = -ah
	art_rect.offset_right = ah
	art_rect.offset_bottom = ah
	name_label.offset_left = -50.0
	name_label.offset_right = 50.0
	name_label.offset_top = -h - 26.0
	name_label.offset_bottom = -h - 4.0
	name_label.add_theme_font_size_override("font_size", name_font_size)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _apply_art() -> void:
	if body_rect == null or art_rect == null:
		return
	var has_art := art_texture != null
	body_rect.visible = not has_art
	art_rect.visible = has_art
	if has_art:
		art_rect.texture = art_texture
