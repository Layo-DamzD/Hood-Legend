# Mobile Action Button - Touch button for jump/run/enter/switch/fire
# Can be pressed and held (for run) or tapped (for jump)
extends Button

# Action name (matches input action in project.godot)
@export var action_name: String = ""
@export var hold_to_activate: bool = false  # true for run, false for jump

# Internal state
var _is_pressed: bool = false

signal action_pressed(action)
signal action_released(action)

func _ready():
    # Hide on desktop unless debugging
    if OS.has_feature("android") or OS.has_feature("ios") or OS.is_debug_build():
        visible = true
    else:
        visible = false
    
    # Make button semi-transparent
    modulate.a = 0.7
    
    # Connect button signals
    button_down.connect(_on_button_down)
    button_up.connect(_on_button_up)

func _on_button_down():
    _is_pressed = true
    action_pressed.emit(action_name)
    # Simulate the input action so existing player code works
    var ev = InputEventAction.new()
    ev.action = action_name
    ev.pressed = true
    Input.parse_input_event(ev)

func _on_button_up():
    _is_pressed = false
    action_released.emit(action_name)
    # Release the input action
    var ev = InputEventAction.new()
    ev.action = action_name
    ev.pressed = false
    Input.parse_input_event(ev)

func is_held() -> bool:
    return _is_pressed
