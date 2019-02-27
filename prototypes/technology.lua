data:extend({
  {
    type = "technology",
    name = "item-detection",
    icon = "__Inventory Sensor__/graphics/tech/inventory-sensor.png",
    icon_size = 64,
    prerequisites = {"circuit-network", "advanced-electronics"},
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "item-sensor"
      }
    },
    unit =
    {
      count = 100,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1}
      },
      time = 30
    },
    order = "d-a-a"
  }
})
