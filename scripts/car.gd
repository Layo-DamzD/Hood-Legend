# Car Controller - Drivable vehicle with enter/exit system
# Uses VehicleBody3D for realistic physics
extends VehicleBody3D

# Driving parameters - tuned for actual drivability
const MAX_STEER = 0.7
const STEER_SPEED = 3.0
const MAX_ENGINE_FORCE = 300.0  # Boosted from 200 so car actually moves
const MAX_BRAKE_FORCE = 150.0

# Currently driving this car?
var is_being_driven: bool = false
var driver: Node = null

# Reference to wheels
@onready var front_left = $FrontLeftWheel
@onready var front_right = $FrontRightWheel
@onready var rear_left = $RearLeftWheel
@onready var rear_right = $RearRightWheel

# Car brand (fictional)
@export var car_brand: String = "Comet"
@export var top_speed: float = 80.0

func _ready():
    set_can_sleep(false)
    # Make sure wheels are configured properly
    for wheel in [front_left, front_right, rear_left, rear_right]:
        if wheel:
            wheel.suspension_stiffness = 40.0
            wheel.suspension_max_travel = 0.3
            wheel.suspension_rest_length = 0.3

func _physics_process(_delta):
    if not is_being_driven or driver == null:
        # When no driver, apply handbrake so car doesn't roll
        brake = MAX_BRAKE_FORCE * 0.3
        engine_force = 0
        return
    
    brake = 0
    
    # Steering (smooth interpolation)
    # move_left = A or LEFT, move_right = D or RIGHT
    # get_axis(negative, positive) - so left = negative, right = positive
    # Steering needs: left = positive steer, right = negative steer (or vice versa)
    var steer_input = Input.get_axis("move_right", "move_left")
    var target_steer = steer_input * MAX_STEER
    steering = lerp(steering, target_steer, STEER_SPEED * _delta)
    
    # Throttle / brake - FIXED
    # move_forward = W or UP, move_back = S or DOWN
    # get_axis(negative, positive): pressing move_back returns +1, move_forward returns -1
    # We want: move_forward = accelerate forward (+engine_force)
    #          move_back = brake then reverse
    var forward_input = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
    
    if forward_input > 0:
        # Accelerate forward
        engine_force = forward_input * MAX_ENGINE_FORCE
        brake = 0
    elif forward_input < 0:
        # Brake or reverse
        if linear_velocity.length() > 2.0:
            # Moving forward - brake first
            engine_force = 0
            brake = abs(forward_input) * MAX_BRAKE_FORCE
        else:
            # Stopped or moving backward - reverse
            engine_force = forward_input * MAX_ENGINE_FORCE * 0.6
            brake = 0
    else:
        engine_force = 0
        brake = 0

# Called when player presses F near the car
func try_enter_exit(player):
    if is_being_driven:
        # Exit the car
        var exit_pos = global_position + global_transform.basis.x * 2.5  # Exit to the left
        exit_pos.y = global_position.y + 0.5
        # Make sure exit position isn't inside a building - simple raycast down would be better
        # For now just use this position
        driver.exit_vehicle(self, exit_pos)
        driver = null
        is_being_driven = false
        print("Exited ", car_brand)
    else:
        # Enter the car
        driver = player
        driver.enter_vehicle(self)
        is_being_driven = true
        print("Entered ", car_brand, " - drive with W/S or Up/Down, A/D or Left/Right to steer")
