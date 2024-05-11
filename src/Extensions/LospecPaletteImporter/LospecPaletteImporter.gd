extends ConfirmationDialog

const DOWNLOAD_PALETTE_ICON := preload("res://assets/download_palette.png")
const BASE_URL := "https://lospec.com/palette-list/"

const SLUGIFY = preload("res://src/Extensions/LospecPaletteImporter/slugify.gd")
var slugify := SLUGIFY.new()
var found_palette: Dictionary
var palette_panel: Control
var import_from_lospec_button: Button
var row_column_value_slider := ValueSlider.new()
var searching_daily_name := false
var rows: int = 1
var columns: int = 1

@onready var palette_line_edit := $VBoxContainer/SearchBar/PaletteLineEdit as LineEdit
@onready var palette_info := $VBoxContainer/PanelContainer/HBoxContainer/PaletteInfo as Label
@onready var palette_colors_preview := %PaletteColorsPreview as TextureRect
@onready var http_request := $HTTPRequest as HTTPRequest
@onready var row_column_option: OptionButton = %RowColumn


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
	get_ok_button().disabled = true
	%PaletteOption.add_child(row_column_value_slider)
	row_column_value_slider.value_changed.connect(_on_row_column_value_value_changed)
	row_column_value_slider.min_value = 0
	row_column_value_slider.value = 10  # an apropriate value (to make things look nicer)
	row_column_value_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL


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
		"width": columns,
		"height": rows,
		"colors": pixelorama_json_colors
	}
	ExtensionsApi.palette.create_palette_from_data(found_palette["name"], pixelorama_json)


func _on_daily_palette_pressed() -> void:
	searching_daily_name = true
	start_search(BASE_URL.path_join("current-daily-palette"), ".txt")


func _on_random_palette_pressed() -> void:
	start_search(BASE_URL.path_join("random"))


func _on_search_pressed() -> void:
	start_search(palette_line_edit.text)


func _on_http_request_request_completed(
	_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	if response_code != 200:
		palette_info.text = "Palette not found"
		palette_colors_preview.texture = null
		found_palette = {}
		return
	if searching_daily_name:  # if we intended to get a palette name
		searching_daily_name = false
		start_search(body.get_string_from_utf8())
		return
	var json = JSON.parse_string(body.get_string_from_utf8())
	if not typeof(json) == TYPE_DICTIONARY:
		palette_info.text = "Palette not found"
		palette_colors_preview.texture = null
		found_palette = {}
		return
	found_palette = json
	var colors: PackedStringArray = json["colors"]
	var colors_size: int = colors.size()
	palette_info.text = 'Palette: "%s"\nAuthor: %s\nColor count: %s colors' % [json["name"], json["author"], colors_size]
	update_preview()
	# change visibilities of some items
	%InfoSeparator.visible = true
	%PaletteOption.visible = true
	get_ok_button().disabled = false


## Helper functions
func start_search(name_url: String, append_extension := ".json") -> void:
	var url := ""
	if BASE_URL in name_url:
		url = name_url + append_extension
	else:
		url = BASE_URL + slugify.slugify(name_url) + append_extension
	palette_info.text = "Searching..."
	palette_colors_preview.texture = null
	http_request.request(url)
	# change visibilities of some items
	%InfoSeparator.visible = false
	%PaletteOption.visible = false
	get_ok_button().disabled = true


func update_preview():
	if found_palette.is_empty():
		return
	var colors: PackedStringArray = found_palette["colors"]
	var colors_size = colors.size()
	var image_preview: Image
	row_column_value_slider.max_value = colors.size()
	var i = 0
	match row_column_option.selected:
		0:  # Rows
			rows = row_column_value_slider.value
			columns = ceili(float(colors_size) / rows)
			image_preview = Image.create(columns, rows, false, Image.FORMAT_RGBA8)
			for x in image_preview.get_width():
				for y in image_preview.get_height():
					if i >= colors.size():
						break
					image_preview.set_pixel(x, y, Color(colors[i]))
					i += 1
		1:  # Columns
			columns = row_column_value_slider.value
			rows = ceili(float(colors_size) / columns)
			image_preview = Image.create(columns, rows, false, Image.FORMAT_RGBA8)
			for y in image_preview.get_height():
				for x in image_preview.get_width():
					if i >= colors.size():
						break
					image_preview.set_pixel(x, y, Color(colors[i]))
					i += 1

	palette_colors_preview.texture = ImageTexture.create_from_image(image_preview)


func _on_row_column_item_selected(_index: int) -> void:
	update_preview()


func _on_row_column_value_value_changed(_value: float) -> void:
	update_preview()
