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
    icon = "__"..MOD_NAME.."__/graphics/icons/lbot-rdy.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-aa"
  },
  {
    type = "virtual-signal",
    name = "home-crobots",
    icon = "__"..MOD_NAME.."__/graphics/icons/cbot-rdy.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-ac"
  },
  {
    type = "virtual-signal",
    name = "all-lrobots",
    icon = "__"..MOD_NAME.."__/graphics/icons/lbot-all.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-ab"
  },
  {
    type = "virtual-signal",
    name = "all-crobots",
    icon = "__"..MOD_NAME.."__/graphics/icons/cbot-all.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-ad"
  },
  {
    type = "virtual-signal",
    name = "detected-car",
    icon = "__"..MOD_NAME.."__/graphics/icons/car.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-ba"
  },
  {
    type = "virtual-signal",
    name = "detected-tank",
    icon = "__"..MOD_NAME.."__/graphics/icons/tank.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-bb"
  },
  {
    type = "virtual-signal",
    name = "detected-wagon",
    icon = "__base__/graphics/icons/cargo-wagon.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-bd"
  },
  {
    type = "virtual-signal",
    name = "detected-locomotive",
    icon = "__base__/graphics/icons/diesel-locomotive.png",
    subgroup = "sensor-signals",
    order = "x[sensor-signals]-bc"
  }
})