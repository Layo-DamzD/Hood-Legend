# Weapon System - Player can pick up and fire a gun
# Press 1 to equip pistol, LMB to fire
extends Node3D

# Weapon types
enum WeaponType {
    NONE,
    PISTOL,
    SMG,  # Submachine gun - future
}

@export var current_weapon: WeaponType = WeaponType.NONE

# Weapon stats
const PISTOL_DAMAGE = 25.0
const PISTOL_RANGE = 100.0
const PISTOL_FIRE_RATE = 0.3  # Seconds between shots
const PISTOL_MAG_SIZE = 12
const PISTOL_RELOAD_TIME = 1.5

# State
var _ammo_in_mag: int = 0
var _total_ammo: int = 60
var _last_fire_time: float = 0.0
var _is_reloading: bool = false
var _reload_start_time: float = 0.0

# Visual model of the held weapon
var _weapon_model: Node3D = null

# Muzzle flash light
var _muzzle_flash: OmniLight3D = null
var _muzzle_flash_timer: float = 0.0

# Bullet trail effect
var _bullet_trails: Array = []

# HUD reference (set by player)
var _hud: Node = null

# Who is holding this weapon
@onready var _player = get_parent()

func _ready():
    # Start with no weapon equipped
    current_weapon = WeaponType.NONE
    
    # Create muzzle flash light (hidden by default)
    _muzzle_flash = OmniLight3D.new()
    _muzzle_flash.light_color = Color(1.0, 0.85, 0.4)
    _muzzle_flash.light_energy = 0.0
    _muzzle_flash.omni_range = 8.0
    _muzzle_flash.position = Vector3(0.3, 1.2, 0.5)  # Approximate gun muzzle position
    add_child(_muzzle_flash)

func _process(delta):
    # Handle reload completion
    if _is_reloading:
        if Time.get_ticks_msec() / 1000.0 - _reload_start_time >= PISTOL_RELOAD_TIME:
            _finish_reload()
    
    # Handle fire input
    if Input.is_action_pressed("fire") and current_weapon != WeaponType.NONE:
        try_fire()
    
    # Reload key (R)
    if Input.is_key_pressed(KEY_R) and current_weapon != WeaponType.NONE:
        start_reload()
    
    # Weapon switch keys (1 = pistol, 0 = holster)
    if Input.is_key_pressed(KEY_1) and not _key_was_pressed_1:
        equip_pistol()
        _key_was_pressed_1 = true
    elif not Input.is_key_pressed(KEY_1):
        _key_was_pressed_1 = false
    
    if Input.is_key_pressed(KEY_0) and not _key_was_pressed_0:
        holster_weapon()
        _key_was_pressed_0 = true
    elif not Input.is_key_pressed(KEY_0):
        _key_was_pressed_0 = false
    
    # Fade muzzle flash
    if _muzzle_flash_timer > 0:
        _muzzle_flash_timer -= delta
        _muzzle_flash.light_energy = max(0, _muzzle_flash_timer * 20.0)

var _key_was_pressed_1: bool = false
var _key_was_pressed_0: bool = false

func equip_pistol():
    if current_weapon == WeaponType.PISTOL:
        return
    current_weapon = WeaponType.PISTOL
    _ammo_in_mag = PISTOL_MAG_SIZE
    _create_pistol_model()
    print("Equipped Pistol - LMB to fire, R to reload, 0 to holster")

func holster_weapon():
    if current_weapon == WeaponType.NONE:
        return
    current_weapon = WeaponType.NONE
    if _weapon_model:
        _weapon_model.queue_free()
        _weapon_model = null
    print("Holstered weapon")

func _create_pistol_model():
    if _weapon_model:
        _weapon_model.queue_free()
    
    _weapon_model = Node3D.new()
    _weapon_model.name = "PistolModel"
    add_child(_weapon_model)
    
    # Gun body (small dark box held in front of player)
    var body = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = Vector3(0.08, 0.12, 0.30)
    body.mesh = box
    body.position = Vector3(0.30, 1.10, 0.30)
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.10, 0.10, 0.10)
    mat.roughness = 0.4
    mat.metallic = 0.7
    body.material_override = mat
    _weapon_model.add_child(body)
    
    # Grip
    var grip = MeshInstance3D.new()
    var grip_box = BoxMesh.new()
    grip_box.size = Vector3(0.07, 0.18, 0.10)
    grip.mesh = grip_box
    grip.position = Vector3(0.30, 0.95, 0.25)
    grip.material_override = mat
    _weapon_model.add_child(grip)

func try_fire():
    if _is_reloading:
        return
    
    var current_time = Time.get_ticks_msec() / 1000.0
    if current_time - _last_fire_time < PISTOL_FIRE_RATE:
        return
    
    if _ammo_in_mag <= 0:
        print("Click! Out of ammo. Press R to reload.")
        start_reload()
        return
    
    _last_fire_time = current_time
    _ammo_in_mag -= 1
    
    # Muzzle flash effect
    _muzzle_flash_timer = 0.05
    _muzzle_flash.light_energy = 5.0
    
    # Raycast forward from camera/player
    _fire_raycast()
    
    print("BANG! Ammo: ", _ammo_in_mag, "/", PISTOL_MAG_SIZE)

func _fire_raycast():
    # Get the active camera to determine aim direction
    var camera = get_viewport().get_camera_3d()
    if not camera:
        return
    
    # Raycast from camera center forward
    var from = camera.global_position
    var to = from - camera.global_transform.basis.z * PISTOL_RANGE
    
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [_player.get_rid()]
    var result = space_state.intersect_ray(query)
    
    if result:
        # Spawn impact effect at hit position
        _spawn_impact(result.position)
        # If we hit a physics body, apply damage (if it has health)
        var collider = result.collider
        if collider.has_method("take_damage"):
            collider.take_damage(PISTOL_DAMAGE)
    else:
        # No hit - bullet went into the sky
        pass

func _spawn_impact(pos: Vector3):
    # Create a brief flash at impact point
    var impact = OmniLight3D.new()
    impact.light_color = Color(1.0, 0.6, 0.2)
    impact.light_energy = 3.0
    impact.omni_range = 3.0
    impact.position = pos
    add_child(impact)
    
    # Auto-remove after 0.1 seconds
    var timer = Timer.new()
    timer.wait_time = 0.1
    timer.one_shot = true
    timer.autostart = true
    timer.timeout.connect(func(): impact.queue_free())
    add_child(timer)

func start_reload():
    if _is_reloading:
        return
    if _ammo_in_mag >= PISTOL_MAG_SIZE:
        return
    if _total_ammo <= 0:
        print("No ammo left!")
        return
    
    _is_reloading = true
    _reload_start_time = Time.get_ticks_msec() / 1000.0
    print("Reloading...")

func _finish_reload():
    _is_reloading = false
    var needed = PISTOL_MAG_SIZE - _ammo_in_mag
    var to_take = min(needed, _total_ammo)
    _ammo_in_mag += to_take
    _total_ammo -= to_take
    print("Reloaded. Ammo: ", _ammo_in_mag, "/", PISTOL_MAG_SIZE, " (", _total_ammo, " reserve)")

func get_ammo_string() -> String:
    if current_weapon == WeaponType.NONE:
        return "Unarmed"
    var weapon_name = WeaponType.keys()[current_weapon]
    return weapon_name + ": " + str(_ammo_in_mag) + "/" + str(PISTOL_MAG_SIZE) + " (" + str(_total_ammo) + ")"
