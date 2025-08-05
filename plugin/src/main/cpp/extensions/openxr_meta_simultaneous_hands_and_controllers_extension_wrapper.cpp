/**************************************************************************/
/*  openxr_meta_simultaneous_hands_and_controllers_extension_wrapper.cpp  */
/**************************************************************************/
/*                       This file is part of:                            */
/*                              GODOT XR                                  */
/*                      https://godotengine.org                           */
/**************************************************************************/
/* Copyright (c) 2022-present Godot XR contributors (see CONTRIBUTORS.md) */
/*                                                                        */
/* Permission is hereby granted, free of charge, to any person obtaining  */
/* a copy of this software and associated documentation files (the        */
/* "Software"), to deal in the Software without restriction, including    */
/* without limitation the rights to use, copy, modify, merge, publish,    */
/* distribute, sublicense, and/or sell copies of the Software, and to     */
/* permit persons to whom the Software is furnished to do so, subject to  */
/* the following conditions:                                              */
/*                                                                        */
/* The above copyright notice and this permission notice shall be         */
/* included in all copies or substantial portions of the Software.        */
/*                                                                        */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
/**************************************************************************/

// @todo GH Issue 304: Remove check for meta headers when feature becomes part of OpenXR spec.
// #ifdef META_HEADERS_ENABLED - Temporarily disabled for testing
#include "extensions/openxr_meta_simultaneous_hands_and_controllers_extension_wrapper.h"

#include <godot_cpp/classes/open_xrapi_extension.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/classes/xr_interface.hpp>
#include <godot_cpp/classes/xr_server.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper *OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::singleton = nullptr;

OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper *OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::get_singleton() {
	if (singleton == nullptr) {
		singleton = memnew(OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper());
	}
	return singleton;
}

OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper() :
		OpenXRExtensionWrapperExtension() {
	ERR_FAIL_COND_MSG(singleton != nullptr, "An OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper singleton already exists.");

	request_extensions[XR_META_SIMULTANEOUS_HANDS_AND_CONTROLLERS_EXTENSION_NAME] = &meta_simultaneous_hands_and_controllers_ext;
	singleton = this;
}

OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::~OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper() {
	cleanup();
	singleton = nullptr;
}

godot::Dictionary OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::_get_requested_extensions() {
	godot::Dictionary result;
	for (auto ext : request_extensions) {
		godot::String key = ext.first;
		uint64_t value = reinterpret_cast<uint64_t>(ext.second);
		result[key] = (godot::Variant)value;
	}
	return result;
}

uint64_t OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::_set_system_properties_and_get_next_pointer(void *p_next_pointer) {
	if (meta_simultaneous_hands_and_controllers_ext) {
		simultaneous_hands_and_controllers_properties.next = p_next_pointer;
		p_next_pointer = &simultaneous_hands_and_controllers_properties;
	}

	return reinterpret_cast<uint64_t>(p_next_pointer);
}

void OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::_on_instance_created(uint64_t p_instance) {
	if (meta_simultaneous_hands_and_controllers_ext) {
		bool result = initialize_meta_simultaneous_hands_and_controllers_extension((XrInstance)p_instance);
		if (!result) {
			UtilityFunctions::printerr("Failed to initialize meta_simultaneous_hands_and_controllers extension");
			meta_simultaneous_hands_and_controllers_ext = false;
		}
	}
}

void OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::_on_instance_destroyed() {
	cleanup();
}

bool OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::_on_event_polled(const void *p_event) {
	if (!meta_simultaneous_hands_and_controllers_ext) {
		return false;
	}

	if (static_cast<const XrEventDataBuffer *>(p_event)->type == XR_TYPE_EVENT_DATA_INTERACTION_PROFILE_CHANGED) {
		const XrEventDataInteractionProfileChanged *interaction_profile_event = static_cast<const XrEventDataInteractionProfileChanged *>(p_event);
		emit_signal("openxr_interaction_profile_changed", (uint64_t)interaction_profile_event->session);
		return true;
	}

	return false;
}

