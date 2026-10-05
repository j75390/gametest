extends SceneTree
func _initialize():
 var pic = Image.new()
 var error = pic.load_svg_from_string(FileAccess.get_file_as_string("res://docs/REGION_ATLAS.svg"))
 assert(error == OK)
 pic.save_png("res://docs/REGION_ATLAS.png")
 quit()
