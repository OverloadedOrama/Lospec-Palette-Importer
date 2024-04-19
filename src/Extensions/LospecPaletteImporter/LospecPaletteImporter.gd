extends ConfirmationDialog

const DOWNLOAD_PALETTE_ICON := preload("res://assets/download_palette.png")
const BASE_URL := "https://lospec.com/palette-list/"
const SLUGIFY = preload("res://src/Extensions/LospecPaletteImporter/slugify.gd")
var slugify := SLUGIFY.new()
var found_palette: Dictionary
var palette_panel: Control
var import_from_lospec_button: Button

@onready var palette_line_edit := $VBoxContainer/HBoxContainer/PaletteLineEdit as LineEdit
@onready var palette_info := $VBoxContainer/PaletteInfo as Label
@onready var palette_colors_preview := $VBoxContainer/PaletteColorsPreview as TextureRect
@onready var http_request := $HTTPRequest as HTTPRequest


func _enter_tree() -> void:
	palette_panel = get_tree().current_scene.find_child("Palettes")
	import_from_lospec_button = Button.new()
	import_from_lospec_button.name = "ImportFromLospec"
	import_from_lospec_button.custom_minimum_size = Vector2(22, 22)
	import_from_lospec_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	import_from_lospec_button.tooltip_text = "Download and import a palette from Lospec"
	import_from_lospec_button.pressed.connect(func(): popup_centered())
	var texture_rect := TextureRect.new()
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	texture_rect.anchor_left = 0
	texture_rect.anchor_top = 0
	texture_rect.anchor_right = 1
	texture_rect.anchor_bottom = 1
	texture_rect.texture = DOWNLOAD_PALETTE_ICON
	import_from_lospec_button.add_child(texture_rect)
	palette_panel.find_child("PaletteButtons").add_child(import_from_lospec_button)


func _exit_tree() -> void:
	import_from_lospec_button.queue_free()


func _on_visibility_changed() -> void:
	ExtensionsApi.dialog.dialog_open(visible)


func _on_confirmed() -> void:
	if found_palette.is_empty():
		return
	var colors: PackedStringArray = found_palette["colors"]
	var pixelorama_json_colors := []
	for i in colors.size():
		var color_hex := colors[i]
		var color := Color(color_hex)
		pixelorama_json_colors.append({"color": color, "index": i})
	var pixelorama_json := {
		"comment": found_palette["author"],
		"width": colors.size(),
		"height": 1,
		"colors": pixelorama_json_colors
	}
	ExtensionsApi.palette.create_palette_from_data(found_palette["name"], pixelorama_json)


func _on_search_pressed() -> void:
	var palette_name := palette_line_edit.text
	var url := ""
	if BASE_URL in palette_name:
		url = palette_name + ".json"
	else:
		url = BASE_URL + slugify.slugify(palette_name) + ".json"
	http_request.request(url)


func _on_http_request_request_completed(
	_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	if response_code != 200:
		palette_info.text = "Palette not found"
		palette_colors_preview.texture = null
		found_palette = {}
		return
	var json = JSON.parse_string(body.get_string_from_utf8())
	if not typeof(json) == TYPE_DICTIONARY:
		palette_info.text = "Palette not found"
		palette_colors_preview.texture = null
		found_palette = {}
		return
	found_palette = json
	var colors: PackedStringArray = json["colors"]
	var colors_size := colors.size()
	palette_info.text = '"%s" by %s, %s colors' % [json["name"], json["author"], colors_size]
	var image_preview := Image.create(colors_size, 1, false, Image.FORMAT_RGBA8)
	for i in colors_size:
		var color_str := colors[i]
		var color := Color(color_str)
		image_preview.set_pixel(i, 0, color)
	palette_colors_preview.texture = ImageTexture.create_from_image(image_preview)
