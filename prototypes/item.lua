data:extend({
  {
    type = "item",
    name = "item-sensor",
    icon = "__Inventory Sensor__/graphics/icons/inventory-sensor.png",
    flags = { "goes-to-quickbar" },
    subgroup = "circuit-network",
    place_result="item-sensor",
    order = "b[combinators]-c[item-sensor]",
    stack_size= 50,
  }
})
