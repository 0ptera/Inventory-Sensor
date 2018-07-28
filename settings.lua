data:extend({
  {
    type = "int-setting",
    name = "inv_sensor_update_interval",
    order = "aa",
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 1,
    maximum_value = 216000, -- 1h
  },
  {
    type = "int-setting",
    name = "inv_sensor_find_entity_interval",
    order = "ab",
    setting_type = "runtime-global",
    default_value = 120,
    minimum_value = 1,
    maximum_value = 216000, -- 1h
  },
  {
    type = "bool-setting",
    name = "inv_sensor_read_grid",
    order = "ba",
    setting_type = "runtime-global",
    default_value = true,
  },
	{
    type = "double-setting",
    name = "inv_sensor_BBox_offset",
    order = "ca",
    setting_type = "runtime-global",
		default_value = 0.2,
  },
  {
    type = "double-setting",
    name = "inv_sensor_BBox_range",
    order = "cb",
    setting_type = "runtime-global",
		default_value = 1.5,
  },
})