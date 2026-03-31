extends Node3D

var _leafs_collected: int

@onready var _leaf_count: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var leaf_container := $Leafs
	var leafs := leaf_container.get_children()
	if not leafs:
		push_warning("No CollectibleLeafs in Leafs container. Please add them")
		return
	_leaf_count = leafs.size()
	for leaf in leafs:
		leaf.leaf_collected.connect(_on_leaf_collected)

func _on_leaf_collected():
	_leafs_collected += 1
	if _leafs_collected >= _leaf_count:
		$LeafBarrier.break_barrier()
