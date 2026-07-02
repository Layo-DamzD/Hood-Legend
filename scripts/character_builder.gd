# Character Builder - Creates a procedural humanoid character
# Builds head, torso, arms, legs from primitive meshes
# Each character gets distinct proportions/colors for visual variety
extends Node3D

# Skin tones
const SKIN_TONES = {
    "marcus": Color(0.45, 0.30, 0.20),   # Darker brown
    "maya": Color(0.62, 0.45, 0.35),     # Medium brown
}

# Outfit colors
const OUTFIT_COLORS = {
    "marcus": Color(0.15, 0.15, 0.20),   # Dark navy
    "maya": Color(0.55, 0.20, 0.45),     # Pink
}

# Builds the character mesh as a child of the given parent
# Returns the root node of the character
static func build(parent: Node3D, character_id: String) -> Node3D:
    var root = Node3D.new()
    root.name = "CharacterModel"
    parent.add_child(root)
    
    var skin_color = SKIN_TONES.get(character_id, Color(0.5, 0.4, 0.3))
    var outfit_color = OUTFIT_COLORS.get(character_id, Color(0.2, 0.2, 0.2))
    
    # === HEAD ===
    var head = _create_part("Head", Vector3(0.18, 0.22, 0.18), Vector3(0, 1.55, 0), skin_color, root)
    # Hair (slightly larger box on top of head, different color)
    var hair_color = Color(0.05, 0.04, 0.03) if character_id == "marcus" else Color(0.15, 0.05, 0.05)
    _create_part("Hair", Vector3(0.20, 0.08, 0.20), Vector3(0, 1.72, 0), hair_color, root)
    # Eyes (small white boxes on face front)
    var left_eye = _create_part("LeftEye", Vector3(0.04, 0.04, 0.02), Vector3(-0.06, 1.58, 0.10), Color(1, 1, 1), root)
    var right_eye = _create_part("RightEye", Vector3(0.04, 0.04, 0.02), Vector3(0.06, 1.58, 0.10), Color(1, 1, 1), root)
    # Pupils (small dark boxes in front of eyes)
    _create_part("LeftPupil", Vector3(0.02, 0.02, 0.01), Vector3(-0.06, 1.58, 0.115), Color(0.05, 0.05, 0.05), root)
    _create_part("RightPupil", Vector3(0.02, 0.02, 0.01), Vector3(0.06, 1.58, 0.115), Color(0.05, 0.05, 0.05), root)
    
    # === TORSO ===
    _create_part("Torso", Vector3(0.45, 0.65, 0.25), Vector3(0, 1.05, 0), outfit_color, root)
    # Chest detail (slightly lighter strip down middle)
    var chest_detail_color = outfit_color.lightened(0.15)
    _create_part("ChestDetail", Vector3(0.10, 0.55, 0.02), Vector3(0, 1.05, 0.13), chest_detail_color, root)
    
    # === ARMS ===
    # Upper arms
    _create_part("LeftUpperArm", Vector3(0.12, 0.35, 0.12), Vector3(-0.32, 1.20, 0), outfit_color, root)
    _create_part("RightUpperArm", Vector3(0.12, 0.35, 0.12), Vector3(0.32, 1.20, 0), outfit_color, root)
    # Lower arms (forearms - skin colored, like rolled up sleeves)
    _create_part("LeftForearm", Vector3(0.10, 0.30, 0.10), Vector3(-0.32, 0.80, 0), skin_color, root)
    _create_part("RightForearm", Vector3(0.10, 0.30, 0.10), Vector3(0.32, 0.80, 0), skin_color, root)
    # Hands
    _create_part("LeftHand", Vector3(0.10, 0.12, 0.08), Vector3(-0.32, 0.60, 0), skin_color, root)
    _create_part("RightHand", Vector3(0.10, 0.12, 0.08), Vector3(0.32, 0.60, 0), skin_color, root)
    
    # === LEGS ===
    # Upper legs (pants color)
    var pants_color = Color(0.10, 0.10, 0.15) if character_id == "marcus" else Color(0.10, 0.10, 0.10)
    _create_part("LeftUpperLeg", Vector3(0.16, 0.40, 0.16), Vector3(-0.12, 0.55, 0), pants_color, root)
    _create_part("RightUpperLeg", Vector3(0.16, 0.40, 0.16), Vector3(0.12, 0.55, 0), pants_color, root)
    # Lower legs (still pants)
    _create_part("LeftLowerLeg", Vector3(0.13, 0.40, 0.13), Vector3(-0.12, 0.20, 0), pants_color, root)
    _create_part("RightLowerLeg", Vector3(0.13, 0.40, 0.13), Vector3(0.12, 0.20, 0), pants_color, root)
    # Shoes
    var shoe_color = Color(0.05, 0.05, 0.05)
    _create_part("LeftShoe", Vector3(0.16, 0.08, 0.25), Vector3(-0.12, 0.04, 0.05), shoe_color, root)
    _create_part("RightShoe", Vector3(0.16, 0.08, 0.25), Vector3(0.12, 0.04, 0.05), shoe_color, root)
    
    return root

# Helper: creates a single body part as a MeshInstance3D
static func _create_part(part_name: String, size: Vector3, position: Vector3, color: Color, parent: Node) -> MeshInstance3D:
    var mesh_inst = MeshInstance3D.new()
    mesh_inst.name = part_name
    var box = BoxMesh.new()
    box.size = size
    mesh_inst.mesh = box
    mesh_inst.position = position
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.7
    mesh_inst.material_override = mat
    
    parent.add_child(mesh_inst)
    return mesh_inst
