# World Generator - Spawns a larger city environment with multiple districts
# Phase 2: Bigger map, more buildings, parks, parking lots, multiple cars
extends Node3D

const BUILDING_COLORS = [
    Color(0.5, 0.45, 0.4),
    Color(0.4, 0.4, 0.45),
    Color(0.55, 0.5, 0.4),
    Color(0.3, 0.3, 0.35),
    Color(0.6, 0.55, 0.5),
    Color(0.45, 0.5, 0.55),
    Color(0.35, 0.40, 0.45),
    Color(0.50, 0.35, 0.30),
]

const GROUND_SIZE = 800.0       # Doubled from 500
const BLOCK_SIZE = 40.0
const ROAD_WIDTH = 12.0
const GRID_EXTENT = 8           # Doubled from 6 - so ~4x more area

# Car spawn positions (brand, position)
const CAR_SPAWNS = [
    {"brand": "Comet", "pos": Vector3(0, 0.5, 12)},      # Near player spawn (yellow sports)
    {"brand": "Adder", "pos": Vector3(40, 0.5, 0)},      # Bugatti-style, one block east (blue)
    {"brand": "Vacca", "pos": Vector3(-40, 0.5, 20)},    # Lambo-style (orange)
    {"brand": "Turismo", "pos": Vector3(80, 0.5, -40)},  # Ferrari-style (red)
    {"brand": "Buffalo", "pos": Vector3(-80, 0.5, 40)},  # Muscle (matte black)
]

# Preloaded car scene
var car_scene: PackedScene = null

func _ready():
    # Load the car scene for spawning multiple cars
    car_scene = load("res://scenes/car.tscn")
    
    _generate_ground()
    _generate_roads()
    _generate_buildings()
    _generate_parks()
    _generate_props()
    _spawn_cars()

func _generate_ground():
    var ground = StaticBody3D.new()
    var mesh = MeshInstance3D.new()
    var plane = PlaneMesh.new()
    plane.size = Vector2(GROUND_SIZE, GROUND_SIZE)
    mesh.mesh = plane
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.20, 0.28, 0.18)  # Grass/dirt
    mesh.material_override = mat
    ground.add_child(mesh)
    
    var col = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = Vector3(GROUND_SIZE, 0.1, GROUND_SIZE)
    col.shape = shape
    ground.add_child(col)
    
    add_child(ground)

func _generate_roads():
    var road_mat = StandardMaterial3D.new()
    road_mat.albedo_color = Color(0.10, 0.10, 0.10)
    road_mat.roughness = 0.85
    
    var sidewalk_mat = StandardMaterial3D.new()
    sidewalk_mat.albedo_color = Color(0.55, 0.55, 0.55)
    
    for i in range(-GRID_EXTENT, GRID_EXTENT + 1):
        var road_h = _create_road(road_mat, true, i * BLOCK_SIZE)
        add_child(road_h)
        var road_v = _create_road(road_mat, false, i * BLOCK_SIZE)
        add_child(road_v)

func _create_road(material: Material, horizontal: bool, offset: float) -> StaticBody3D:
    var road = StaticBody3D.new()
    var mesh = MeshInstance3D.new()
    var box = BoxMesh.new()
    var length = BLOCK_SIZE * (GRID_EXTENT * 2 + 1)
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
    rng.seed = hash("hood_legends_v2")
    
    for x in range(-GRID_EXTENT, GRID_EXTENT + 1):
        for z in range(-GRID_EXTENT, GRID_EXTENT + 1):
            # Skip center area (player spawn + first block)
            if abs(x) <= 1 and abs(z) <= 1:
                continue
            # Skip some blocks for parks (every 4th block on a diagonal)
            if (x + z) % 4 == 0 and x != 0 and z != 0:
                continue
            
            var num_buildings = rng.randi_range(1, 4)
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
    
    var width = rng.randf_range(6, 14)
    var depth = rng.randf_range(6, 14)
    var height = rng.randf_range(8, 40)
    
    box.size = Vector3(width, height, depth)
    mesh.mesh = box
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = BUILDING_COLORS[rng.randi() % BUILDING_COLORS.size()]
    mat.roughness = 0.75
    mesh.material_override = mat
    
    mesh.position = Vector3(0, height / 2, 0)
    building.add_child(mesh)
    
    # Add windows (grid of small emissive yellow boxes on the front face)
    if height > 12 and rng.randf() > 0.3:
        var window_mat = StandardMaterial3D.new()
        window_mat.albedo_color = Color(0.95, 0.85, 0.4)
        window_mat.emission_enabled = true
        window_mat.emission = Color(0.95, 0.85, 0.4)
        window_mat.emission_energy_multiplier = 0.4
        
        var rows = int(height / 3.5)
        var cols = int(width / 2.5)
        for r in range(rows):
            for c in range(cols):
                if rng.randf() > 0.55:  # Not all windows lit
                    continue
                var window_mesh = MeshInstance3D.new()
                var window_box = BoxMesh.new()
                window_box.size = Vector3(1.2, 1.5, 0.05)
                window_mesh.mesh = window_box
                window_mesh.material_override = window_mat
                window_mesh.position = Vector3(
                    -width/2 + 1.5 + c * 2.5,
                    2 + r * 3.5,
                    depth/2 + 0.01
                )
                building.add_child(window_mesh)
    
    var col = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = Vector3(width, height, depth)
    col.shape = shape
    col.position = Vector3(0, height / 2, 0)
    building.add_child(col)
    
    return building

