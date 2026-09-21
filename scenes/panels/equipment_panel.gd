class_name EquipmentPanel
extends PanelBase
## 装备面板：4 部位槽 + 背包列表 + 穿上/脱下/出售；槽位文字与按钮 Inspector 可调

@export var slot_labels: Array[String] = ["武器", "护具", "头饰", "手饰"]
@export var list_min_height: float = 160.0
@export var font_size: int = 14:
	set(v):
		font_size = v
		_apply_style()

signal equip_requested(index: int)
signal unequip_requested(slot: int)
signal sell_requested(index: int)

var slot_rows: Array = []
var bag_list: ItemList
var equip_btn: Button
var unequip_btn: Button
var sell_btn: Button
var bag: Array = []

func _ready() -> void:
	super._ready()
	for i in slot_labels.size():
		var slot := i
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.custom_minimum_size = Vector2(56, 0)
		var item_lbl := Label.new()
		item_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn := Button.new()
		btn.text = "脱下"
		btn.pressed.connect(func(): unequip_requested.emit(slot))
		row.add_child(name_lbl)
		row.add_child(item_lbl)
		row.add_child(btn)
		content.add_child(row)
		slot_rows.append({"name": name_lbl, "item": item_lbl, "btn": btn})

	bag_list = ItemList.new()
	bag_list.custom_minimum_size = Vector2(0, list_min_height)
	bag_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(bag_list)

	var btn_row := HBoxContainer.new()
	equip_btn = Button.new()
	equip_btn.text = "穿上选中"
	unequip_btn = Button.new()
	unequip_btn.text = "全部脱下"
	sell_btn = Button.new()
	sell_btn.text = "出售选中"
	equip_btn.pressed.connect(_on_equip)
	sell_btn.pressed.connect(_on_sell)
	btn_row.add_child(equip_btn)
	btn_row.add_child(unequip_btn)
	btn_row.add_child(sell_btn)
	content.add_child(btn_row)
	_apply_style()

func update_panel(player: Player) -> void:
	bag = player.inventory
	for i in slot_rows.size():
		var row: Dictionary = slot_rows[i]
		if player.equipped.has(i):
			var item: Equipment = player.equipped[i]
			row.item.text = item.display_name
			row.item.add_theme_color_override("font_color", item.quality_color())
			row.btn.disabled = false
		else:
			row.item.text = "（空）"
			row.item.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			row.btn.disabled = true
	bag_list.clear()
	for item in bag:
		bag_list.add_item(item.summary())
		bag_list.set_item_custom_fg_color(bag_list.item_count - 1, item.quality_color())
	equip_btn.disabled = bag_list.get_selected_items().is_empty() if bag.is_empty() else false
	if bag.is_empty():
		equip_btn.disabled = true
		sell_btn.disabled = true

func _on_equip() -> void:
	var selected := bag_list.get_selected_items()
	if not selected.is_empty():
		equip_requested.emit(selected[0])

func _on_sell() -> void:
	var selected := bag_list.get_selected_items()
	if not selected.is_empty():
		sell_requested.emit(selected[0])

func _apply_style() -> void:
	if not is_inside_tree():
		return
	for row: Dictionary in slot_rows:
		row.name.add_theme_font_size_override("font_size", font_size)
		row.item.add_theme_font_size_override("font_size", font_size)
		row.btn.add_theme_font_size_override("font_size", font_size)
	if bag_list:
		bag_list.add_theme_font_size_override("font_size", font_size)
	if equip_btn:
		for btn: Button in [equip_btn, unequip_btn, sell_btn]:
			btn.add_theme_font_size_override("font_size", font_size)