bool OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::is_simultaneous_hands_and_controllers_supported() {
	return simultaneous_hands_and_controllers_properties.supportsSimultaneousHandsAndControllers;
}

void OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::resume_simultaneous_tracking() {
	if (!meta_simultaneous_hands_and_controllers_ext) {
		UtilityFunctions::printerr("META simultaneous hands and controllers extension is not available");
		return;
	}

	if (!is_simultaneous_hands_and_controllers_supported()) {
		UtilityFunctions::printerr("System does not support simultaneous hands and controllers tracking");
		return;
	}

	if (is_tracking_active) {
		// Already active, no need to resume
		return;
	}

	XrSimultaneousHandsAndControllersTrackingResumeInfoMETA resume_info = {
		XR_TYPE_SIMULTANEOUS_HANDS_AND_CONTROLLERS_TRACKING_RESUME_INFO_META, // type
		nullptr // next
	};

	XrResult result = xrResumeSimultaneousHandsAndControllersTrackingMETA(SESSION, &resume_info);
	if (XR_FAILED(result)) {
		UtilityFunctions::printerr("Failed to resume simultaneous hands and controllers tracking: ", get_openxr_api()->get_error_string(result));
	} else {
		is_tracking_active = true;
		emit_signal("openxr_simultaneous_tracking_resumed");
	}
}

void OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::pause_simultaneous_tracking() {
	if (!meta_simultaneous_hands_and_controllers_ext) {
		UtilityFunctions::printerr("META simultaneous hands and controllers extension is not available");
		return;
	}

	if (!is_tracking_active) {
		// Already paused, no need to pause again
		return;
	}

	XrSimultaneousHandsAndControllersTrackingPauseInfoMETA pause_info = {
		XR_TYPE_SIMULTANEOUS_HANDS_AND_CONTROLLERS_TRACKING_PAUSE_INFO_META, // type
		nullptr // next
	};

	XrResult result = xrPauseSimultaneousHandsAndControllersTrackingMETA(SESSION, &pause_info);
	if (XR_FAILED(result)) {
		UtilityFunctions::printerr("Failed to pause simultaneous hands and controllers tracking: ", get_openxr_api()->get_error_string(result));
	} else {
		is_tracking_active = false;
		emit_signal("openxr_simultaneous_tracking_paused");
	}
}

bool OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::is_simultaneous_tracking_active() {
	return is_tracking_active;
}

void OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::_bind_methods() {
	ClassDB::bind_method(D_METHOD("is_simultaneous_hands_and_controllers_supported"), &OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::is_simultaneous_hands_and_controllers_supported);

	ClassDB::bind_method(D_METHOD("resume_simultaneous_tracking"), &OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::resume_simultaneous_tracking);
	ClassDB::bind_method(D_METHOD("pause_simultaneous_tracking"), &OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::pause_simultaneous_tracking);
	ClassDB::bind_method(D_METHOD("is_simultaneous_tracking_active"), &OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::is_simultaneous_tracking_active);

	ADD_SIGNAL(MethodInfo("openxr_simultaneous_tracking_resumed"));
	ADD_SIGNAL(MethodInfo("openxr_simultaneous_tracking_paused"));
	ADD_SIGNAL(MethodInfo("openxr_interaction_profile_changed", PropertyInfo(Variant::INT, "session")));
}

void OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::cleanup() {
	meta_simultaneous_hands_and_controllers_ext = false;
	is_tracking_active = false;
}

bool OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper::initialize_meta_simultaneous_hands_and_controllers_extension(XrInstance p_instance) {
	GDEXTENSION_INIT_XR_FUNC_V(xrResumeSimultaneousHandsAndControllersTrackingMETA);
	GDEXTENSION_INIT_XR_FUNC_V(xrPauseSimultaneousHandsAndControllersTrackingMETA);

	return true;
}
// #endif // META_HEADERS_ENABLED - Temporarily disabled for testing