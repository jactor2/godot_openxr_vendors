extends Node3D

var xr_interface: XRInterface = null
var debug_system: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.initialize():
		xr_interface.session_stopping.connect(self._on_session_stopping)
		var vp: Viewport = get_viewport()
		vp.use_xr = true
		
		# Initialize simultaneous tracking debug system
		initialize_debug_system()
	else:
		print("❌ Failed to initialize OpenXR interface")
		# Still show debug system for testing
		initialize_debug_system()

func initialize_debug_system():
	"""Initialize the simple test system"""
	print("🔍 Initializing simple test system...")
	
	# Load and add the simple test script
	var test_script = load("res://simple_test.gd")
	debug_system = Node.new()
	debug_system.set_script(test_script)
	debug_system.name = "SimpleTest"
	add_child(debug_system)
	
	print("✅ Simple test system initialized")


func _on_session_stopping() -> void:
	if "--xrsim-automated-tests" in OS.get_cmdline_user_args():
		# When we're running tests via the XR Simulator, it will end the OpenXR
		# session automatically, and in that case, we want to quit.
		get_tree().quit()
