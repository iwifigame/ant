local ecs = ...
local world = ecs.world

local Statics = require("statics")

local mathpkg = import_package "ant.math"
local ms = mathpkg.stack
local mu = mathpkg.util

ecs.import 'ant.basic_components'
ecs.import 'ant.render'
ecs.import 'ant.editor'
ecs.import 'ant.inputmgr'
ecs.import 'ant.serialize'
ecs.import 'ant.scene'
ecs.import 'ant.timer'
ecs.import 'ant.bullet'
ecs.import 'ant.animation'
ecs.import 'ant.event'
ecs.import 'ant.objcontroller'
ecs.import 'ant.math.adapter'

local renderpkg = import_package 'ant.render'
local renderutil=renderpkg.util
local lu = renderpkg.light
 
local unitySceneMaker = require "unitySceneMaker"

local scene_walker = ecs.system 'scene_walker'

scene_walker.dependby 	'render_system'
scene_walker.dependby 	'primitive_filter_system'
scene_walker.dependby 	'camera_controller'
scene_walker.depend 	'timesystem'


function scene_walker:init()
	renderutil.create_main_queue(world, world.args.fb_size, ms({1, 1, -1}, "inT"), {5, 50, 5})
    do
        -- 255,209,172
        lu.create_directional_light_entity(world, 'directional_light',{1,0.81*0.70,0.67*0.6,0}, 5.5, mu.to_radian {-220,-235,0,0} )     --{1,0.81,0.67,0}
        lu.create_ambient_light_entity(world, 'ambient_light', 'gradient', {1, 1, 1, 1})
    end
   
    -- allscene.lua 13500000
    -- spaceship_a_crashed.lua    90000
    -- spaceship_background_a.lua 10000
    -- fpsscene.lua 280000
    -- buildingc_scene.lua
    -- sample.lua
    unitySceneMaker.create(world,"/pkg/unity_viking/assets/scene/viking_glb.lua") 

    --computil.create_grid_entity(world, 'grid', 64, 64, 1)

end

function scene_walker:update()

    -- local deltaTime =  timer.deltatime
    -- print("deltaTime",deltaTime)

	-- local camera_entity = world:first_entity("main_queue")
	-- local camera = camera_entity.camera

    -- local pos = ms(camera.eyepos,"T")
    -- print("camera :",string.format("%08.4f",pos[1]), string.format("%08.4f",pos[2]),string.format("%08.4f",pos[3]) )

    -- 注意屏蔽，简单统计测试函数，影响效率
    -- Statics.reset()
    -- Statics.collect(world)
    -- Statics.print()

end 