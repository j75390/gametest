extends SceneTree
const Status = preload("res://scripts/unit_status.gd")
const Data = preload("res://scripts/game_data.gd")
func _initialize():
	var a=Status.new()
	var b=Status.new()
	for unit in [a,b]:
		unit.apply([{"id":"bleed","amount":3},{"id":"venom","amount":2,"rate":0.08},{"id":"empower","amount":4}])
		assert(unit.tick(100)==11)
		assert(unit.amount("bleed")==2 and unit.amount("venom")==1)
		assert(unit.consume_attack()==4 and unit.consume_attack()==0)
	assert(Data.cards().common[0].cost==1)
	assert(Data.read("monsters").size()==3)
	print("CONTENT_STATUS_QA units=2 shared_catalog=true failures=0")
	quit()
