extends XRController3D

@onready var hand_cube: MeshInstance3D = $HandCube
@onready var render_model: OpenXRFbRenderModel = $ControllerFbRenderModel

# Debug visualization
var debug_material: StandardMaterial3D
var original_material: Material
var simultaneous_tracking_active: bool = false

func _ready():
	# Create debug material for visual feedback
	debug_material = StandardMaterial3D.new()
	debug_material.albedo_color = Color.YELLOW
	debug_material.emission_enabled = true
	debug_material.emission = Color.YELLOW * 0.3
	
	# Store original material
	if hand_cube and hand_cube.get_surface_override_material(0):
		original_material = hand_cube.get_surface_override_material(0)

func _process(_delta: float) -> void:
	var hand_tracker_name = "/user/hand_tracker/left" if tracker == "left_hand" \
			else "/user/hand_tracker/right"
	var hand_tracker_hand: OpenXRInterface.Hand = OpenXRInterface.HAND_LEFT if tracker == "left_hand" \
		else OpenXRInterface.HAND_RIGHT

	var interface: OpenXRInterface = XRServer.find_interface("OpenXR")
	
	# Check simultaneous tracking status
	check_simultaneous_tracking_status()

	var hand_tracker: XRHandTracker = XRServer.get_tracker(hand_tracker_name)
	if hand_tracker and hand_tracker.has_tracking_data:
		# Apply visual feedback based on tracking source and simultaneous mode
		update_visual_feedback(hand_tracker)
		
		# If hand tracking data is provided by controller,
		# and controller model is available, show it with hand mesh.
		if hand_tracker.hand_tracking_source == XRHandTracker.HAND_TRACKING_SOURCE_CONTROLLER \
				and render_model.has_render_model_node():
			render_model.show()  
			interface.set_motion_range(hand_tracker_hand, OpenXRInterface.HAND_MOTION_RANGE_CONFORM_TO_CONTROLLER)
		# If hand tracking data is not provided by controller,
		# and controller model is available, hide it.
		elif render_model.has_render_model_node():
			render_model.hide()
			interface.set_motion_range(hand_tracker_hand, OpenXRInterface.HAND_MOTION_RANGE_UNOBSTRUCTED)

		# Always hide placeholder hand cubes if we have hand tracking data.
		hand_cube.hide()
	else:
		# Show render model if availabe, otherwise show hand cubes.
		if render_model.has_render_model_node():
			render_model.show()
			hand_cube.hide()
		else:
			hand_cube.show()
			# Reset visual feedback when no tracking data
			reset_visual_feedback()

func check_simultaneous_tracking_status():
	"""Check if simultaneous tracking is currently active"""
	var extension_wrapper = Engine.get_singleton("OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper")
	if extension_wrapper:
		simultaneous_tracking_active = extension_wrapper.is_simultaneous_tracking_active()

func update_visual_feedback(hand_tracker: XRHandTracker):
	"""Update visual feedback based on tracking state"""
	if not hand_cube:
		return
		
	# Color coding for different tracking states
	if simultaneous_tracking_active:
		# Yellow glow when simultaneous tracking is active
		hand_cube.set_surface_override_material(0, debug_material)
		
		# Additional feedback based on tracking source
		if hand_tracker.hand_tracking_source == XRHandTracker.HAND_TRACKING_SOURCE_CONTROLLER:
			debug_material.albedo_color = Color.CYAN  # Cyan for controller in simultaneous mode
			debug_material.emission = Color.CYAN * 0.4
		else:
			debug_material.albedo_color = Color.YELLOW  # Yellow for hand in simultaneous mode  
			debug_material.emission = Color.YELLOW * 0.4
	else:
		# Standard colors when not in simultaneous mode
		if hand_tracker.hand_tracking_source == XRHandTracker.HAND_TRACKING_SOURCE_CONTROLLER:
			debug_material.albedo_color = Color.BLUE  # Blue for controller only
			debug_material.emission = Color.BLUE * 0.2
			hand_cube.set_surface_override_material(0, debug_material)
		else:
			debug_material.albedo_color = Color.GREEN  # Green for hand only
			debug_material.emission = Color.GREEN * 0.2
			hand_cube.set_surface_override_material(0, debug_material)

func reset_visual_feedback():
	"""Reset visual feedback to original state"""
	if hand_cube:
		hand_cube.set_surface_override_material(0, original_material)
