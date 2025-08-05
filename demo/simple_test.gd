extends Node

# Simple test script for META Simultaneous Hands and Controllers Extension

func _ready():
	print("🧪 Testing META Simultaneous Hands and Controllers Extension...")
	
	# Wait a bit for everything to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	test_extension()

func test_extension():
	print("📡 Getting extension singleton...")
	
	# Try to get our extension
	var extension_wrapper = Engine.get_singleton("OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper")
	
	if extension_wrapper == null:
		print("❌ Extension not found! Checking what's available...")
		list_available_singletons()
		return
	
	print("✅ Extension found successfully!")
	
	# Test the API
	print("🧪 Testing API methods...")
	
	# Test support check
	var is_supported = extension_wrapper.is_simultaneous_hands_and_controllers_supported()
	print("🏗️ System support: " + ("✅ YES" if is_supported else "❌ NO (expected on desktop)"))
	
	# Test status check
	var is_active = extension_wrapper.is_simultaneous_tracking_active()
	print("⚡ Currently active: " + ("✅ YES" if is_active else "❌ NO"))
	
	# Test resume/pause (safe to call even if not supported)
	print("🚀 Testing resume...")
	extension_wrapper.resume_simultaneous_tracking()
	
	# Check status after resume
	await get_tree().create_timer(0.1).timeout
	is_active = extension_wrapper.is_simultaneous_tracking_active()
	print("⚡ After resume: " + ("✅ ACTIVE" if is_active else "❌ NOT ACTIVE"))
	
	print("✅ Extension test completed!")
	
	# Save results to a file for VR testing
	save_test_results(extension_wrapper, is_supported, is_active)

func save_test_results(extension_wrapper, is_supported: bool, is_active: bool):
	var results = "META Simultaneous Hands & Controllers Test Results:\n"
	results += "==============================================\n"
	results += "Extension Found: " + ("YES" if extension_wrapper != null else "NO") + "\n"
	results += "System Support: " + ("YES" if is_supported else "NO") + "\n" 
	results += "Currently Active: " + ("YES" if is_active else "NO") + "\n"
	results += "Test Date: " + Time.get_datetime_string_from_system() + "\n"
	
	var file = FileAccess.open("user://extension_test_results.txt", FileAccess.WRITE)
	if file:
		file.store_string(results)
		file.close()
		print("📄 Results saved to user://extension_test_results.txt")

func list_available_singletons():
	print("🔍 Available Engine singletons:")
	var singletons = Engine.get_singleton_list()
	for singleton_name in singletons:
		if "OpenXR" in singleton_name:
			print("   - " + singleton_name)