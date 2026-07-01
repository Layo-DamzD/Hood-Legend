# Virtual Joystick - On-screen touch joystick for mobile movement
extends Control

@export var max_distance: float = 80.0
@export var dead_zone: float = 0.1

var output: Vector2 = Vector2.ZERO

var _touching: bool = false
var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO

@onready var base = $Base
@onready var stick = $Base/Stick
@onready var touch_area = $TouchArea

func _ready():
    if OS.has_feature("android") or OS.has_feature("ios") or OS.is_debug_build():
        visible = true
    else:
        visible = false
    
    # Defer the layout calc to next frame so ColorRects have their sizes
    call_deferred("_setup_layout")

func _setup_layout():
    if touch_area and base:
        var area_size = touch_area.size
        if area_size == Vector2.ZERO:
            area_size = Vector2(240, 240)  # Fallback
        _center = area_size / 2
        base.position = _center - base.size / 2

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed and _touch_index == -1:
            var local_pos = event.position - touch_area.global_position
            if local_pos.x >= 0 and local_pos.x <= touch_area.size.x and local_pos.y >= 0 and local_pos.y <= touch_area.size.y:
                _touching = true
                _touch_index = event.index
                base.position = event.position - touch_area.global_position - base.size / 2
                _update_stick(event.position - touch_area.global_position)
        elif not event.pressed and event.index == _touch_index:
            _touching = false
            _touch_index = -1
            output = Vector2.ZERO
            stick.position = base.size / 2 - stick.size / 2
    
    elif event is InputEventScreenDrag and event.index == _touch_index:
        var local_pos = event.position - touch_area.global_position
        _update_stick(local_pos)

func _update_stick(touch_pos: Vector2):
    var center_pos = base.position + base.size / 2
    var delta = touch_pos - center_pos
    var distance = delta.length()
    
    if distance > max_distance:
        delta = delta.normalized() * max_distance
        distance = max_distance
    
    stick.position = center_pos + delta - stick.size / 2 - base.position
    
    if distance > dead_zone * max_distance:
        output = delta / max_distance
    else:
        output = Vector2.ZERO

func get_vector() -> Vector2:
    return output
