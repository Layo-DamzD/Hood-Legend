# Player Manager - Handles switching between the two protagonists
# Like GTA V's character switching (but only 2 characters here)
# Each character stays where you left them when you switch away.
extends Node

# References to the two player characters
@export var player_a: NodePath
@export var player_b: NodePath

@onready var p_a = get_node(player_a)
@onready var p_b = get_node(player_b)

# Which character is currently active (0 = A, 1 = B)
var active_index: int = 0

# Switch cooldown to prevent spam
var switch_cooldown: float = 0.0
const SWITCH_DELAY: float = 0.5

func _ready():
    # Start with player A active
    p_a.set_active(true)
    p_b.set_active(false)

func _process(delta):
    if switch_cooldown > 0:
        switch_cooldown -= delta
    
    if Input.is_action_just_pressed("switch_character") and switch_cooldown <= 0:
        switch_character()
        switch_cooldown = SWITCH_DELAY

func switch_character():
    if active_index == 0:
        # Switch to B
        p_a.set_active(false)
        p_b.set_active(true)
        active_index = 1
        print("Switched to: ", p_b.character_name)
    else:
        # Switch to A
        p_b.set_active(false)
        p_a.set_active(true)
        active_index = 0
        print("Switched to: ", p_a.character_name)

func get_active_player():
    return p_a if active_index == 0 else p_b
