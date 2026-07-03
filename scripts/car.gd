# Car Controller - Drivable vehicle with enter/exit system
# Now uses procedural car model (body, cabin, wheels, lights) instead of box
extends VehicleBody3D

# Driving parameters
const MAX_STEER = 0.7
const STEER_SPEED = 3.0
const MAX_ENGINE_FORCE = 300.0
const MAX_BRAKE_FORCE = 150.0

var is_being_driven: bool = false
var driver: Node = null

@onready var front_left = $FrontLeftWheel
@onready var front_right = $FrontRightWheel
@onready var rear_left = $RearLeftWheel
@onready var rear_right = $RearRightWheel
@onready var model_holder = $ModelHolder

# Headlights (created on _ready)
var _left_headlight: SpotLight3D = null
var _right_headlight: SpotLight3D = null
var _headlights_on: bool = false

@export var car_brand: String = "Comet"
@export var top_speed: float = 80.0

func _ready():
    set_can_sleep(false)
    
    # Tune wheels (suspension_max_travel doesn't exist in Godot 4 - removed)
    for wheel in [front_left, front_right, rear_left, rear_right]:
        if wheel:
            wheel.suspension_stiffness = 40.0
            wheel.suspension_rest_length = 0.3
            wheel.damping_compression = 0.85
            wheel.damping_relaxation = 0.9
    
    # Build the procedural car model
    var CarBuilder = load("res://scripts/car_builder.gd")
    CarBuilder.build(model_holder, car_brand)
    
    # Add headlights (invisible lights, can toggle on/off later)
    _setup_headlights()

func _setup_headlights():
    _left_headlight = SpotLight3D.new()
    _left_headlight.name = "LeftHeadlight"
    _left_headlight.light_color = Color(1.0, 0.95, 0.8)
    _left_headlight.light_energy = 0.0  # Off by default
    _left_headlight.spot_range = 30.0
    _left_headlight.spot_angle = 35.0
    _left_headlight.position = Vector3(-0.65, 0.7, 2.1)
    _left_headlight.rotation_degrees = Vector3(-15, 0, 0)
    add_child(_left_headlight)
    
    _right_headlight = SpotLight3D.new()
    _right_headlight.name = "RightHeadlight"
    _right_headlight.light_color = Color(1.0, 0.95, 0.8)
    _right_headlight.light_energy = 0.0
    _right_headlight.spot_range = 30.0
    _right_headlight.spot_angle = 35.0
    _right_headlight.position = Vector3(0.65, 0.7, 2.1)
    _right_headlight.rotation_degrees = Vector3(-15, 0, 0)
    add_child(_right_headlight)

func toggle_headlights():
    _headlights_on = not _headlights_on
    var energy = 2.5 if _headlights_on else 0.0
    if _left_headlight:
        _left_headlight.light_energy = energy
    if _right_headlight:
        _right_headlight.light_energy = energy
    print("Headlights: ", "ON" if _headlights_on else "OFF")

func _physics_process(_delta):
    if not is_being_driven or driver == null:
        brake = MAX_BRAKE_FORCE * 0.3
        engine_force = 0
        return
    
    brake = 0
    
    # Steering
    var steer_input = Input.get_axis("move_right", "move_left")
    var target_steer = steer_input * MAX_STEER
    steering = lerp(steering, target_steer, STEER_SPEED * _delta)
    
    # Throttle / brake
    var forward_input = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
    
    if forward_input > 0:
        engine_force = forward_input * MAX_ENGINE_FORCE
        brake = 0
    elif forward_input < 0:
        if linear_velocity.length() > 2.0:
            engine_force = 0
            brake = abs(forward_input) * MAX_BRAKE_FORCE
        else:
            engine_force = forward_input * MAX_ENGINE_FORCE * 0.6
            brake = 0
    else:
        engine_force = 0
        brake = 0
    
    # Headlight toggle with H key (only when driving)
    if Input.is_key_pressed(KEY_H) and not _h_was_pressed:
        toggle_headlights()
        _h_was_pressed = true
    elif not Input.is_key_pressed(KEY_H):
        _h_was_pressed = false

var _h_was_pressed: bool = false

func try_enter_exit(player):
    if is_being_driven:
        var exit_pos = global_position + global_transform.basis.x * 2.5
        exit_pos.y = global_position.y + 0.5
        driver.exit_vehicle(self, exit_pos)
        driver = null
        is_being_driven = false
        # Turn off headlights when exiting
        if _headlights_on:
            toggle_headlights()
        print("Exited ", car_brand)
    else:
        driver = player
        driver.enter_vehicle(self)
        is_being_driven = true
        print("Entered ", car_brand, " - W/S=drive, A/D=steer, F=exit, H=headlights")
