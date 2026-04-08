class_name LevelAndStateManager
extends LevelManager

## Transient flag: when true, the main menu should auto-open the credits view.
static var show_credits_on_menu : bool = false

func set_current_level_path(value : String) -> void:
	super.set_current_level_path(value)
	GameState.set_current_level_path(value)

func set_checkpoint_level_path(value : String) -> void:
	super.set_checkpoint_level_path(value)
	GameState.set_checkpoint_level_path(value)

func get_checkpoint_level_path() -> String:
	var state_level_path := GameState.get_checkpoint_level_path()
	if not state_level_path.is_empty():
		return state_level_path
	return super.get_checkpoint_level_path()

func _load_ending() -> void:
	# Instead of scrolling credits, go to main menu and auto-open credits there.
	LevelAndStateManager.show_credits_on_menu = true
	_load_main_menu()
