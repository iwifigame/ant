local ecs = ...
local world = ecs.world

local math3d = require "math3d"

ecs.component_alias("filter_tag", "string")

local pf = ecs.component "primitive_filter"
	.filter_tag "filter_tag" ("can_render")

function pf:init()
	self.result = {
		translucent = {
			visible_set = {},
		},
		opaticy = {
			visible_set = {},
		},
	}
	return self
end

local prim_filter_sys = ecs.system "primitive_filter_system"

--luacheck: ignore self
local function reset_results(results)
	for k, result in pairs(results) do
		result.n = 0
	end
end

local function add_result(eid, group, materialinfo, worldmat, aabb, result)
	local idx = result.n + 1
	local r = result[idx]
	if r == nil then
		r = {
			mgroup 		= group,
			material 	= assert(materialinfo),
			worldmat 	= worldmat,
			aabb		= aabb,
			eid 		= eid,
		}
		result[idx] = r
	else
		r.mgroup 	= group
		r.material 	= assert(materialinfo)
		r.worldmat 	= worldmat
		r.aabb		= aabb
		r.eid 		= eid
	end
	result.n = idx
	return r
end

function prim_filter_sys:filter_primitive()
	for _, prim_eid in world:each "primitive_filter" do
		local e = world[prim_eid]
		local filter = e.primitive_filter
		reset_results(filter.result)
		local filtertag = filter.filter_tag

		for _, eid in world:each(filtertag) do
			local ce = world[eid]
			if ce[filtertag] then
				local primgroup = ce.rendermesh

				local m = ce.material
				local resulttarget = assert(filter.result[m.fx.surface_type.transparency])

				local worldaabb, worldtrans = math3d.aabb_transform(ce.transform._world, primgroup.bounding and primgroup.bounding.aabb or nil)
				add_result(eid, primgroup, m, worldtrans, worldaabb, resulttarget)
			end
		end
	end
end

