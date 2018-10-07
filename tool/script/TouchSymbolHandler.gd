extends Button

#variables
##########
var is_pressed = false
var spell_symbols = {}
var raw_touch_path = []
var scaled_touch_path = []

#built in functions
###################
func _ready():
	load_spell_symbols(["example1", "example2", "example3", "example4", "bad" ])
	pass

func _process(delta):
	if is_pressed:
		if raw_touch_path.empty() || raw_touch_path.back() != get_global_mouse_position():
			raw_touch_path.append(get_global_mouse_position())
		pass

#uncomment to see raw_touch_path and scaled_touch_path on screen
func _draw():
	draw_multiline(scaled_touch_path, Color(1.0, 0.0, 0.0, 1.0), 10)
	draw_multiline(raw_touch_path, Color(0.0, 1.0, 0.0, 1.0), 10)
	pass

#my functions
#############
func load_spell_symbols(spell_list):
	for spell_name in spell_list:
		spell_symbols[spell_name] = (Image.new())
		spell_symbols[spell_name].load("res://spell/image/"+spell_name+".png")
		spell_symbols[spell_name].lock()
		pass
	pass

#returns extreme points, used to shift and scale touch path
func find_extreme_points_indexes(vector2d_array):
	var ret = {
		"left_x": 0,
		"right_x": 0,
		"top_y": 0,
		"bottom_y": 0
	}
	for i in range(1, vector2d_array.size()):
		#finding extreme xs
		if vector2d_array[i].x < vector2d_array[ret.left_x].x:
			ret["left_x"] = i
		elif vector2d_array[i].x > vector2d_array[ret.right_x].x:
			ret["right_x"] = i
		
		#finding extreme ys
		if vector2d_array[i].y < vector2d_array[ret.top_y].y:
			ret["top_y"] = i
		elif vector2d_array[i].y > vector2d_array[ret.bottom_y].y:
			ret["bottom_y"] = i
	
	return ret

func scale_touch_path(raw_touch_path, spell_map_width, spell_map_height, margin=0):
	#searching for extreme points
	var extreme_points_indexes = find_extreme_points_indexes(raw_touch_path)
	
	#shifting path to top right position
	var shifted_touch_path = []
	var shift = Vector2(raw_touch_path[extreme_points_indexes.left_x].x, raw_touch_path[extreme_points_indexes.top_y].y)
	for pos in raw_touch_path:
		shifted_touch_path.append(pos - shift)
	
	#scaling path to image size
	var scaled_touch_path = []
	var x_scale = 1
	var y_scale = 1
	if shifted_touch_path[extreme_points_indexes.right_x].x != 0:
		x_scale = (spell_map_width-margin-1)/shifted_touch_path[extreme_points_indexes.right_x].x
	if shifted_touch_path[extreme_points_indexes.right_x].x != 0:
		y_scale = (spell_map_height-margin-1)/shifted_touch_path[extreme_points_indexes.bottom_y].y
	var scale = Vector2(x_scale, y_scale)
	for pos in shifted_touch_path:
		scaled_touch_path.append(pos * scale)
	
	if margin != 0:
		for i in range(0, scaled_touch_path.size()):
			scaled_touch_path[i] += Vector2(margin, margin) 
	
	return scaled_touch_path

func compare_path_to_spells():
	var compability = {}
	if raw_touch_path.size() > 4:
		var spell_w = ProjectSettings.get_setting("Others/Spell Map Width")
		var spell_h = ProjectSettings.get_setting("Others/Spell Map Height")
		scaled_touch_path = scale_touch_path(raw_touch_path, spell_w, spell_h, 30)
		for symbol in spell_symbols:
			compability[symbol] = 0
			for pos in scaled_touch_path:
				compability[symbol] += spell_symbols[symbol].get_pixel(pos.x, pos.y).r
			compability[symbol] /= scaled_touch_path.size()
	return compability

#signal_receivers
#################
func _on_TouchSymbolHandler_button_down():
	raw_touch_path = []
	scaled_touch_path = []
	is_pressed = true

func _on_TouchSymbolHandler_button_up():
	var comp = compare_path_to_spells()
	var best = "bad"
	var best_score = 0
	for i in comp:
		if comp[i] > 0.75 && comp[i] > best_score:
			best = i
			best_score = comp[i]
			pass
	var tex = ImageTexture.new()
	tex.create_from_image(spell_symbols[best])
	get_child(0).set_texture(tex)
	is_pressed = false

