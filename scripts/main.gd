# Main Scene Controller - Manages the game loop, handles vehicle interaction,
# wires up mobile UI, and detects platform automatically.
extends Node3D

@onready var player_manager = $PlayerManager
@onready var car = $Car
@onready var interact_label = $UI/InteractLabel
@onready var mobile_ui = $MobileUI
@onready var joystick = $MobileUI/Joystick
@onready var btn_jump = $MobileUI/ButtonJump
@onready var btn_run = $MobileUI/ButtonRun
@onready var btn_action = $MobileUI/ButtonAction  # Enter/Exit vehicle
@onready var btn_switch = $MobileUI/ButtonSwitch
@onready var btn_fire = $MobileUI/ButtonFire

# Interaction detection
var nearby_car: Node = null
var active_player: Node = null
var is_mobile: bool = false

func _ready():
    is_mobile = OS.has_feature("android") or OS.has_feature("ios")
    
    if is_mobile:
        mobile_ui.visible = true
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        # Connect joystick output to InputManager-like behavior
        # (We use Input.parse_input_event via mobile buttons - see mobile_button.gd)
        # For joystick movement, we'll poll it directly in _process
    else:
        mobile_ui.visible = false
    
    _refresh_active_player()

func _process(delta):
    _refresh_active_player()
    
    # Feed joystick output into the input system on mobile
    if is_mobile:
        _inject_joystick_as_input()
    
    _check_vehicle_proximity()
    _handle_interaction()

func _inject_joystick_as_input():
    # The virtual joystick gives us a Vector2 output
    # We need to translate that into Input actions that player.gd can read
    var joy = joystick.get_vector()
    
    # Create or update a virtual axis by simulating key presses
    # We use a simpler approach: directly set the input via Input.action_press
    # But Godot doesn't allow that, so we use InputEventAction
    
    # We'll just store it in a global and have player.gd read it
    # For now, simulate keyboard events
    _set_action_state("move_left", joy.x < -0.2)
    _set_action_state("move_right", joy.x > 0.2)
    _set_action_state("move_forward", joy.y < -0.2)
    _set_action_state("move_back", joy.y > 0.2)

func _set_action_state(action: String, pressed: bool):
    # Simulate pressing/releasing an action
    # We track pressed state and emit events
    if pressed and not Input.is_action_pressed(action):
        var ev = InputEventAction.new()
        ev.action = action
        ev.pressed = true
        Input.parse_input_event(ev)
    elif not pressed and Input.is_action_pressed(action):
        var ev = InputEventAction.new()
        ev.action = action
        ev.pressed = false
        Input.parse_input_event(ev)

func _refresh_active_player():
    var new_active = player_manager.get_active_player()
    if new_active != active_player:
        active_player = new_active

func _check_vehicle_proximity():
    if active_player == null:
        return
    
    if active_player.in_vehicle:
        nearby_car = car
        interact_label.text = "Press F to EXIT vehicle"
        interact_label.visible = true
        if is_mobile:
            btn_action.text = "EXIT"
        return
    
    var distance = active_player.global_position.distance_to(car.global_position)
    if distance < 4.0:
        nearby_car = car
        interact_label.text = "Press F to ENTER " + car.car_brand
        interact_label.visible = true
        if is_mobile:
            btn_action.text = "ENTER"
            btn_action.disabled = false
    else:
        nearby_car = null
        interact_label.visible = false
        if is_mobile:
            btn_action.text = ""
            btn_action.disabled = true

func _handle_interaction():
    if nearby_car == null or active_player == null:
        return
    
    if Input.is_action_just_pressed("enter_exit_vehicle"):
        nearby_car.try_enter_exit(active_player)

func _input(event):
    if event.is_action_pressed("pause"):
        if not is_mobile:
            if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
            else:
                get_tree().quit()
        else:
            # On mobile, pause menu instead of quit
            pass
