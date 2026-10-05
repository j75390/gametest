extends SceneTree
func _initialize(): run.call_deferred()
func run():
 root.size = Vector2i(1440,900)
 var v=load("res://scripts/codex.gd").new()
 root.add_child(v)
 v._change_category("지역")
 await create_timer(.4).timeout
 assert(v.detail_box.get_node("StoryScene").size.y > 450)
 v._open_map_image(load("res://assets/map/region_atlas_v1.png"))
 await create_timer(.3).timeout
 var viewer=v.get_node("MapImageViewer")
 assert(viewer.picture.size.x > 1000)
 viewer.change_zoom(2)
 await process_frame
 assert(viewer.picture.custom_minimum_size.x > 2000)
 viewer.change_zoom(1)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/map-viewer.png")
 print("MAP_VIEWER_QA PASS")
 quit()
