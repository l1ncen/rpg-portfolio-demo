class_name WorldMap
extends Control
## RPG 2D 地图：Inspector 用字符行直接编辑地形布局，色块美术占位
## 字符含义：T树 #石头 ~水（障碍）；. 草 r 路（可走）；S 出生点 N 模拟师 B 战斗门

signal battle_requested
signal sim_requested

@export var map_rows: Array[String] = [
	"TTTTTTTTTT",
	"T..r....NT",
	"T..r.TTT.T",
	"T..r.~...T",
	"T..r.~...T",
	"T..rrS...T",
	"T....r...T",
	"TT...r...T",
	"T.B..r..#T",
	"T....r...T",
	"TTTTTTTTTT",
]
@export var tile_size: int = 44
@export_group("布局")
@export var map_top_margin: float = 64.0
@export var hint_bottom_margin: float = 46.0

@export_group("地块颜色（美术占位，可换 tileset）")
@export var grass_color: Color = Color(0.30, 0.52, 0.28)
@export var road_color: Color = Color(0.74, 0.64, 0.44)
@export var tree_color: Color = Color(0.12, 0.30, 0.16)
@export var water_color: Color = Color(0.28, 0.42, 0.68)
@export var rock_color: Color = Color(0.48, 0.48, 0.50)
@export var gate_color: Color = Color(0.85, 0.28, 0.28)
@export var gate_text: String = "战斗"

@export_group("角色外观（美术透传）")
@export var player_art: Texture2D
@export var npc_art: Texture2D
@export var player_name: String = "勇者"

@export_group("交互")
@export var interact_range: float = 64.0
@export var hint_text: String = "方向键/WASD 移动 · 靠近师父按 E 对话 · 踩红门进入战斗"
@export var hint_font_size: int = 13
@export var hint_color: Color = Color(0.92, 0.92, 0.86)

var _blocked := {}          # Vector2i -> true（障碍格）
var _gate_cells: Array[Vector2i] = []
var _spawn_cell := Vector2i(5, 5)
var _npc_cell := Vector2i(8, 1)
var _active := true

@onready var map_area: Control = $MapArea
@onready var tiles_root: Control = $MapArea/Tiles
@onready var player_avatar: PlayerAvatar = $MapArea/Player
@onready var npc: SimNpc = $MapArea/Npc
@onready var hint_label: Label = $HintLabel

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	hint_label.mouse_filter = MOUSE_FILTER_IGNORE
	_build_map()
	hint_label.text = hint_text
	hint_label.add_theme_font_size_override("font_size", hint_font_size)
	hint_label.add_theme_color_override("font_color", hint_color)

## 设置玩家显示（职业名与美术透传），职业选择后由 main 调用
func setup(display_name: String, p_art: Texture2D, n_art: Texture2D) -> void:
	player_avatar.display_name = display_name
	player_avatar.name_label.text = display_name
	if p_art:
		player_avatar.art_texture = p_art
	if n_art:
		npc.art_texture = n_art
	_reset_player()

func set_active(v: bool) -> void:
	_active = v
	player_avatar.input_enabled = v

func _build_map() -> void:
	for c in tiles_root.get_children():
		c.queue_free()
	_blocked.clear()
	_gate_cells.clear()
	var cols := 0
	for row in map_rows.size():
		cols = maxi(cols, map_rows[row].length())
		for col in map_rows[row].length():
			var ch := map_rows[row][col]
			var cell := Vector2i(col, row)
			match ch:
				"T", "#", "~":
					_blocked[cell] = true
				"B":
					_gate_cells.append(cell)
				"S":
					_spawn_cell = cell
				"N":
					_npc_cell = cell
			_spawn_tile(ch, cell)
	# 地图居中定位
	var map_size := Vector2(cols * tile_size, map_rows.size() * tile_size)
	var view := size
	map_area.position = Vector2((view.x - map_size.x) * 0.5, map_top_margin)
	map_area.size = map_size
	# NPC 与玩家定位（格中心）
	npc.position = _cell_center(_npc_cell)
	_reset_player()
	player_avatar.walkable_check = _is_walkable

func _reset_player() -> void:
	player_avatar.position = _cell_center(_spawn_cell)

func _spawn_tile(ch: String, cell: Vector2i) -> void:
	var rect := ColorRect.new()
	rect.mouse_filter = MOUSE_FILTER_IGNORE
	rect.position = Vector2(cell) * float(tile_size)
	rect.size = Vector2(float(tile_size), float(tile_size))
	match ch:
		"r":
			rect.color = road_color
		"T":
			rect.color = tree_color
		"~":
			rect.color = water_color
		"#":
			rect.color = rock_color
		"B":
			rect.color = gate_color
			_add_tile_text(rect, gate_text)
		_:
			rect.color = grass_color
	tiles_root.add_child(rect)

func _add_tile_text(parent: ColorRect, label_text: String) -> void:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	parent.add_child(lbl)

func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2.ONE * 0.5) * float(tile_size)

func _cell_of(local_pos: Vector2) -> Vector2i:
	return Vector2i((local_pos / float(tile_size)).floor())

## 玩家小半径采样四点，任一点入障碍格或越界即视为不可走
func _is_walkable(local_pos: Vector2) -> bool:
	var half := player_avatar.body_size * 0.5 - 2.0
	var probes := [
		local_pos,
		local_pos + Vector2(half, 0.0),
		local_pos + Vector2(-half, 0.0),
		local_pos + Vector2(0.0, half),
		local_pos + Vector2(0.0, -half),
	]
	for p in probes:
		var cell := _cell_of(p)
		if not _in_map(cell) or _blocked.has(cell):
			return false
	return true

func _in_map(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.y < map_rows.size() and cell.x < map_rows[cell.y].length()

func _process(_delta: float) -> void:
	if not _active or not visible:
		return
	# 靠近 NPC：显示提示
	var near_npc := player_avatar.position.distance_to(npc.position) <= interact_range
	npc.set_hint_visible(near_npc)
	# 踩战斗门：触发战斗
	var pcell := _cell_of(player_avatar.position)
	if pcell in _gate_cells:
		set_active(false)
		_reset_player()
		battle_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not _active or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if player_avatar.position.distance_to(npc.position) <= interact_range:
			set_active(false)
			sim_requested.emit()
