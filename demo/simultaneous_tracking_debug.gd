extends Node

# Simultaneous Hands and Controllers Extension Debug Manager
# Tests and monitors the META simultaneous tracking extension

var extension_wrapper: OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper
var debug_ui: Control
var status_labels: Dictionary = {}
var event_log: RichTextLabel
var test_sequence_running: bool = false

# Debug state tracking
var last_left_profile: String = ""
var last_right_profile: String = ""
var event_count: int = 0
var start_time: float

signal extension_status_changed(status: String)
signal tracking_state_changed(active: bool)
signal interaction_profile_changed(session: int)

func _ready():
	start_time = Time.get_time_dict_from_system()["hour"] * 3600 + Time.get_time_dict_from_system()["minute"] * 60 + Time.get_time_dict_from_system()["second"]
	print("🔍 [SimultaneousTrackingDebug] Initializing extension debug system...")
	
	# Try to get the extension wrapper
	initialize_extension()
	
	# Create debug UI
	create_debug_ui()
	
	# Start monitoring
	start_monitoring()

func initialize_extension():
	"""Initialize and test the extension wrapper"""
	print("📡 [SimultaneousTrackingDebug] Getting extension singleton...")
	
	# First check if the class exists
	if not ClassDB.class_exists("OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper"):
		log_event("❌ Extension class not registered in ClassDB", true)
		list_available_extensions()
		return
	
	# Try to get the singleton using Engine.get_singleton
	extension_wrapper = Engine.get_singleton("OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper")
	
	if extension_wrapper == null:
		log_event("❌ Extension singleton is NULL - not registered properly", true)
		return
	
	log_event("✅ Extension wrapper loaded successfully")
	
	
	# Connect to extension signals
	if extension_wrapper.has_signal("openxr_simultaneous_tracking_resumed"):
		extension_wrapper.connect("openxr_simultaneous_tracking_resumed", _on_tracking_resumed)
		log_event("🔗 Connected to tracking_resumed signal")
	
	if extension_wrapper.has_signal("openxr_simultaneous_tracking_paused"):
		extension_wrapper.connect("openxr_simultaneous_tracking_paused", _on_tracking_paused)
		log_event("🔗 Connected to tracking_paused signal")
	
	if extension_wrapper.has_signal("openxr_interaction_profile_changed"):
		extension_wrapper.connect("openxr_interaction_profile_changed", _on_interaction_profile_changed)
		log_event("🔗 Connected to interaction_profile_changed signal")
	
	# Test basic functionality
	test_extension_api()

func list_available_extensions():
	"""List all available OpenXR extension classes for debugging"""
	log_event("🔍 Listing available OpenXR extension classes:")
	
	var all_classes = ClassDB.get_class_list()
	var openxr_classes = []
	
	for c in all_classes:
		if "OpenXR" in c and "Extension" in c:
			openxr_classes.append(c)
	
	if openxr_classes.is_empty():
		log_event("❌ No OpenXR extension classes found", true)
	else:
		for c in openxr_classes:
			log_event("   - " + c)
	
	# Also check engine singletons
	log_event("🔍 Available Engine singletons:")
	var singletons = Engine.get_singleton_list()
	for singleton_name in singletons:
		if "OpenXR" in singleton_name:
			log_event("   - " + singleton_name)

func test_extension_api():
	"""Test all extension API methods"""
	log_event("🧪 Testing extension API methods...")
	
	# Test support check
	var is_supported = extension_wrapper.is_simultaneous_hands_and_controllers_supported()
	log_event("🏗️ System support: " + ("✅ YES" if is_supported else "❌ NO"))
	extension_status_changed.emit("supported" if is_supported else "not_supported")
	
	# Test status check
	var is_active = extension_wrapper.is_simultaneous_tracking_active()
	log_event("⚡ Currently active: " + ("✅ YES" if is_active else "❌ NO"))
	tracking_state_changed.emit(is_active)
	
	# If supported, try to enable it
	if is_supported:
		log_event("🚀 Attempting to resume simultaneous tracking...")
		extension_wrapper.resume_simultaneous_tracking()
	else:
		log_event("⚠️ Cannot test resume/pause - system not supported")

