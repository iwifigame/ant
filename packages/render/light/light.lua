local ecs = ...
local world = ecs.world
local w = world.w

local declmgr	= require "vertexdecl_mgr"
local math3d	= require "math3d"
local bgfx		= require "bgfx"
local iom		= ecs.import.interface "ant.objcontroller|obj_motion"
local ies		= ecs.import.interface "ant.scene|ientity_state"

local setting	= import_package "ant.settings".setting
local enable_cluster_shading = setting:data().graphic.lighting.cluster_shading ~= 0

local DEFAULT_INTENSITY<const> = {
	directional = 2,--120000,
	point = 2, --1200,
	spot = 2,--1200,
	area = 2, --1200
}

local changed = false

local function setChanged()
	changed = true
end

local function isChanged()
	if changed then
		changed = false
		return true
	end
	for _ in w:select "scene_changed light" do
		return true
	end
	--TODO state
end

local ilight = ecs.interface "light"

function ilight.create(light)
	return ecs.create_entity {
		policy = {
			"ant.render|light",
			"ant.general|name",
		},
		data = {
			name		= light.name or "DEFAULT_LIGHT",
			scene = {
				srt = light.transform
			},
			light = {
				make_shadow	= light.make_shadow,
				motion_type = light.motion_type,
				light_type	= assert(light.light_type),
				color		= light.color,
				intensity	= light.intensity,
				range		= light.range,
				inner_radian= light.inner_radian,
				outter_radian= light.outter_radian,
				angular_radius=light.angular_radius,
			},
			visible = true,
		}
	}
end

function ilight.data(e)
	w:sync("light:in", e)
	return e.light
end

function ilight.color(e)
	w:sync("light:in", e)
	return e.light.color
end

function ilight.set_color(e, color)
	w:sync("light:in", e)
	local l = e.light
	local c = l.color
	for i=1, 4 do c[i] = color[i] end
	setChanged()
end

function ilight.intensity(e)
	w:sync("light:in", e)
	return e.light.intensity
end

function ilight.set_intensity(e, i)
	w:sync("light:in", e)
	e.light.intensity = i
	setChanged()
end

function ilight.range(e)
	w:sync("light:in", e)
	return e.light.range
end

function ilight.set_range(e, r)
	w:sync("light:in", e)
	if e.light.light_type == "directional" then
		error("directional light do not have 'range' property")
	end
	e.light.range = r
	setChanged()
end

function ilight.inner_radian(e)
	w:sync("light:in", e)
	return e.light.inner_radian
end

local function check_spot_light(e)
	if e.light.light_type ~= "spot" then
		error(("%s light do not have 'radian' property"):format(e.light.light_type))
	end
end

local spot_radian_threshold<const> = 10e-6
function ilight.set_inner_radian(e, r)
	w:sync("light:in", e)
	check_spot_light(e)
	local l = e.light
	l.inner_radian = math.min(l.outter_radian-spot_radian_threshold, r)
	l.inner_cutoff = math.cos(l.inner_radian*0.5)
	setChanged()
end

function ilight.outter_radian(e)
	w:sync("light:in", e)
	return e.light.outter_radian
end

function ilight.set_outter_radian(e, r)
	w:sync("light:in", e)
	check_spot_light(e)
	local l = e.light
	l.outter_radian = math.max(r, l.inner_radian+spot_radian_threshold)
	l.outter_cutoff = math.cos(l.outter_radian*0.5)
	setChanged()
end

function ilight.inner_cutoff(e)
	w:sync("light:in", e)
	return e.light.inner_cutoff
end

function ilight.outter_cutoff(e)
	w:sync("light:in", e)
	return e.light.outter_cutoff
end

function ilight.which_type(e)
	w:sync("light:in", e)
	return e.light.light_type
end

function ilight.make_shadow(e)
	w:sync("light:in", e)
	return e.light.make_shadow
end

function ilight.set_make_shadow(e, enable)
	w:sync("light:in", e)
	e.light.make_shadow = enable
end

function ilight.motion_type(e)
	w:sync("light:in", e)
	return e.light.motion_type
end

function ilight.set_motion_type(e, t)
	w:sync("light:in", e)
	e.light.motion_type = t
end

local lighttypes = {
	directional = 0,
	point = 1,
	spot = 2,
}

local function count_visible_light()
	local n = 0
	for _ in w:select "light visible" do
		n = n + 1
	end
	return n
end

ilight.count_visible_light = count_visible_light

local function create_light_buffers()
	local lights = {}
	for e in w:select "light:in visible" do
		local p	= math3d.tovalue(iom.get_position(e))
		local d	= math3d.tovalue(math3d.inverse(iom.get_direction(e)))
		local c = e.light.color
		local t	= e.light.light_type
		local enable<const> = 1
		lights[#lights+1] = ('f'):rep(16):pack(
			p[1], p[2], p[3],
			e.light.range or math.maxinteger,
			d[1], d[2], d[3], enable,
			c[1], c[2], c[3], c[4],
			lighttypes[t],
			e.light.intensity,
			e.light.inner_cutoff or 0,
			e.light.outter_cutoff or 0
		)
	end
    return lights
end

function ilight.use_cluster_shading()
	return enable_cluster_shading
end

local light_buffer = bgfx.create_dynamic_vertex_buffer(1, declmgr.get "t40".handle, "ra")

local function update_light_buffers()
	local lights = create_light_buffers()
	if #lights > 0 then
		bgfx.update(light_buffer, 0, bgfx.memory_buffer(table.concat(lights, "")))
	end
end

function ilight.light_buffer()
	return light_buffer
end

local lightsys = ecs.system "light_system"

function lightsys:entity_init()
	for e in w:select "INIT light:in" do
		setChanged()
		local l = e.light
		local t = l.light_type
		l.color			= l.color or {1, 1, 1, 1}
		l.intensity		= l.intensity or 2
		l.make_shadow	= l.make_shadow or false
		l.motion_type	= l.motion_type or "dynamic"
		l.angular_radius= l.angular_radius or math.rad(0.27)
		if t == "point" then
			if l.range == nil then
				error("point light need range defined!")
			end
			l.inner_radian = 0
			l.outter_radian = 0
			l.inner_cutoff = 0
			l.outter_cutoff = 0
		elseif t == "spot" then
			if l.range == nil then
				error("spot light need range defined!")
			end
			local i_r, o_r = e.inner_radian, e.outter_radian
			if i_r == nil or o_r == nil then
				error("spot light need 'inner_radian' and 'outter_radian' defined!")
			end
			if i_r > o_r then
				error(("invalid 'inner_radian' > 'outter_radian':%d, %d"):format(i_r, o_r))
			end
			l.inner_radian, l.outter_radian = i_r, o_r
			l.inner_cutoff = math.cos(l.inner_radian * 0.5)
			l.outter_cutoff = math.cos(l.outter_radian * 0.5)
		else
			l.range = math.maxinteger
			l.inner_radian = 0
			l.outter_radian = 0
			l.inner_cutoff = 0
			l.outter_cutoff = 0
		end
	end
end

function lightsys:entity_remove()
	for _ in w:select "REMOVED light" do
		setChanged()
		return
	end
end

function lightsys:update_system_properties()
	if isChanged() then
		update_light_buffers()
	end
end
