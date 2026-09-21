class_name PanelBase
extends Control
## 弹窗基类：半透明遮罩 + 居中面板 + 标题栏关闭按钮；子面板往 Content 里塞内容

@export var title_text: String = "面板":
	set(v):
		title_text = v
		if title_label:
			title_label.text = v
@export var title_font_size: int = 20:
	set(v):
		title_font_size = v
		if title_label:
			title_label.add_theme_font_size_override("font_size", v)
@export var dim_color: Color = Color(0, 0, 0, 0.6)
@export var panel_width: float = 420.0:
	set(v):
		panel_width = v
		if panel:
			panel.custom_minimum_size = Vector2(v, 0)
@export var close_text: String = "关闭"

signal closed

@onready var dim: ColorRect = $Dim
@onready var panel: PanelContainer = $Center/Panel
@onready var title_label: Label = $Center/Panel/Margin/VBox/TitleRow/TitleLabel
@onready var close_btn: Button = $Center/Panel/Margin/VBox/TitleRow/CloseBtn
@onready var content: VBoxContainer = $Center/Panel/Margin/VBox/Content

func _ready() -> void:
	dim.color = dim_color
	title_label.text = title_text
	title_label.add_theme_font_size_override("font_size", title_font_size)
	close_btn.text = close_text
	panel.custom_minimum_size = Vector2(panel_width, 0)
	close_btn.pressed.connect(close)
	dim.gui_input.connect(_on_dim_input)
	visible = false

func open() -> void:
	visible = true

func close() -> void:
	visible = false
	closed.emit()

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()
