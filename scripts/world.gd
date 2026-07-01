# World Generator - Spawns the city environment
# For Phase 1: a few city blocks with roads, sidewalks, and buildings
# In later phases this expands to the full large map.
extends Node3D

# Building colors for variety
const BUILDING_COLORS = [
    Color(0.5, 0.45, 0.4),
    Color(0.4, 0.4, 0.45),
    Color(0.55, 0.5, 0.4),
    Color(0.3, 0.3, 0.35),
    Color(0.6, 0.55, 0.5),
    Color(0.45, 0.5, 0.55),
]

const GROUND_SIZE = 500.0
const BLOCK_SIZE = 40.0
const ROAD_WIDTH = 12.0

func _ready():
    _generate_ground()
    _generate_roads()
    _generate_buildings()
    _generate_props()

func _generate_ground():
    var ground = StaticBody3D.new()
    var mesh = MeshInstance3D.new()
    var plane = PlaneMesh.new()
    plane.size = Vector2(GROUND_SIZE, GROUND_SIZE)
    mesh.mesh = plane
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.25, 0.3, 0.2)  # Grass / dirt base
    mesh.material_override = mat
    ground.add_child(mesh)
    
    var col = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = Vector3(GROUND_SIZE, 0.1, GROUND_SIZE)
    col.shape = shape
    ground.add_child(col)
    
    add_child(ground)

func _generate_roads():
    # Create a grid of roads
    var road_mat = StandardMaterial3D.new()
    road_mat.albedo_color = Color(0.1, 0.1, 0.1)
    
    var grid_extent = 6  # How many blocks in each direction from center
    for i in range(-grid_extent, grid_extent + 1):
        # Horizontal road
        var road_h = _create_road(road_mat, true, i * BLOCK_SIZE)
        add_child(road_h)
        # Vertical road
        var road_v = _create_road(road_mat, false, i * BLOCK_SIZE)
        add_child(road_v)

func _create_road(material: Material, horizontal: bool, offset: float) -> StaticBody3D:
    var road = StaticBody3D.new()
    var mesh = MeshInstance3D.new()
    var box = BoxMesh.new()
    var length = BLOCK_SIZE * 13  # Long enough to span the grid
    if horizontal:
        box.size = Vector3(length, 0.05, ROAD_WIDTH)
    else:
        box.size = Vector3(ROAD_WIDTH, 0.05, length)
    mesh.mesh = box
    mesh.material_override = material
    
    if horizontal:
        mesh.position = Vector3(0, 0.05, offset)
    else:
        mesh.position = Vector3(offset, 0.05, 0)
    
    road.add_child(mesh)
    
    var col = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    if horizontal:
        shape.size = Vector3(length, 0.1, ROAD_WIDTH)
        col.position = Vector3(0, 0.05, offset)
    else:
        shape.size = Vector3(ROAD_WIDTH, 0.1, length)
        col.position = Vector3(offset, 0.05, 0)
    col.shape = shape
    road.add_child(col)
    
    return road

func _generate_buildings():
    var rng = RandomNumberGenerator.new()
    rng.seed = hash("hood_legends_seed")
    
    var grid_extent = 5
    for x in range(-grid_extent, grid_extent + 1):
        for z in range(-grid_extent, grid_extent + 1):
            # Skip center area (player spawn)
            if abs(x) <= 1 and abs(z) <= 1:
                continue
            
            # Place 1-3 buildings per block
            var num_buildings = rng.randi_range(1, 3)
            for b in range(num_buildings):
                var building = _create_building(rng)
                var bx = x * BLOCK_SIZE + rng.randf_range(-12, 12)
                var bz = z * BLOCK_SIZE + rng.randf_range(-12, 12)
                building.position = Vector3(bx, 0, bz)
                add_child(building)

func _create_building(rng: RandomNumberGenerator) -> StaticBody3D:
    var building = StaticBody3D.new()
    var mesh = MeshInstance3D.new()
    var box = BoxMesh.new()
    
    var width = rng.randf_range(6, 12)
    var depth = rng.randf_range(6, 12)
    var height = rng.randf_range(8, 30)
    
    box.size = Vector3(width, height, depth)
    mesh.mesh = box
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = BUILDING_COLORS[rng.randi() % BUILDING_COLORS.size()]
    mesh.material_override = mat
    
    mesh.position = Vector3(0, height / 2, 0)
    building.add_child(mesh)
    
    var col = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = Vector3(width, height, depth)
    col.shape = shape
    col.position = Vector3(0, height / 2, 0)
    building.add_child(col)
    
    return building

func _generate_props():
    # Add some streetlights and trees for atmosphere
    var rng = RandomNumberGenerator.new()
    rng.seed = hash("props_seed")
    
    for i in range(40):
        var prop_type = rng.randi() % 2
        var prop: Node3D
        if prop_type == 0:
            prop = _create_streetlight()
        else:
            prop = _create_tree()
        
        prop.position = Vector3(
            rng.randf_range(-200, 200),
            0,
            rng.randf_range(-200, 200)
        )
        add_child(prop)

func _create_streetlight() -> Node3D:
    var light_node = Node3D.new()
    
    # Pole
    var pole = MeshInstance3D.new()
    var pole_mesh = CylinderMesh.new()
    pole_mesh.top_radius = 0.15
    pole_mesh.bottom_radius = 0.2
    pole_mesh.height = 8.0
    pole.mesh = pole_mesh
    pole.position = Vector3(0, 4, 0)
    var pole_mat = StandardMaterial3D.new()
    pole_mat.albedo_color = Color(0.2, 0.2, 0.2)
    pole.material_override = pole_mat
    light_node.add_child(pole)
    
    # Light
    var lamp = OmniLight3D.new()
    lamp.light_color = Color(1, 0.9, 0.7)
    lamp.light_energy = 2.0
    lamp.omni_range = 15.0
    lamp.position = Vector3(0, 8, 0)
    light_node.add_child(lamp)
    
    return light_node

func _create_tree() -> Node3D:
    var tree = Node3D.new()
    
    # Trunk
    var trunk = MeshInstance3D.new()
    var trunk_mesh = CylinderMesh.new()
    trunk_mesh.top_radius = 0.3
    trunk_mesh.bottom_radius = 0.4
    trunk_mesh.height = 4.0
    trunk.mesh = trunk_mesh
    trunk.position = Vector3(0, 2, 0)
    var trunk_mat = StandardMaterial3D.new()
    trunk_mat.albedo_color = Color(0.4, 0.25, 0.15)
    trunk.material_override = trunk_mat
    tree.add_child(trunk)
    
    # Foliage
    var foliage = MeshInstance3D.new()
    var foliage_mesh = SphereMesh.new()
    foliage_mesh.radius = 2.0
    foliage_mesh.height = 4.0
    foliage.mesh = foliage_mesh
    foliage.position = Vector3(0, 5, 0)
    var fol_mat = StandardMaterial3D.new()
    fol_mat.albedo_color = Color(0.2, 0.45, 0.2)
    foliage.material_override = fol_mat
    tree.add_child(foliage)
    
    return tree
