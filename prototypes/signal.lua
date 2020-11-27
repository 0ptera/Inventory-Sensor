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
    order = "is-ba"
  },
  {
    type = "virtual-signal",
    name = "inv-sensor-temperature",
    icon = "__Inventory Sensor__/graphics/icons/temperature.png",
    icon_size = 32,
    subgroup = "sensor-signals",
    order = "is-bb"
  },
  {
    type = "virtual-signal",
    name = "inv-sensor-fuel",
    icon = "__Inventory Sensor__/graphics/icons/fuel.png",
    icon_size = 32,
    subgroup = "sensor-signals",
    order = "is-bc"
  },
  {
    type = "virtual-signal",
    name = "inv-sensor-detected-car",
    icons = {
      { icon = "__base__/graphics/icons/signal/signal_green.png", icon_size = 64, icon_mipmaps = 4 },
      { icon = "__base__/graphics/icons/car.png", icon_size = 64, icon_mipmaps = 4, scale = 0.375 },
    },
    subgroup = "sensor-signals",
    order = "is-da"
  },
  {
    type = "virtual-signal",
    name = "inv-sensor-detected-tank",
    icons = {
      { icon = "__base__/graphics/icons/signal/signal_green.png", icon_size = 64, icon_mipmaps = 4 },
      { icon = "__base__/graphics/icons/tank.png", icon_size = 64, icon_mipmaps = 4, scale = 0.375 },
    },
    subgroup = "sensor-signals",
    order = "is-db"
  },
  {
    type = "virtual-signal",
    name = "inv-sensor-detected-spider",
    icons = {
      { icon = "__base__/graphics/icons/signal/signal_green.png", icon_size = 64, icon_mipmaps = 4 },
      { icon = "__base__/graphics/icons/spidertron.png", icon_size = 64, icon_mipmaps = 4, scale = 0.375 },
    },
    subgroup = "sensor-signals",
    order = "is-dc"
  },
  {
    type = "virtual-signal",
    name = "inv-sensor-detected-wagon",
    icons = {
      { icon = "__base__/graphics/icons/signal/signal_green.png", icon_size = 64, icon_mipmaps = 4 },
      { icon = "__base__/graphics/icons/cargo-wagon.png", icon_size = 64, icon_mipmaps = 4, scale = 0.375 },
    },
    subgroup = "sensor-signals",
    order = "is-dd"
  },
  {
    type = "virtual-signal",
    name = "inv-sensor-detected-locomotive",
    icons = {
      { icon = "__base__/graphics/icons/signal/signal_green.png", icon_size = 64, icon_mipmaps = 4 },
      { icon = "__base__/graphics/icons/locomotive.png", icon_size = 64, icon_mipmaps = 4, scale = 0.375 },
    },
    subgroup = "sensor-signals",
    order = "is-dc"
  }
})