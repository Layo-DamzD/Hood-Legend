# Player Controller - Third-person character movement
# Works on both PC (WASD + mouse) and Mobile (virtual joystick + touch look)
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

# Node references
@onready var camera_rig = $CameraRig
@onready var camera = $CameraRig/Camera3D  # The actual Camera3D node
@onready var mesh = $Mesh

# Input manager reference (set by main.gd)
var input_manager: Node = null

func _ready():
    # Set the camera's current property (NOT the rig's - the rig is a Node3D)
    camera.current = false
    var mat = StandardMaterial3D.new()
    mat.albedo_color = character_color
    mesh.material_override = mat

func set_active(active: bool):
    is_active = active
    camera.current = active  # Use camera, not camera_rig
    if active:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    else:
        pass

func _input(event):
    if not is_active or in_vehicle:
        return
    # Only handle mouse motion on desktop (mobile uses injected events)
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
        return
    
    # Gravity
    if not is_on_floor():
        velocity.y -= gravity * delta
    
    # Jump (works on both platforms - mobile uses virtual button)
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY
    
    # Movement direction (camera-relative)
    var speed = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
    
    # Get input vector - works for both keyboard (Input) and mobile (InputManager injects)
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    
    var direction = (camera_rig.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
        var target_rotation = atan2(direction.x, direction.z)
        rotation.y = lerp_angle(rotation.y, target_rotation, ROTATION_SPEED * delta)
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
        velocity.z = move_toward(velocity.z, 0, speed)
    
    move_and_slide()

# Called by vehicle system when entering/exiting a car
# (parameter prefixed with _ to suppress unused warning)
func enter_vehicle(_vehicle_node):
    in_vehicle = true
    visible = false
    velocity = Vector3.ZERO

func exit_vehicle(_vehicle_node, exit_position: Vector3):
    in_vehicle = false
    visible = true
    global_position = exit_position
    velocity = Vector3.ZERO
