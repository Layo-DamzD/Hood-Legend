# Debug helper - run this from Godot's Script Editor to check input mappings
# To use: open this file in Godot's Script Editor and press F6 (Run Current Script)
extends SceneTree

func _init():
    print("=== INPUT MAPPING CHECK ===")
    var actions = InputMap.get_actions()
    print("Total actions defined: ", actions.size())
    print("")
    
    var required = ["move_forward", "move_back", "move_left", "move_right", 
                    "jump", "run", "switch_character", "enter_exit_vehicle",
                    "fire", "interact", "pause"]
    
    for action in required:
        if InputMap.has_action(action):
            var events = InputMap.action_get_events(action)
            print("  ", action, ": OK (", events.size(), " events bound)")
        else:
            print("  ", action, ": MISSING! ← THIS WILL CAUSE ERRORS")
    
    print("")
    print("=== PROJECT INFO ===")
    print("Project name: ", ProjectSettings.get_setting("application/config/name"))
    print("Main scene: ", ProjectSettings.get_setting("application/run/main_scene"))
    print("Godot version: ", Engine.get_version_info()["string"])
    print("")
    print("If any actions are MISSING above, the project.godot file's input")
    print("section didn't load correctly. Re-import the project.")
    print("=== END DEBUG ===")
    quit()
