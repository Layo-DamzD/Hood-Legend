# Main Scene Controller - Manages game loop, vehicle interaction, mobile UI
# Now supports multiple cars (interacts with nearest car)
extends Node3D

@onready var player_manager = $PlayerManager
@onready var interact_label = $UI/InteractLabel
@onready var mobile_ui = $MobileUI
@onready var joystick = $MobileUI/Joystick
@onready var btn_jump = $MobileUI/ButtonJump
@onready var btn_run = $MobileUI/ButtonRun
@onready var btn_action = $MobileUI/ButtonAction
@onready var btn_switch = $MobileUI/ButtonSwitch
@onready var btn_fire = $MobileUI/ButtonFire
@onready var weapon_hud = $UI/WeaponHUD
@onready var character_hud = $UI/CharacterHUD

var nearby_car: Node = null
var active_player: Node = null
var is_mobile: bool = false

# All cars in the scene (collected at _ready)
var all_cars: Array = []

func _ready():
    print("=== HOOD LEGENDS STARTING ===")
    print("Platform: ", OS.get_name())
    print("Godot version: ", Engine.get_version_info()["string"])
    
    is_mobile = OS.has_feature("android") or OS.has_feature("ios")
    print("Is mobile: ", is_mobile)
    
    # Find all cars in the scene (they're children of World)
    all_cars = []
    _collect_cars($World)
    print("Found ", all_cars.size(), " cars in the world")
    
    # Verify nodes
    if player_manager:
        print("PlayerManager: OK")
    else:
        push_error("PlayerManager: MISSING!")
    if interact_label:
        print("InteractLabel: OK")
    
    if is_mobile:
        mobile_ui.visible = true
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    else:
        mobile_ui.visible = false
    
    _refresh_active_player()
    
    if active_player:
        print("Active player: ", active_player.character_name)
    
    print("=== STARTUP COMPLETE ===")
    print("Controls:")
    print("  WASD/Arrows = move")
    print("  Shift = run")
    print("  Space = jump")
    print("  Tab = switch character (Marcus <-> Maya)")
    print("  F = enter/exit nearest car")
    print("  H = toggle headlights (when in car)")
    print("  LMB = fire weapon (when gun system added)")
    print("  Esc = quit")
    print("================================")

# Recursively find all VehicleBody3D nodes (cars) in the world
func _collect_cars(node: Node):
    for child in node.get_children():
        if child is VehicleBody3D:
            all_cars.append(child)
        _collect_cars(child)

func _process(_delta):
    _refresh_active_player()
    
    if is_mobile:
        _inject_joystick_as_input()
    
    _check_vehicle_proximity()
    _handle_interaction()
    _update_hud()

func _update_hud():
    if active_player and character_hud:
        character_hud.text = "Playing: " + active_player.character_name
    
    if active_player and active_player.has_node("Weapon") and weapon_hud:
        var weapon = active_player.get_node("Weapon")
        if weapon.has_method("get_ammo_string"):
            weapon_hud.text = weapon.get_ammo_string()

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
    
    # If player is in a vehicle, allow exit
    if active_player.in_vehicle:
        nearby_car = _find_driven_car()
        if nearby_car:
            interact_label.text = "Press F to EXIT " + nearby_car.car_brand
            interact_label.visible = true
            if is_mobile:
                btn_action.text = "EXIT"
        return
    
    # Otherwise find the nearest car within range
    nearby_car = null
    var nearest_distance = 5.0  # Max distance to enter car
    
    for car in all_cars:
        if car == null or not is_instance_valid(car):
            continue
        if car.is_being_driven:
            continue  # Skip cars other players might be in
        var distance = active_player.global_position.distance_to(car.global_position)
        if distance < nearest_distance:
            nearest_distance = distance
            nearby_car = car
    
    if nearby_car:
        interact_label.text = "Press F to ENTER " + nearby_car.car_brand
        interact_label.visible = true
        if is_mobile:
            btn_action.text = "ENTER"
            btn_action.disabled = false
    else:
        interact_label.visible = false
        if is_mobile:
            btn_action.text = ""
            btn_action.disabled = true

# Find which car the active player is currently driving
func _find_driven_car() -> Node:
    for car in all_cars:
        if car and is_instance_valid(car) and car.is_being_driven and car.driver == active_player:
            return car
    return null

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
