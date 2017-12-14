local inv_sensor = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
inv_sensor.name = "item-sensor"
inv_sensor.icon = "__Inventory Sensor__/graphics/icons/inventory-sensor.png"
inv_sensor.icon_size = 32
inv_sensor.minable.result = "item-sensor"

inv_sensor.sprites =
{
  north =
  {
    filename = "__Inventory Sensor__/graphics/entity/inventory-sensor.png",
    x = 158,
    y = 5,
    width = 79,
    height = 63,
    frame_count = 1,
    shift = {0.140625, 0.140625},
  },
  east =
  {
    filename = "__Inventory Sensor__/graphics/entity/inventory-sensor.png",
    y = 5,
    width = 79,
    height = 63,
    frame_count = 1,
    shift = {0.140625, 0.140625},
  },
  south =
  {
    filename = "__Inventory Sensor__/graphics/entity/inventory-sensor.png",
    x = 237,
    y = 5,
    width = 79,
    height = 63,
    frame_count = 1,
    shift = {0.140625, 0.140625},
  },
  west =
  {
    filename = "__Inventory Sensor__/graphics/entity/inventory-sensor.png",
    x = 79,
    y = 5,
    width = 79,
    height = 63,
    frame_count = 1,
    shift = {0.140625, 0.140625},
  }
}

inv_sensor.item_slot_count = 1000
    
    
data:extend({ inv_sensor })