func create_debug_ui():
	"""Create the visual debug interface"""
	# Create a CanvasLayer for UI overlay
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100 # Ensure it's on top
	add_child(canvas_layer)
	
	# Main debug panel
	debug_ui = Panel.new()
	debug_ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	debug_ui.size = Vector2(400, 500)
	debug_ui.position = Vector2(10, 10)
	canvas_layer.add_child(debug_ui)
	
	# Create UI layout
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	debug_ui.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "🎯 Simultaneous Tracking Debug"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	# Status section
	create_status_section(vbox)
	
	# Control buttons
	create_control_buttons(vbox)
	
	# Hand/Controller status
	create_tracking_status_section(vbox)
	
	# Event log
	create_event_log_section(vbox)

func create_status_section(parent: VBoxContainer):
	"""Create extension status indicators"""
	var status_frame = VBoxContainer.new()
	parent.add_child(status_frame)
	
	# Extension status
	status_labels["extension"] = Label.new()
	status_labels["extension"].text = "Extension: Loading..."
	status_frame.add_child(status_labels["extension"])
	
	# System support
	status_labels["support"] = Label.new()
	status_labels["support"].text = "System Support: Checking..."
	status_frame.add_child(status_labels["support"])
	
	# Active status
	status_labels["active"] = Label.new()
	status_labels["active"].text = "Tracking Active: Unknown"
	status_frame.add_child(status_labels["active"])

func create_control_buttons(parent: VBoxContainer):
	"""Create control buttons for manual testing"""
	var button_frame = HBoxContainer.new()
	parent.add_child(button_frame)
	
	# Resume button
	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.pressed.connect(_on_resume_pressed)
	button_frame.add_child(resume_btn)
	
	# Pause button
	var pause_btn = Button.new()
	pause_btn.text = "Pause"
	pause_btn.pressed.connect(_on_pause_pressed)
	button_frame.add_child(pause_btn)
	
	# Test cycle button
	var test_btn = Button.new()
	test_btn.text = "Test Cycle"
	test_btn.pressed.connect(_on_test_cycle_pressed)
	button_frame.add_child(test_btn)

func create_tracking_status_section(parent: VBoxContainer):
	"""Create hand/controller tracking status display"""
	var tracking_frame = VBoxContainer.new()
	parent.add_child(tracking_frame)
	
	var tracking_title = Label.new()
	tracking_title.text = "👐 Hand/Controller Status:"
	tracking_frame.add_child(tracking_title)
	
	status_labels["left_hand"] = Label.new()
	status_labels["left_hand"].text = "Left Hand: Unknown"
	tracking_frame.add_child(status_labels["left_hand"])
	
	status_labels["right_hand"] = Label.new()
	status_labels["right_hand"].text = "Right Hand: Unknown"
	tracking_frame.add_child(status_labels["right_hand"])

func create_event_log_section(parent: VBoxContainer):
	"""Create event log display"""
	var log_title = Label.new()
	log_title.text = "📋 Event Log:"
	parent.add_child(log_title)
	
	event_log = RichTextLabel.new()
	event_log.custom_minimum_size = Vector2(380, 150)
	event_log.scroll_following = true
	event_log.bbcode_enabled = true
	parent.add_child(event_log)

func start_monitoring():
	"""Start continuous monitoring of hand/controller states"""
	# Update UI every frame
	pass

func _process(_delta):
	"""Update debug information continuously"""
	update_hand_controller_status()
	update_interaction_profiles()

func update_hand_controller_status():
	"""Update the visual status of hands and controllers"""
	var left_tracker = XRServer.get_tracker("/user/hand_tracker/left")
	var right_tracker = XRServer.get_tracker("/user/hand_tracker/right")
	
	# Left hand status
	if left_tracker and left_tracker.has_tracking_data:
		var source = "Hand" if left_tracker.hand_tracking_source == XRHandTracker.HAND_TRACKING_SOURCE_UNOBSTRUCTED else "Controller"
		status_labels["left_hand"].text = "Left Hand: ✅ " + source
		status_labels["left_hand"].modulate = Color.GREEN if source == "Hand" else Color.BLUE
	else:
		status_labels["left_hand"].text = "Left Hand: ❌ No Data"
		status_labels["left_hand"].modulate = Color.RED
	
	# Right hand status  
	if right_tracker and right_tracker.has_tracking_data:
		var source = "Hand" if right_tracker.hand_tracking_source == XRHandTracker.HAND_TRACKING_SOURCE_UNOBSTRUCTED else "Controller"
		status_labels["right_hand"].text = "Right Hand: ✅ " + source
		status_labels["right_hand"].modulate = Color.GREEN if source == "Hand" else Color.BLUE
	else:
		status_labels["right_hand"].text = "Right Hand: ❌ No Data"
		status_labels["right_hand"].modulate = Color.RED

