data:extend({
  {
    type = "recipe",
    name = "item-sensor",
    icon = "__Inventory Sensor__/graphics/icons/inventory-sensor.png",
    icon_size = 32,
    enabled = false,
    ingredients =
    {
      { type = 'item', name = "copper-cable", amount = 5 },
      { type = 'item', name = "electronic-circuit", amount = 5 },
    },
    results =
    {
      { type = 'item', name = "item-sensor", amount = 1 },
    },
  }
})
