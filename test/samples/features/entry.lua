local runtime = import_package "ant.imguibase".runtime
runtime.start {
	policy = {
		"ant.animation|animation",
		"ant.animation|state_machine",
		"ant.animation|ozzmesh",
		"ant.animation|ozz_skinning",
		"ant.animation|skinning",
		"ant.serialize|serialize",
		"ant.bullet|collider",
		"ant.bullet|collider.character",
		"ant.sky|procedural_sky",
		"ant.render|name",
		"ant.render|mesh",
		"ant.render|shadow_cast",
		"ant.render|render",
		"ant.render|bounding_draw",
		"ant.render|debug_mesh_bounding",
		"ant.render|light.directional",
		"ant.render|light.ambient",
		"ant.scene|hierarchy",
		"ant.scene|ignore_parent_scale",
		--editor
		"ant.test.features|character",
		"ant.objcontroller|select",
	},
	system = {
		"ant.test.features|init_loader",
	},
	pipeline = {
		{ name = "init",
			"init",
			"init_blit_render",
			"post_init",
		},
		{ name = "update",
			"start",
			"timer",
			"data_changed",
			"scene_update",
			{name = "collider",
				"update_collider_transform",
				"update_collider",
				"raycast",
				{name = "character",
					"character_height",
					"character_ik_target",
				}
			},
			{ name = "animation",
				"animation_state",
				"update_animation_data",
				"sample_animation_pose",
				"skin_mesh",
			},
			{ name = "sky",
				"update_sun",
				"update_sky",
			},
			
			"widget",
			{ name = "render",
				"shadow_camera",
				"load_render_properties",
				"filter_primitive",
				"make_shadow",
				"debug_shadow",
				"cull",
				"render_commit",
				{ name = "postprocess",
					"bloom",
					"tonemapping",
					"combine_postprocess",
				}
			},
			-- editor
			"camera_control",
			"lock_target",
			"pickup",
			"update_editable_hierarchy",
			{ name = "ui",
				"ui_start",
				"ui_update",
				"ui_end",
			},
			"end_frame",
			"final",
		},
	}
}