func _generate_parks():
    var rng = RandomNumberGenerator.new()
    rng.seed = hash("parks_v2")
    
    # Add parks on the diagonal blocks we skipped
    for x in range(-GRID_EXTENT, GRID_EXTENT + 1):
        for z in range(-GRID_EXTENT, GRID_EXTENT + 1):
            if (x + z) % 4 == 0 and x != 0 and z != 0 and abs(x) > 1 and abs(z) > 1:
                # This is a park block - add grass patch + trees
                var park_x = x * BLOCK_SIZE
                var park_z = z * BLOCK_SIZE
                
                # Grass patch (lighter green)
                var grass = StaticBody3D.new()
                var grass_mesh = MeshInstance3D.new()
                var grass_box = BoxMesh.new()
                grass_box.size = Vector3(BLOCK_SIZE - 4, 0.1, BLOCK_SIZE - 4)
                grass_mesh.mesh = grass_box
                grass_mesh.position = Vector3(park_x, 0.07, park_z)
                var grass_mat = StandardMaterial3D.new()
                grass_mat.albedo_color = Color(0.30, 0.45, 0.20)
                grass_mesh.material_override = grass_mat
                grass.add_child(grass_mesh)
                add_child(grass)
                
                # Add 3-5 trees in the park
                var num_trees = rng.randi_range(3, 5)
                for t in range(num_trees):
                    var tree = _create_tree()
                    tree.position = Vector3(
                        park_x + rng.randf_range(-15, 15),
                        0,
                        park_z + rng.randf_range(-15, 15)
                    )
                    add_child(tree)

func _generate_props():
    var rng = RandomNumberGenerator.new()
    rng.seed = hash("props_v2")
    
    for i in range(80):
        var prop_type = rng.randi() % 3
        var prop: Node3D
        if prop_type == 0:
            prop = _create_streetlight()
        elif prop_type == 1:
            prop = _create_tree()
        else:
            prop = _create_bench()
        
        prop.position = Vector3(
            rng.randf_range(-300, 300),
            0,
            rng.randf_range(-300, 300)
        )
        add_child(prop)

func _create_streetlight() -> Node3D:
    var light_node = Node3D.new()
    
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
    
    var lamp = OmniLight3D.new()
    lamp.light_color = Color(1, 0.9, 0.7)
    lamp.light_energy = 2.0
    lamp.omni_range = 15.0
    lamp.position = Vector3(0, 8, 0)
    light_node.add_child(lamp)
    
    return light_node

func _create_tree() -> Node3D:
    var tree = Node3D.new()
    
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

func _create_bench() -> Node3D:
    var bench = Node3D.new()
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.35, 0.20, 0.10)
    
    var seat = MeshInstance3D.new()
    var seat_box = BoxMesh.new()
    seat_box.size = Vector3(1.5, 0.1, 0.4)
    seat.mesh = seat_box
    seat.position = Vector3(0, 0.5, 0)
    seat.material_override = mat
    bench.add_child(seat)
    
    return bench

func _spawn_cars():
    for spawn in CAR_SPAWNS:
        var car = car_scene.instantiate()
        car.car_brand = spawn["brand"]
        car.position = spawn["pos"]
        # Random rotation so cars don't all face the same way
        car.rotation_degrees.y = randf_range(0, 360)
        add_child(car)
