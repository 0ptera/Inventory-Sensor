data:extend({
  {
    type = "item-subgroup",
    name = "circuit-network-2",
    group = "logistics",
    order = data.raw["item-subgroup"]["circuit-network"].order.."2"
  },
  {
    type = "item",
    name = "item-sensor",
    place_result="item-sensor",
    icon = "__Inventory Sensor__/graphics/icons/inventory-sensor.png",
    icon_size = 32,
    subgroup = "circuit-network-2",
    order = "is-a",
    stack_size= 50,
  }
})
