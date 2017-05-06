data:extend({
  {
    type = "item-subgroup",
    name = "sensor-signals",
    group = "signals",
    order = "x[sensor-signals]"
  },

  {
    type = "virtual-signal",
    name = "home-lrobots",
    icon = "__Inventory Sensor__/graphics/icons/lbot-rdy.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-aa"
  },
  {
    type = "virtual-signal",
    name = "home-crobots",
    icon = "__Inventory Sensor__/graphics/icons/cbot-rdy.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-ac"
  },
  {
    type = "virtual-signal",
    name = "all-lrobots",
    icon = "__Inventory Sensor__/graphics/icons/lbot-all.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-ab"
  },
  {
    type = "virtual-signal",
    name = "all-crobots",
    icon = "__Inventory Sensor__/graphics/icons/cbot-all.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-ad"
  },
  {
    type = "virtual-signal",
    name = "inv-sensor-temperature",
    icon = "__Inventory Sensor__/graphics/icons/temperature.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-ba"
  },
  {
    type = "virtual-signal",
    name = "detected-car",
    icon = "__Inventory Sensor__/graphics/icons/car.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-da"
  },
  {
    type = "virtual-signal",
    name = "detected-tank",
    icon = "__Inventory Sensor__/graphics/icons/tank.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-db"
  },
  {
    type = "virtual-signal",
    name = "detected-wagon",
    icon = "__base__/graphics/icons/cargo-wagon.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-dd"
  },
  {
    type = "virtual-signal",
    name = "detected-locomotive",
    icon = "__base__/graphics/icons/diesel-locomotive.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-dc"
  }
})