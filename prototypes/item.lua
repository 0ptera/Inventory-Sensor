data:extend({
  {
    type = "item",
    name = "item-sensor",
    icon = "__Inventory Sensor__/graphics/icons/inventory-sensor.png",
    icon_size = 32,
    flags = { "goes-to-quickbar" },
    subgroup = "circuit-network",
    place_result="item-sensor",
    order = "c[combinators]-d[item-sensor]",
    stack_size= 50,
  }
})
