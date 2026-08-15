---
title: Factorio Modding — Vanilla Reference Tables
description: Quick lookup tables for vanilla Factorio 2.0 entity names, item names, and technology names.
---

# Factorio Modding — Vanilla Reference Tables

Use this skill as a quick lookup for vanilla prototype names. Always verify with the actual game or API docs if unsure.

These tables are convenience hints, not authoritative version data. Treat the official [Factorio Data repository](https://github.com/wube/factorio-data) as the source of truth for versioned Lua prototype definitions and vanilla names: inspect the branch, tag, or release matching the target Factorio version before relying on an entry. Use the official API docs for runtime contracts and the live game for final validation.

---

## Entity Names

### Production
```
assembling-machine-1, assembling-machine-2, assembling-machine-3,
stone-furnace, steel-furnace, electric-furnace,
chemical-plant, oil-refinery, centrifuge,
rocket-silo
```

### Mining & Resources
```
burner-mining-drill, electric-mining-drill,
pumpjack, offshore-pump
```

### Power
```
boiler, steam-engine, steam-turbine, nuclear-reactor,
heat-exchanger, heat-pipe, solar-panel, accumulator,
small-electric-pole, medium-electric-pole, big-electric-pole,
substation, power-switch
```

### Logistics
```
transport-belt, fast-transport-belt, express-transport-belt,
underground-belt, fast-underground-belt, express-underground-belt,
splitter, fast-splitter, express-splitter,
inserter, fast-inserter, long-handed-inserter,
stack-inserter, stack-filter-inserter,
filter-inserter, burner-inserter,
pipe, pipe-to-ground, pump, storage-tank
```

### Combat
```
gun-turret, laser-turret, flamethrower-turret, artillery-turret,
land-mine, wall, gate,
radar
```

### Circuit Network
```
constant-combinator, decider-combinator, arithmetic-combinator,
selector-combinator, small-lamp, programmable-speaker,
display-panel
```

### Vehicles
```
car, tank, locomotive, cargo-wagon, fluid-wagon,
artillery-wagon, spidertron
```

### Robots
```
construction-robot, logistic-robot, roboport
```

### Space Age (2.0)
```
asteroid-collector, agricultural-tower, cargo-bay,
cargo-landing-pad, space-platform-hub,
thruster, fusion-reactor, fusion-generator,
lightning-attractor, cargo-pod
```

### Chests
```
wooden-chest, iron-chest, steel-chest,
active-provider-chest, passive-provider-chest,
storage-chest, requester-chest, buffer-chest
```

---

## Item Names

### Raw Materials
```
iron-ore, copper-ore, coal, stone, uranium-ore,
iron-plate, copper-plate, steel-plate, stone-brick,
wood, raw-fish
```

### Intermediates
```
iron-gear-wheel, copper-cable, electronic-circuit,
advanced-circuit, processing-unit, battery,
plastic-bar, sulfur, solid-fuel, rocket-fuel,
low-density-structure, rocket-control-unit,
speed-module, speed-module-2, speed-module-3,
productivity-module, productivity-module-2, productivity-module-3,
effectivity-module, effectivity-module-2, effectivity-module-3,
quality-module, quality-module-2, quality-module-3
```

### Science Packs (Tools)
```
automation-science-pack, logistic-science-pack,
military-science-pack, chemical-science-pack,
production-science-pack, utility-science-pack,
space-science-pack, metallurgic-science-pack,
electromagnetic-science-pack, agricultural-science-pack,
biological-science-pack, cryogenic-science-pack,
promethium-science-pack
```

### Fluids (Bucket Items)
```
water-barrel, crude-oil-barrel, lubricant-barrel,
heavy-oil-barrel, light-oil-barrel, petroleum-gas-barrel,
sulfuric-acid-barrel
```

### Ammo
```
firearm-magazine, piercing-rounds-magazine, uranium-rounds-magazine,
shotgun-shell, piercing-shotgun-shell, uranium-shotgun-shell,
rocket, explosive-rocket, atomic-bomb,
cannon-shell, explosive-cannon-shell, uranium-cannon-shell,
explosive-uranium-cannon-shell,
artillery-shell, flamethrower-ammo
```

### Armor & Equipment
```
light-armor, heavy-armor, modular-armor, power-armor, power-armor-mk2,
solar-panel-equipment, battery-equipment, battery-mk2-equipment,
energy-shield-equipment, energy-shield-mk2-equipment,
personal-laser-defense-equipment, exoskeleton-equipment,
night-vision-equipment, belt-immunity-equipment,
portable-fusion-reactor, personal-roboport-equipment,
personal-roboport-mk2-equipment
```

---

## Technology Names

### Early Game
```
automation, automation-2, automation-3,
logistics, logistics-2, logistics-3,
optics, electronics, advanced-electronics, advanced-electronics-2,
military, military-2, military-3, military-4,
stone-brick, sulfur-processing, plastics
```

### Power
```
steam-power, nuclear-power, uranium-processing,
kovarex-enrichment-process, fusion-reactor
```

### Oil & Chemistry
```
oil-processing, advanced-oil-processing, coal-liquefaction,
lubricant, rocket-fuel, low-density-structure,
rocket-silo, space-science-pack
```

### Logistics & Robotics
```
logistic-system, worker-robots-speed-1 through worker-robots-speed-6,
worker-robots-storage-1 through worker-robots-storage-3,
character-logistic-slots-1 through character-logistic-slots-6,
automated-rail-transportation, railway, rail-signals,
fluid-wagon, artillery, spidertron
```

### Mining & Production
```
mining-productivity-1 through mining-productivity-4,
steel-processing, advanced-material-processing,
advanced-material-processing-2, concrete, refined-concrete,
landfill, cliff-explosives
```

### Space Age (2.0)
```
space-platform, asteroid-collecting, cargo-bay,
agricultural-science-pack, electromagnetic-science-pack,
metallurgic-science-pack, cryogenic-science-pack,
promethium-science-pack, biochamber,
asteroid-reprocessing, thruster
```

---

## Fluid Names

```
water, steam, crude-oil, heavy-oil, light-oil, petroleum-gas,
lubricant, sulfuric-acid, molten-iron, molten-copper,
holmium-solution, ammonia, fluoroketone-cold,
fluoroketone-hot, lithium-brine
```

---

## Resource Names

```
iron-ore, copper-ore, coal, stone, uranium-ore,
crude-oil, water, steam
```

---

## Virtual Signal Names

```
signal-each, signal-anything, signal-everything,
signal-A through signal-Z,
signal-red, signal-green, signal-blue, signal-yellow,
signal-cyan, signal-pink, signal-white, signal-grey,
signal-black
```
