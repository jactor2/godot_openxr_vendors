extends XRNode3D

# Debug visualization for simultaneous tracking
var simultaneous_tracking_active: bool = false
var base_modulate: Color = Color.WHITE
var modulate: Color
func _ready():
	base_modulate = modulate

func _process(_delta: float) -> void:
	# Check simultaneous tracking status
	check_simultaneous_tracking_status()
	
	var hand_tracker: XRHandTracker = XRServer.get_tracker(tracker)
	if hand_tracker and hand_tracker.has_tracking_data:
		show()
		update_hand_mesh_visual_feedback(hand_tracker)
	else:
		hide()

func check_simultaneous_tracking_status():
	"""Check if simultaneous tracking is currently active"""
	var extension_wrapper = Engine.get_singleton("OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper")
	if extension_wrapper:
		simultaneous_tracking_active = extension_wrapper.is_simultaneous_tracking_active()

func update_hand_mesh_visual_feedback(hand_tracker: XRHandTracker):
	"""Update hand mesh visual feedback based on tracking state"""
	if simultaneous_tracking_active:
		# Add subtle color tint when simultaneous tracking is active
		if hand_tracker.hand_tracking_source == XRHandTracker.HAND_TRACKING_SOURCE_CONTROLLER:
			modulate = Color.CYAN# Cyan tint for controller-based hand tracking
		else:
			modulate = Color.YELLOW # Yellow tint for pure hand tracking
	else:
		# Standard visualization
		if hand_tracker.hand_tracking_source == XRHandTracker.HAND_TRACKING_SOURCE_CONTROLLER:
			modulate = Color.BLUE # Blue tint for controller only
		else:
			modulate = base_modulate # Normal color for hand only
