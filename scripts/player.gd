# Player Controller - Third-person character movement
# Now uses procedural humanoid model (head, body, arms, legs) instead of capsule
extends CharacterBody3D

# Movement speeds
const WALK_SPEED = 5.0
const RUN_SPEED = 9.0
const JUMP_VELOCITY = 6.0
const ROTATION_SPEED = 10.0

# Camera mouse sensitivity (desktop)
const SENSITIVITY = 0.003

# Gravity from project settings
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Whether this character is currently being controlled
var is_active: bool = false

# Whether this character is inside a vehicle
var in_vehicle: bool = false

# Character metadata (for switching system)
@export var character_name: String = "Player"
@export var character_color: Color = Color(0.8, 0.6, 0.4)
@export var character_id: String = "marcus"  # "marcus" or "maya"

# Node references
@onready var camera_rig = $CameraRig
@onready var camera = $CameraRig/Camera3D
@onready var mesh_holder = $MeshHolder  # Container for the character model

# Animation state
var _walk_cycle: float = 0.0
var _is_moving: bool = false
var _is_running: bool = false
var _character_model: Node3D = null

func _ready():
    camera.current = false
    
    # Build the procedural humanoid character
    var CharacterBuilder = load("res://scripts/character_builder.gd")
    _character_model = CharacterBuilder.build(mesh_holder, character_id)
    
    # Apply character color as a tint on the torso (kept for backwards compat)
    # Now individual parts have their own colors

func set_active(active: bool):
    is_active = active
    camera.current = active
    if active:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    else:
        pass

func _input(event):
    if not is_active or in_vehicle:
        return
    if event is InputEventMouseMotion:
        camera_rig.rotation.y -= event.relative.x * SENSITIVITY
        camera_rig.rotation.x = clamp(
            camera_rig.rotation.x - event.relative.y * SENSITIVITY,
            -1.2, 0.5
        )

func _physics_process(delta):
    if not is_active or in_vehicle:
        if not is_on_floor():
            velocity.y -= gravity * delta
        move_and_slide()
        # Idle animation - subtle breathing
        _animate_idle(delta)
        return
    
    # Gravity
    if not is_on_floor():
        velocity.y -= gravity * delta
    
    # Jump
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY
    
    # Movement direction (camera-relative)
    _is_running = Input.is_action_pressed("run")
    var speed = RUN_SPEED if _is_running else WALK_SPEED
    
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction = (camera_rig.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
        var target_rotation = atan2(direction.x, direction.z)
        rotation.y = lerp_angle(rotation.y, target_rotation, ROTATION_SPEED * delta)
        _is_moving = true
        # Walk/run animation
        _animate_walk(delta, speed)
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
        velocity.z = move_toward(velocity.z, 0, speed)
        _is_moving = false
        _animate_idle(delta)
    
    move_and_slide()

# Simple idle animation - subtle vertical bob (breathing)
func _animate_idle(delta):
    if not _character_model:
        return
    _walk_cycle += delta * 2.0
    var bob = sin(_walk_cycle) * 0.02
    _character_model.position.y = bob
    # Slightly swing arms
    var left_arm = _character_model.get_node_or_null("LeftUpperArm")
    var right_arm = _character_model.get_node_or_null("RightUpperArm")
    if left_arm and right_arm:
        left_arm.rotation_x = sin(_walk_cycle) * 0.05
        right_arm.rotation_x = -sin(_walk_cycle) * 0.05

# Walk/run animation - leg swing + arm swing
func _animate_walk(delta, speed):
    if not _character_model:
        return
    var cycle_speed = 8.0 if speed > 7.0 else 6.0
    _walk_cycle += delta * cycle_speed
    
    var swing_amount = 0.6 if speed > 7.0 else 0.4
    var bob_amount = 0.05 if speed > 7.0 else 0.03
    
    # Vertical bob
    _character_model.position.y = abs(sin(_walk_cycle * 2)) * bob_amount
    
    # Leg swing
    var left_upper_leg = _character_model.get_node_or_null("LeftUpperLeg")
    var right_upper_leg = _character_model.get_node_or_null("RightUpperLeg")
    var left_lower_leg = _character_model.get_node_or_null("LeftLowerLeg")
    var right_lower_leg = _character_model.get_node_or_null("RightLowerLeg")
    if left_upper_leg and right_upper_leg:
        left_upper_leg.rotation_x = sin(_walk_cycle) * swing_amount
        right_upper_leg.rotation_x = -sin(_walk_cycle) * swing_amount
    if left_lower_leg and right_lower_leg:
        # Lower legs bend opposite to upper for natural walk
        left_lower_leg.rotation_x = max(0, -sin(_walk_cycle) * swing_amount * 0.7)
        right_lower_leg.rotation_x = max(0, sin(_walk_cycle) * swing_amount * 0.7)
    
    # Arm swing (opposite to legs)
    var left_arm = _character_model.get_node_or_null("LeftUpperArm")
    var right_arm = _character_model.get_node_or_null("RightUpperArm")
    var left_forearm = _character_model.get_node_or_null("LeftForearm")
    var right_forearm = _character_model.get_node_or_null("RightForearm")
    if left_arm and right_arm:
        left_arm.rotation_x = -sin(_walk_cycle) * swing_amount
        right_arm.rotation_x = sin(_walk_cycle) * swing_amount
    if left_forearm and right_forearm:
        left_forearm.rotation_x = -0.3 + abs(sin(_walk_cycle)) * 0.2
        right_forearm.rotation_x = -0.3 + abs(sin(_walk_cycle)) * 0.2

# Called by vehicle system when entering/exiting a car
func enter_vehicle(_vehicle_node):
    in_vehicle = true
    visible = false
    velocity = Vector3.ZERO

func exit_vehicle(_vehicle_node, exit_position: Vector3):
    in_vehicle = false
    visible = true
    global_position = exit_position
    velocity = Vector3.ZERO
