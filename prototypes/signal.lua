data:extend({
  {
    type = "item-subgroup",
    name = "sensor-signals",
    group = "signals",
    order = "x[sensor-signals]"
  },

  {
    type = "virtual-signal",
    name = "inv-sensor-progress",
    icon = "__Inventory Sensor__/graphics/icons/progress.png",
    icon_size = 32,
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-ba"
  },
  {
    type = "virtual-signal",
    name = "inv-sensor-temperature",
    icon = "__Inventory Sensor__/graphics/icons/temperature.png",
    icon_size = 32,
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-bb"
  },
  {
    type = "virtual-signal",
    name = "inv-sensor-detected-car",
    icon = "__Inventory Sensor__/graphics/icons/car.png",
    icon_size = 32,
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-da"
  },
  {
    type = "virtual-signal",
    name = "inv-sensor-detected-tank",
    icon = "__Inventory Sensor__/graphics/icons/tank.png",
    icon_size = 32,
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-db"
  },
  {
    type = "virtual-signal",
    name = "inv-sensor-detected-wagon",
    icon = "__base__/graphics/icons/cargo-wagon.png",
    icon_size = 32,
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-dd"
  },
  {
    type = "virtual-signal",
    name = "inv-sensor-detected-locomotive",
    icon = "__base__/graphics/icons/diesel-locomotive.png",
    icon_size = 32,
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-dc"
  }
})