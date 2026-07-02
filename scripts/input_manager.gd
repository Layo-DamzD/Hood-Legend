# Input Manager - Bridges keyboard/mouse and touch input
# Detects platform and provides unified input queries
extends Node

# Singleton-ish: store as autoload or attach to Main scene
# For simplicity, we attach to Main scene and query via get_node("/root/Main/InputManager")

var is_mobile: bool = false
var joystick_output: Vector2 = Vector2.ZERO

# Touch look state (right side of screen for camera)
var _look_touch_index: int = -1
var _look_last_pos: Vector2 = Vector2.ZERO
const LOOK_SENSITIVITY: float = 0.005

func _ready():
    is_mobile = OS.has_feature("android") or OS.has_feature("ios")
    print("Platform: ", OS.get_name(), " | Mobile: ", is_mobile)

func set_joystick_output(vec: Vector2):
    joystick_output = vec

# Returns movement vector (-1 to 1 on each axis)
# On desktop: reads WASD
# On mobile: reads from virtual joystick
func get_movement_vector() -> Vector2:
    if is_mobile:
        return joystick_output
    else:
        return Input.get_vector("move_left", "move_right", "move_forward", "move_back")

# Handle touch look (right half of screen rotates camera)
func _input(event):
    if not is_mobile:
        return
    
    if event is InputEventScreenTouch:
        if event.pressed and _look_touch_index == -1:
            # Right half of screen = look
            if event.position.x > get_viewport().size.x / 2:
                _look_touch_index = event.index
                _look_last_pos = event.position
        elif not event.pressed and event.index == _look_touch_index:
            _look_touch_index = -1
    
    elif event is InputEventScreenDrag and event.index == _look_touch_index:
        var delta = event.position - _look_last_pos
        _look_last_pos = event.position
        # Inject as mouse motion so the player.gd camera code works
        var ev = InputEventMouseMotion.new()
        ev.relative = delta
        ev.position = event.position
        Input.parse_input_event(ev)

func is_action_pressed(action: String) -> bool:
    return Input.is_action_pressed(action)

func is_action_just_pressed(action: String) -> bool:
    return Input.is_action_just_pressed(action)
