local ecs = ...
local world = ecs.world
local w = world.w

local default	= import_package "ant.general".default
local icamera	= ecs.import.interface "ant.camera|icamera"
local irender	= ecs.import.interface "ant.render|irender"

local mathpkg	= import_package "ant.math"
local mu		= mathpkg.util

local fr_sys = ecs.system "forward_render_system"

function fr_sys:init()
	local ratio = world.args.framebuffer.scene_ratio
	local vr = mu.calc_viewport(world.args.viewport, ratio)
	if ratio then
		vr.ratio = ratio
	end
	local camera = icamera.create{
		name = "default_camera",
		frustum = default.frustum(vr.w/vr.h),
		exposure = {
			type 			= "manual",
			aperture 		= 16.0,
			shutter_speed 	= 0.008,
			ISO 			= 100,
		}
	}

	if irender.use_pre_depth() then
		irender.create_pre_depth_queue(vr, camera)
	end
	irender.create_main_queue(vr, camera)
end

local mq_cc = world:sub{"camera_changed", "main_queue"}
local mq_vr_changed = world:sub{"view_rect_changed", "main_queue"}

function fr_sys:data_changed()
	if irender.use_pre_depth() then
		for _, _, ceid in mq_cc:unpack() do
			local pdq = w:first "pre_depth_queue camera_ref:out"
			pdq.camera_ref = ceid
			w:submit(pdq)
		end

		for _, _, vr in mq_vr_changed:unpack() do
			local pdq = w:first "pre_depth_queue render_target:in"
			mu.copy2viewrect(vr, pdq.render_target.view_rect)
		end
	end
end