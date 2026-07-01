# Virtual Joystick - On-screen touch joystick for mobile movement
# Drag inside the joystick area to move the character
# Works on both Android and desktop (mouse drag for testing)
extends Control

# Visual settings
@export var max_distance: float = 80.0
@export var dead_zone: float = 0.1

# Output: -1 to 1 on each axis
var output: Vector2 = Vector2.ZERO

# Internal state
var _touching: bool = false
var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO

# Node references
@onready var base = $Base
@onready var stick = $Base/Stick
@onready var touch_area = $TouchArea

func _ready():
    # Hide on desktop unless debugging
    if OS.has_feature("android") or OS.has_feature("ios") or OS.is_debug_build():
        visible = true
    else:
        visible = false
    
    # Position the base at center of touch area
    _center = touch_area.size / 2
    base.position = _center - base.size / 2

func _input(event):
    # Touch input
    if event is InputEventScreenTouch:
        if event.pressed and _touch_index == -1:
            var local_pos = event.position - touch_area.global_position
            if local_pos.x >= 0 and local_pos.x <= touch_area.size.x and local_pos.y >= 0 and local_pos.y <= touch_area.size.y:
                _touching = true
                _touch_index = event.index
                # Move base to where finger landed (dynamic joystick)
                base.position = event.position - touch_area.global_position - base.size / 2
                _update_stick(event.position - touch_area.global_position)
        elif not event.pressed and event.index == _touch_index:
            _touching = false
            _touch_index = -1
            output = Vector2.ZERO
            # Animate stick back to center
            stick.position = base.size / 2 - stick.size / 2
    
    # Touch drag
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
    
    # Normalize output to -1..1
    if distance > dead_zone * max_distance:
        output = delta / max_distance
    else:
        output = Vector2.ZERO

# Public API: get movement vector
func get_vector() -> Vector2:
    return output
