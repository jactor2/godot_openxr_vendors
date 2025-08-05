/**************************************************************************/
/*  openxr_meta_simultaneous_hands_and_controllers_extension_wrapper.h    */
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
#ifndef OPENXR_META_SIMULTANEOUS_HANDS_AND_CONTROLLERS_EXTENSION_WRAPPER_H
#define OPENXR_META_SIMULTANEOUS_HANDS_AND_CONTROLLERS_EXTENSION_WRAPPER_H

// The extension is already included in the standard OpenXR headers!
#include <openxr/openxr.h>
#include <godot_cpp/classes/open_xr_extension_wrapper_extension.hpp>
#include <map>

#include "util.h"

using namespace godot;

class OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper : public OpenXRExtensionWrapperExtension {
	GDCLASS(OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper, OpenXRExtensionWrapperExtension);

public:
	static OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper *get_singleton();

	OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper();
	~OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper();

	godot::Dictionary _get_requested_extensions() override;

	uint64_t _set_system_properties_and_get_next_pointer(void *p_next_pointer) override;
	void _on_instance_created(uint64_t p_instance) override;
	void _on_instance_destroyed() override;
	bool _on_event_polled(const void *event) override;

	bool is_simultaneous_hands_and_controllers_supported();

	void resume_simultaneous_tracking();
	void pause_simultaneous_tracking();
	bool is_simultaneous_tracking_active();

protected:
	static void _bind_methods();

private:
	EXT_PROTO_XRRESULT_FUNC2(xrResumeSimultaneousHandsAndControllersTrackingMETA,
			(XrSession), session,
			(const XrSimultaneousHandsAndControllersTrackingResumeInfoMETA*), resumeInfo)

	EXT_PROTO_XRRESULT_FUNC2(xrPauseSimultaneousHandsAndControllersTrackingMETA,
			(XrSession), session,
			(const XrSimultaneousHandsAndControllersTrackingPauseInfoMETA*), pauseInfo)

	bool initialize_meta_simultaneous_hands_and_controllers_extension(XrInstance p_instance);

	void cleanup();

	static OpenXRMetaSimultaneousHandsAndControllersExtensionWrapper *singleton;

	std::map<godot::String, bool *> request_extensions;
	bool meta_simultaneous_hands_and_controllers_ext = false;

	XrSystemSimultaneousHandsAndControllersPropertiesMETA simultaneous_hands_and_controllers_properties = {
		XR_TYPE_SYSTEM_SIMULTANEOUS_HANDS_AND_CONTROLLERS_PROPERTIES_META, // type
		nullptr, // next
		false // supportsSimultaneousHandsAndControllers
	};

	bool is_tracking_active = false;
};

#endif // OPENXR_META_SIMULTANEOUS_HANDS_AND_CONTROLLERS_EXTENSION_WRAPPER_H
// #endif // META_HEADERS_ENABLED - Temporarily disabled for testing