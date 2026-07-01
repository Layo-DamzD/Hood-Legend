# Main Scene Controller - Manages the game loop, handles vehicle interaction,
# wires up mobile UI, and detects platform automatically.
# Includes debug output to help diagnose issues.
extends Node3D

@onready var player_manager = $PlayerManager
@onready var car = $Car
@onready var interact_label = $UI/InteractLabel
@onready var mobile_ui = $MobileUI
@onready var joystick = $MobileUI/Joystick
@onready var btn_jump = $MobileUI/ButtonJump
@onready var btn_run = $MobileUI/ButtonRun
@onready var btn_action = $MobileUI/ButtonAction
@onready var btn_switch = $MobileUI/ButtonSwitch
@onready var btn_fire = $MobileUI/ButtonFire

# Interaction detection
var nearby_car: Node = null
var active_player: Node = null
var is_mobile: bool = false

func _ready():
    print("=== HOOD LEGENDS STARTING ===")
    print("Platform: ", OS.get_name())
    print("Godot version: ", Engine.get_version_info()["string"])
    
    is_mobile = OS.has_feature("android") or OS.has_feature("ios")
    print("Is mobile: ", is_mobile)
    
    # Verify all nodes loaded
    print("Checking nodes...")
    if player_manager:
        print("  PlayerManager: OK")
    else:
        push_error("  PlayerManager: MISSING!")
    if car:
        print("  Car: OK")
    else:
        push_error("  Car: MISSING!")
    if interact_label:
        print("  InteractLabel: OK")
    else:
        push_error("  InteractLabel: MISSING!")
    if mobile_ui:
        print("  MobileUI: OK")
    else:
        push_error("  MobileUI: MISSING!")
    
    if is_mobile:
        mobile_ui.visible = true
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    else:
        mobile_ui.visible = false
    
    _refresh_active_player()
    
    if active_player:
        print("Active player: ", active_player.character_name)
    else:
        push_error("No active player found!")
    
    print("=== STARTUP COMPLETE ===")
    print("Controls: WASD=move, Shift=run, Space=jump, Tab=switch, F=enter/exit car, Esc=quit")
    print("================================")

func _process(delta):
    _refresh_active_player()
    
    if is_mobile:
        _inject_joystick_as_input()
    
    _check_vehicle_proximity()
    _handle_interaction()

func _inject_joystick_as_input():
    var joy = joystick.get_vector()
    _set_action_state("move_left", joy.x < -0.2)
    _set_action_state("move_right", joy.x > 0.2)
    _set_action_state("move_forward", joy.y < -0.2)
    _set_action_state("move_back", joy.y > 0.2)

func _set_action_state(action: String, pressed: bool):
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
