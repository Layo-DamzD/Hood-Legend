# Car Controller - Drivable vehicle with enter/exit system
# Uses VehicleBody3D for realistic physics
extends VehicleBody3D

# Driving parameters
const MAX_STEER = 0.7
const STEER_SPEED = 3.0
const MAX_ENGINE_FORCE = 200.0
const MAX_BRAKE_FORCE = 100.0

# Currently driving this car?
var is_being_driven: bool = false
var driver: Node = null

# Reference to wheels for steering
@onready var front_left = $FrontLeftWheel
@onready var front_right = $FrontRightWheel
@onready var rear_left = $RearLeftWheel
@onready var rear_right = $RearRightWheel

# Car brand (fictional) - easy to rename later
@export var car_brand: String = "Comet"  # Porsche-style
@export var top_speed: float = 80.0

func _ready():
    # Make sure car doesn't fall asleep
    set_can_sleep(false)

func _physics_process(delta):
    if not is_being_driven or driver == null:
        # When no driver, apply handbrake so car doesn't roll
        brake = MAX_BRAKE_FORCE * 0.3
        return
    
    brake = 0
    
    # Steering (smooth interpolation)
    var steer_input = Input.get_axis("move_right", "move_left")
    var target_steer = steer_input * MAX_STEER
    steering = lerp(steering, target_steer, STEER_SPEED * delta)
    
    # Throttle / brake
    var throttle = Input.get_axis("move_back", "move_forward")
    if throttle > 0:
        engine_force = throttle * MAX_ENGINE_FORCE
        brake = 0
    elif throttle < 0:
        # Reverse or brake
        if linear_velocity.length() > 1.0:
            engine_force = 0
            brake = abs(throttle) * MAX_BRAKE_FORCE
        else:
            engine_force = throttle * MAX_ENGINE_FORCE * 0.5  # Reverse at half power
            brake = 0
    else:
        engine_force = 0
        brake = 0

# Called when player presses F near the car
func try_enter_exit(player):
    if is_being_driven:
        # Exit the car
        var exit_pos = global_position + global_transform.basis.x * 2.0  # Exit to the left
        # Make sure exit position is on the ground
        exit_pos.y = global_position.y
        driver.exit_vehicle(self, exit_pos)
        driver = null
        is_being_driven = false
        print("Exited ", car_brand)
    else:
        # Enter the car
        driver = player
        driver.enter_vehicle(self)
        is_being_driven = true
        print("Entered ", car_brand)
