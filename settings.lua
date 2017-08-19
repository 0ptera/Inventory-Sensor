data:extend({
  {  
    type = "int-setting",
    name = "inv_sensor_update_interval",
    order = "aa",
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 1,
  },
  {
    type = "int-setting",
    name = "inv_sensor_find_entity_interval",
    order = "ab",
    setting_type = "runtime-global",
    default_value = 120,
    minimum_value = 1,
  },
	{
    type = "double-setting",
    name = "inv_sensor_BBox_offset",
    order = "ad",
    setting_type = "runtime-global",
		default_value = 0.2,
  },
  {
    type = "double-setting",
    name = "inv_sensor_BBox_range",
    order = "ac",
    setting_type = "runtime-global",
		default_value = 1.5,
  },
})