func update_interaction_profiles():
	"""Monitor interaction profile changes"""
	var openxr_interface = XRServer.find_interface("OpenXR")
	if not openxr_interface:
		return
	
	# This would require additional OpenXR API calls to get current interaction profiles
	# For now, we'll rely on the extension's signals

func log_event(message: String, is_error: bool = false):
	"""Add an event to the log with timestamp"""
	event_count += 1
	var time_dict = Time.get_time_dict_from_system()
	var timestamp = "%02d:%02d:%02d" % [time_dict.hour, time_dict.minute, time_dict.second]
	
	var color = "red" if is_error else "white"
	var full_message = "[color=%s][%s] %s[/color]" % [color, timestamp, message]
	
	if event_log:
		event_log.append_text(full_message + "\n")
	
	# Also print to console
	print("🕐 [%s] %s" % [timestamp, message])

# Signal handlers for extension events
func _on_tracking_resumed():
	log_event("🟢 Simultaneous tracking RESUMED")
	if status_labels.has("active"):
		status_labels["active"].text = "Tracking Active: ✅ YES"
		status_labels["active"].modulate = Color.GREEN
	tracking_state_changed.emit(true)

func _on_tracking_paused():
	log_event("🟡 Simultaneous tracking PAUSED")
	if status_labels.has("active"):
		status_labels["active"].text = "Tracking Active: ❌ NO"
		status_labels["active"].modulate = Color.RED
	tracking_state_changed.emit(false)

func _on_interaction_profile_changed(session: int):
	log_event("🔄 Interaction profile changed (session: %d)" % session)
	interaction_profile_changed.emit(session)

# Button handlers
func _on_resume_pressed():
	if extension_wrapper:
		log_event("🎮 Manual RESUME requested")
		extension_wrapper.resume_simultaneous_tracking()
	else:
		log_event("❌ Cannot resume - extension not available", true)

func _on_pause_pressed():
	if extension_wrapper:
		log_event("⏸️ Manual PAUSE requested")
		extension_wrapper.pause_simultaneous_tracking()
	else:
		log_event("❌ Cannot pause - extension not available", true)

func _on_test_cycle_pressed():
	if test_sequence_running:
		log_event("⚠️ Test cycle already running")
		return
	
	log_event("🔄 Starting automated test cycle...")
	run_test_sequence()

func run_test_sequence():
	"""Run automated test sequence"""
	test_sequence_running = true
	
	if not extension_wrapper:
		log_event("❌ Cannot run test - extension not available", true)
		test_sequence_running = false
		return
	
	log_event("🧪 Test 1/4: Checking support...")
	var supported = extension_wrapper.is_simultaneous_hands_and_controllers_supported()
	log_event("Result: " + ("✅ Supported" if supported else "❌ Not supported"))
	
	await get_tree().create_timer(1.0).timeout
	
	log_event("🧪 Test 2/4: Testing resume...")
	extension_wrapper.resume_simultaneous_tracking()
	
	await get_tree().create_timer(2.0).timeout
	
	log_event("🧪 Test 3/4: Checking active status...")
	var active = extension_wrapper.is_simultaneous_tracking_active()
	log_event("Result: " + ("✅ Active" if active else "❌ Not active"))
	
	await get_tree().create_timer(1.0).timeout
	
	log_event("🧪 Test 4/4: Testing pause...")
	extension_wrapper.pause_simultaneous_tracking()
	
	await get_tree().create_timer(1.0).timeout
	
	log_event("✅ Test cycle completed!")
	test_sequence_running = false

# Update status labels based on extension state
func _on_extension_status_changed(status: String):
	if status_labels.has("support"):
		if status == "supported":
			status_labels["support"].text = "System Support: ✅ YES"
			status_labels["support"].modulate = Color.GREEN
		else:
			status_labels["support"].text = "System Support: ❌ NO"
			status_labels["support"].modulate = Color.RED
	
	if status_labels.has("extension"):
		status_labels["extension"].text = "Extension: ✅ Loaded"
		status_labels["extension"].modulate = Color.GREEN

func _on_tracking_state_changed(active: bool):
	if status_labels.has("active"):
		status_labels["active"].text = "Tracking Active: " + ("✅ YES" if active else "❌ NO")
		status_labels["active"].modulate = Color.GREEN if active else Color.RED
