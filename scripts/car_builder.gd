# Car Builder - Creates a procedural car model from primitives
# Body, cabin, windows, wheels, headlights, taillights
extends Node3D

# Different car color schemes per brand
const CAR_SCHEMES = {
    "comet": {  # Porsche-style - yellow
        "body": Color(0.95, 0.85, 0.15),
        "cabin": Color(0.15, 0.15, 0.18),
        "accent": Color(0.05, 0.05, 0.05),
    },
    "adder": {  # Bugatti-style - blue
        "body": Color(0.10, 0.30, 0.85),
        "cabin": Color(0.05, 0.05, 0.08),
        "accent": Color(0.95, 0.95, 0.95),
    },
    "vacca": {  # Lambo-style - orange
        "body": Color(0.95, 0.45, 0.10),
        "cabin": Color(0.08, 0.08, 0.10),
        "accent": Color(0.10, 0.10, 0.10),
    },
    "turismo": {  # Ferrari-style - red
        "body": Color(0.85, 0.10, 0.10),
        "cabin": Color(0.05, 0.05, 0.05),
        "accent": Color(0.95, 0.95, 0.95),
    },
    "buffalo": {  # Muscle - matte black
        "body": Color(0.08, 0.08, 0.08),
        "cabin": Color(0.05, 0.05, 0.05),
        "accent": Color(0.80, 0.10, 0.10),
    },
}

# Build a car model as a child of the given parent
# car_brand determines the color scheme
static func build(parent: Node3D, car_brand: String) -> Node3D:
    var root = Node3D.new()
    root.name = "CarModel"
    parent.add_child(root)
    
    var scheme = CAR_SCHEMES.get(car_brand.to_lower(), CAR_SCHEMES["comet"])
    var body_color = scheme["body"]
    var cabin_color = scheme["cabin"]
    var accent_color = scheme["accent"]
    
    # === MAIN BODY (lower box) ===
    _create_part("BodyLower", Vector3(2.0, 0.5, 4.2), Vector3(0, 0.5, 0), body_color, root, 0.3)
    
    # === HOOD (front, slightly lower) ===
    _create_part("Hood", Vector3(1.9, 0.25, 1.4), Vector3(0, 0.85, 1.4), body_color, root, 0.3)
    
    # === TRUNK (rear, slightly lower) ===
    _create_part("Trunk", Vector3(1.9, 0.25, 1.0), Vector3(0, 0.85, -1.5), body_color, root, 0.3)
    
    # === CABIN (middle, raised, with windows) ===
    _create_part("Cabin", Vector3(1.7, 0.55, 1.8), Vector3(0, 1.20, 0), cabin_color, root, 0.2)
    
    # === WINDOWS (transparent-ish black) ===
    var window_color = Color(0.05, 0.08, 0.12, 0.85)
    # Windshield (front of cabin)
    var windshield = _create_part("Windshield", Vector3(1.65, 0.50, 0.10), Vector3(0, 1.20, 0.95), window_color, root, 0.1)
    # Tilt the windshield back
    windshield.rotation_degrees = Vector3(-30, 0, 0)
    # Rear window
    var rear_window = _create_part("RearWindow", Vector3(1.65, 0.50, 0.10), Vector3(0, 1.20, -0.95), window_color, root, 0.1)
    rear_window.rotation_degrees = Vector3(30, 0, 0)
    # Side windows
    _create_part("LeftWindow", Vector3(0.05, 0.40, 1.6), Vector3(-0.85, 1.25, 0), window_color, root, 0.1)
    _create_part("RightWindow", Vector3(0.05, 0.40, 1.6), Vector3(0.85, 1.25, 0), window_color, root, 0.1)
    
    # === HEADLIGHTS (front, white/yellow) ===
    _create_part("LeftHeadlight", Vector3(0.35, 0.18, 0.05), Vector3(-0.65, 0.65, 2.10), Color(1.0, 1.0, 0.85), root, 0.0, true)
    _create_part("RightHeadlight", Vector3(0.35, 0.18, 0.05), Vector3(0.65, 0.65, 2.10), Color(1.0, 1.0, 0.85), root, 0.0, true)
    
    # === TAILLIGHTS (rear, red) ===
    _create_part("LeftTaillight", Vector3(0.35, 0.18, 0.05), Vector3(-0.65, 0.65, -2.10), Color(0.85, 0.10, 0.10), root, 0.0, true)
    _create_part("RightTaillight", Vector3(0.35, 0.18, 0.05), Vector3(0.65, 0.65, -2.10), Color(0.85, 0.10, 0.10), root, 0.0, true)
    
    # === ACCENT STRIPE (down the middle, side) ===
    _create_part("SideStripe", Vector3(0.02, 0.10, 3.5), Vector3(1.01, 0.60, 0), accent_color, root, 0.4)
    _create_part("SideStripe2", Vector3(0.02, 0.10, 3.5), Vector3(-1.01, 0.60, 0), accent_color, root, 0.4)
    
    # === WHEELS (visible as black cylinders - actual wheel physics is on VehicleWheel3D) ===
    # Front-left
    _create_wheel("WheelFL", Vector3(-1.0, 0.4, 1.4), root)
    # Front-right
    _create_wheel("WheelFR", Vector3(1.0, 0.4, 1.4), root)
    # Rear-left
    _create_wheel("WheelRL", Vector3(-1.0, 0.4, -1.4), root)
    # Rear-right
    _create_wheel("WheelRR", Vector3(1.0, 0.4, -1.4), root)
    
    return root

# Helper: creates a single box body part
static func _create_part(part_name: String, size: Vector3, position: Vector3, color: Color, parent: Node, roughness: float = 0.3, emissive: bool = false) -> MeshInstance3D:
    var mesh_inst = MeshInstance3D.new()
    mesh_inst.name = part_name
    var box = BoxMesh.new()
    box.size = size
    mesh_inst.mesh = box
    mesh_inst.position = position
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    mat.metallic = 0.5 if roughness < 0.2 else 0.0
    if emissive:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 0.8
    
    mesh_inst.material_override = mat
    parent.add_child(mesh_inst)
    return mesh_inst

# Helper: creates a wheel (cylinder rotated to roll on Z axis)
static func _create_wheel(part_name: String, position: Vector3, parent: Node) -> MeshInstance3D:
    var mesh_inst = MeshInstance3D.new()
    mesh_inst.name = part_name
    var cyl = CylinderMesh.new()
    cyl.top_radius = 0.35
    cyl.bottom_radius = 0.35
    cyl.height = 0.25
    mesh_inst.mesh = cyl
    mesh_inst.position = position
    # Rotate so cylinder axis is along X (across the car)
    mesh_inst.rotation_degrees = Vector3(0, 0, 90)
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.05, 0.05, 0.05)
    mat.roughness = 0.8
    mesh_inst.material_override = mat
    
    parent.add_child(mesh_inst)
    return mesh_inst
