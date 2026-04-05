extends Control

const AUDIO_BUS_NAMES := ["Master", "Music", "SFX"]
const VSYNC_OPTIONS := ["Disabled", "Enabled", "Adaptive", "Mailbox"]

@onready var back_button = $BackButtonMargin/BackButton

# Audio sliders (bus order: Master=0, Music=1, SFX=2)
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var master_slider: HSlider = %MasterSlider

# Video controls
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var vsync_option: OptionButton = %VSyncOption

func _ready() -> void:
	back_button.pressed.connect(hide)
	_setup_audio()
	_setup_video()

# --- Audio ---

func _setup_audio() -> void:
	music_slider.value = AppSettings.get_bus_volume(1)
	sfx_slider.value = AppSettings.get_bus_volume(2)
	master_slider.value = AppSettings.get_bus_volume(0)

	music_slider.value_changed.connect(_on_audio_slider_changed.bind(1, "Music"))
	sfx_slider.value_changed.connect(_on_audio_slider_changed.bind(2, "Sfx"))
	master_slider.value_changed.connect(_on_audio_slider_changed.bind(0, "Master"))

func _on_audio_slider_changed(value: float, bus_index: int, config_key: String) -> void:
	AppSettings.set_bus_volume(bus_index, value)
	PlayerConfig.set_config("AudioSettings", config_key, value)

# --- Video ---

func _setup_video() -> void:
	var window := get_window()
	fullscreen_check.button_pressed = AppSettings.is_fullscreen(window)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	for option in VSYNC_OPTIONS:
		vsync_option.add_item(option)
	vsync_option.selected = AppSettings.get_vsync(window)
	vsync_option.item_selected.connect(_on_vsync_selected)

func _on_fullscreen_toggled(value: bool) -> void:
	var window := get_window()
	AppSettings.set_fullscreen_enabled(value, window)
	PlayerConfig.set_config("VideoSettings", "Fullscreen", value)

func _on_vsync_selected(index: int) -> void:
	AppSettings.set_vsync(index, get_window())
	PlayerConfig.set_config("VideoSettings", "V-Sync", index)
