data:extend({
  {
    type = "recipe",
    name = "item-sensor",
    icon = "__"..MOD_NAME.."__/graphics/icons/inventory-sensor.png",
    enabled = "false",
    ingredients =
    {
      {"constant-combinator", 1},
      {"advanced-circuit", 5}
    },
    result = "item-sensor"
  }
})
