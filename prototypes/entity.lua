local inv_sensor = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
inv_sensor.name = "item-sensor"
inv_sensor.icon = "__Inventory Sensor__/graphics/icons/inventory-sensor.png"
inv_sensor.icon_size = 32
inv_sensor.icon_mipmaps = nil
inv_sensor.minable.result = "item-sensor"
inv_sensor.sprites = make_4way_animation_from_spritesheet(
  { layers =
    {
      {
        scale = 0.5,
        filename = "__Inventory Sensor__/graphics/entity/inventory-sensor.png",
        width = 114,
        height = 102,
        frame_count = 1,
        shift = util.by_pixel(0, 5),
      },
      {
        scale = 0.5,
        filename = "__base__/graphics/entity/combinator/constant-combinator-shadow.png",
        width = 98,
        height = 66,
        frame_count = 1,
        shift = util.by_pixel(8.5, 5.5),
        draw_as_shadow = true,
      },
    },
  })

inv_sensor.item_slot_count = 1000

data:extend({ inv_sensor })