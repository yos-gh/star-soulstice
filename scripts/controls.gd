class_name Controls
extends RefCounted
## Input map for keyboard and gamepads (as in the draft):
##   move      : D-pad / left stick, WASD, arrows
##   shot      : button 1 (A), Space, Z, "."   tap fast = concentration up,
##               hold = auto fire
##   side      : button 2 (B), Enter, X, "/"   Spear + homing
## Pad bindings use device -1 so any connected pad works.

const DEADZONE := 0.3

static var using_pad := false
static var pad_device := -1
static var pad_style := "xbox"
static var notice := ""
static var notice_t := 0.0


static func setup() -> void:
	_bind("left", [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_bind("right", [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_bind("up", [KEY_UP, KEY_W], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_bind("down", [KEY_DOWN, KEY_S], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_bind("shot", [KEY_SPACE, KEY_Z, KEY_PERIOD], [JOY_BUTTON_A], [])
	_bind("side", [KEY_ENTER, KEY_KP_ENTER, KEY_X, KEY_SLASH], [JOY_BUTTON_B], [])
	_bind("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START], [])
	_bind("confirm", [KEY_SPACE, KEY_Z, KEY_ENTER, KEY_PERIOD], [JOY_BUTTON_A, JOY_BUTTON_START], [])
	_bind("back", [KEY_Q], [JOY_BUTTON_BACK], [])
	_bind("fullscreen", [KEY_F11], [], [])
	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		_set_style(pads[0])


static func _bind(action: String, keys: Array, buttons: Array, axes: Array) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action, DEADZONE)
	for k: Key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	for b: JoyButton in buttons:
		var ev := InputEventJoypadButton.new()
		ev.device = -1
		ev.button_index = b
		InputMap.action_add_event(action, ev)
	for a: Array in axes:
		var ev := InputEventJoypadMotion.new()
		ev.device = -1
		ev.axis = a[0]
		ev.axis_value = a[1]
		InputMap.action_add_event(action, ev)


## Call from _input: remembers whether the keyboard or a pad was used last.
static func note_event(ev: InputEvent) -> void:
	if ev is InputEventJoypadButton and ev.pressed:
		_use_pad(ev.device)
	elif ev is InputEventJoypadMotion and absf(ev.axis_value) > 0.5:
		_use_pad(ev.device)
	elif ev is InputEventKey and ev.pressed:
		using_pad = false


static func _use_pad(device: int) -> void:
	if not using_pad or device != pad_device:
		_set_style(device)
	using_pad = true
	pad_device = device


static func _set_style(device: int) -> void:
	var n := Input.get_joy_name(device).to_lower()
	if n.contains("playstation") or n.contains("dualsense") or n.contains("dualshock") or n.contains("ps4") or n.contains("ps5") or n.contains("sony"):
		pad_style = "ps"
	elif n.contains("nintendo") or n.contains("switch") or n.contains("joy-con") or n.contains("pro controller"):
		pad_style = "nintendo"
	else:
		pad_style = "xbox"


static func on_joy_changed(device: int, connected: bool) -> void:
	if connected:
		_set_style(device)
		notice = "GAMEPAD CONNECTED : " + Input.get_joy_name(device)
	else:
		notice = "GAMEPAD DISCONNECTED"
		if device == pad_device:
			using_pad = false
	notice_t = 3.0


static func rumble(weak: float, strong: float, duration: float) -> void:
	for id in Input.get_connected_joypads():
		if pad_device < 0 or id == pad_device:
			Input.start_joy_vibration(id, weak, strong, duration)


static func _face(xbox_name: String) -> String:
	match pad_style:
		"ps":
			return {"A": "×", "B": "○"}.get(xbox_name, xbox_name)
		"nintendo":
			return {"A": "B", "B": "A"}.get(xbox_name, xbox_name)
	return xbox_name


## Label shown for an action on the device that was used last.
static func label(what: String) -> String:
	if not using_pad:
		return {
			"move": "ARROWS/WASD", "shot": "Z/SPACE", "side": "X/ENTER",
			"pause": "ESC", "confirm": "Z/SPACE", "back": "Q",
		}.get(what, "")
	var start := "OPTIONS" if pad_style == "ps" else ("+" if pad_style == "nintendo" else "START")
	var back := "SHARE" if pad_style == "ps" else ("-" if pad_style == "nintendo" else "BACK")
	return {
		"move": "D-PAD", "shot": _face("A"), "side": _face("B"),
		"pause": start, "confirm": _face("A"), "back": back,
	}.get(what, "")
