extends RefCounted
## Settings are kept separate from quest saves.

const PATH: String = "user://veil_settings.cfg"
const MIN_BRIGHTNESS: float = 0.85
const MAX_BRIGHTNESS: float = 1.8
const DEFAULT_BRIGHTNESS: float = 1.25
var brightness: float = DEFAULT_BRIGHTNESS
var sound_enabled: bool = true
var error: Error = OK

func load_settings(path: String = PATH) -> void:
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		return
	var value: Variant = file.get_value("display", "brightness", DEFAULT_BRIGHTNESS)
	if (value is int or value is float) and is_finite(float(value)):
		brightness = clampf(float(value), MIN_BRIGHTNESS, MAX_BRIGHTNESS)
	var sound_value: Variant = file.get_value("audio", "enabled", true)
	if sound_value is bool:
		sound_enabled = sound_value

func save_settings(path: String = PATH) -> bool:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("display", "brightness", brightness)
	file.set_value("audio", "enabled", sound_enabled)
	error = file.save(path)
	return error == OK
