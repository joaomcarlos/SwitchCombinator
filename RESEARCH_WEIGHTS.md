# Factorio Space Age — Research Cost-Efficiency Weight Table

> Compiled from the official Factorio Wiki & community breakpoints.  
> Use these weights to bias a research-queue mod (e.g. awesome-rqm) toward high-ROI technologies instead of blindly following the tree order.

---

## How to read the table

| Column | Meaning |
|--------|---------|
| **Weight** | Relative priority boost. `+10` = extremely high ROI, `-5` = avoid unless forced. |
| **Breakpoint** | Specific level where a massive practical benefit kicks in. Research *to* this level, then deprioritize. |
| **Cap Level** | Level where 300 % productivity cap (or other hard cap) is hit → further levels are wasted. |
| **ROI Note** | Why this tech is (or isn't) cost-efficient. |

---

## S-Tier (game-changing ROI)

| Technology | Weight | Breakpoint | Cap Level | ROI Note |
|------------|--------|------------|-----------|----------|
| **Transport belt capacity** | `+10` | L1 (stack 2) → L2 (stack 3) → L3 (stack 4) | L3 | **Each level doubles belt throughput.** L1 is gated by Stack inserter research. L2 and L3 are two of the cheapest ways to 2×/4× your entire belt network. |
| **Processing unit productivity** | `+9` | **L13**: EM plants hit 300 % cap *with* legendary prod modules<br>**L25**: EM plants hit 300 % cap *without* modules | L25 | Blue circuits are used everywhere (modules, rockets, science). L25 lets you run bare EM plants at max productivity — no modules needed, massive power/space savings. |
| **Research productivity** | `+9` | Every level | None (infinite) | **Compounding returns.** +10 % lab productivity per level. The only research that uses Promethium science. Makes *every* future research cheaper. Highest long-term ROI. |
| **Mining productivity** | `+8` | **L50**: 1 big drill saturates one side of turbo belt (scrap)<br>**L110**: full turbo belt (scrap)<br>**L230**: full turbo belt (normal ores)<br>**L590**: one side turbo belt (tungsten)<br>**L1190**: full turbo belt (tungsten) | None (uncapped) | Bonus ore is **free** — it does not deplete patches. Also cheaper in Space Age (no utility/space science required). |

---

## A-Tier (very strong ROI)

| Technology | Weight | Breakpoint | Cap Level | ROI Note |
|------------|--------|------------|-----------|----------|
| **Rocket part productivity** | `+7` | **L20**: Rocket silos hit 300 % cap *with* legendary prod modules<br>**L30**: Rocket silos hit 300 % cap *without* modules | L30 | Rocket parts are expensive and needed for Space Platform science. Removing module requirement at L30 is huge for megabases. |
| **Low density structure productivity** | `+7` | **L15**: Foundries hit 300 % cap *with* legendary prod modules<br>**L25**: Foundries hit 300 % cap *without* modules | L25 | LDS is rocket-part feedstock. L25 means zero-module foundries at max productivity. |
| **Steel plate productivity** | `+6` | **L15**: Foundries hit 300 % cap *with* legendary prod modules<br>**L25**: Foundries hit 300 % cap *without* modules | L25 | Steel is consumed in enormous quantities. Foundries already have +50 % base productivity, so the cap comes quickly. |
| **Plastic bar productivity** | `+6` | **L10**: Cryogenic plants hit cap *with* legendary modules<br>**L15**: Biochambers hit cap *with* legendary modules<br>**L25**: Biochambers hit cap *without* modules<br>**L30**: Cryogenic plants hit cap *without* modules | L30 | Plastic is needed for circuits & rocket fuel. L30 is the true no-module breakpoint for cryogenic plants. |
| **Rocket fuel productivity** | `+6` | Same breakpoints as Plastic bar productivity | L30 | Rocket fuel is needed for rockets, flamethrower ammo, and some science. Same cap curve as plastic. |
| **Scrap recycling productivity** | `+5` | — | None (infinite) | Fulgora-specific. Higher levels = more free material from scrap. Linear cost, so always decent ROI while on Fulgora. |
| **Asteroid productivity** | `+5` | — | None (infinite) | Space-platform-specific. More ore per asteroid chunk. Pays for itself quickly if you do any serious space manufacturing. |

---

## B-Tier (good ROI, situational)

| Technology | Weight | Breakpoint | Cap Level | ROI Note |
|------------|--------|------------|-----------|----------|
| **Physical projectile damage** | `+4` | **L1**: Gun turrets kill basic biters in 3 shots (was 4) | Infinite | L1 alone saves a massive amount of iron on magazines. Beyond L1 the benefit is incremental combat stats. |
| **Stronger explosives** | `+4` | **L2**: Grenades one-shot trees<br>**L7**: Rockets one-shot medium asteroids<br>**L12**: Rockets two-shot large asteroids<br>**L16**: Explosive rockets two-shot large asteroids | Infinite | Asteroid breakpoints save huge amounts of ammunition on space platforms. |
| **Worker robot speed** | `+4` | Finite levels up to L6, then infinite | Infinite | Bot speed is the #1 logistics throughput stat. Finite levels are cheap; infinite levels add electromagnetic science and are still worthwhile for bot-heavy bases. |
| **Laser weapons damage** | `+3` | **L11**: Laser turrets one-cycle small asteroids | Infinite | Only matters if you rely on laser turrets for platform defense. |
| **Railgun damage** | `+3` | — | Infinite | Railguns are the best anti-asteroid weapon late-game. Damage scales well, but no hard breakpoints known. |
| **Follower robot count** | `+2` | — | Infinite | Only relevant if you use combat robots. Linear cost increase. |
| **Refined flammables** | `+2` | — | Infinite | Flamethrower turret fuel. Niche unless you base defend with flame. |
| **Energy weapons damage** (now split) | `+2` | — | Infinite | Covers personal laser defense & electric weapons. Niche unless you use Tesla guns. |

---

## C-Tier / Deprioritize (low ROI or hard-capped early)

| Technology | Weight | Breakpoint | Cap Level | ROI Note |
|------------|--------|------------|-----------|----------|
| **Artillery shell shooting speed** | `-3` | L10 hits animation cap (0.845 shots/sec) | L10 | **Beyond L10 is literally useless** — the railgun/artillery animation cannot cycle faster. The mod should cap or deprioritize this. |
| **Artillery shell range** | `-2` | — | Infinite | Artillery is already enormous. Extra range is nice but very expensive for marginal convenience. |
| **Artillery shell damage** | `-2` | — | Infinite | Artillery one-shots most things already. More damage is overkill. |
| **Health** | `-1` | — | Infinite | Nice for personal survivability, but does not help factory throughput. |
| **Character inventory size** | `+1` | — | Finite | QoL only. Low weight because it does not affect factory output. |
| **Character build distance / reach** | `+1` | — | Finite | QoL only. |
| **Toolbelt** | `+1` | — | Finite | QoL only (extra quickbar rows). |

---

## Important clarifications

### “Circuit research up to level 30”
The research that affects blue circuits (Processing Units) is **Processing unit productivity**.
- **Level 13** = 300 % cap when using legendary productivity modules in Electromagnetic plants.
- **Level 25** = 300 % cap with **no modules at all**.

There is **no practical benefit past L25** for Processing units.  
The **Level 30** no-module cap applies to **Plastic bar productivity** and **Rocket fuel productivity** in Cryogenic plants, not Processing units. If your source said “circuits L30,” they may have been referring to Plastic (which feeds circuits) or conflating the two.

### Productivity cap math
All productivity bonuses are additive and clamped at **300 %**:
- Electromagnetic plants have **+50 % base productivity**.
- 5 legendary Productivity module 3s = **+125 %** (5 × 25 %).
- Base + modules = **175 %**.
- You need **+125 %** from research to hit 300 %.  
  Processing unit productivity gives **+10 % per level** → **13 levels** = 130 % (enough).
- Without modules, you need the full **+250 %** from research alone → **25 levels**.

### Research productivity is the true endgame king
Once you unlock Promethium science, every level of Research productivity makes *every other research* cheaper. It is the only research with compounding, cross-cutting ROI. If you can only run one infinite research late-game, make it this one.

---

## Example weight-based heuristic (pseudo-code)

```lua
function get_research_weight(tech_name, current_level)
    local weights = {
        ["transport-belt-capacity"] = 10,
        ["processing-unit-productivity"] = 9,
        ["research-productivity"] = 9,
        ["mining-productivity"] = 8,
        ["rocket-part-productivity"] = 7,
        ["low-density-structure-productivity"] = 7,
        ["steel-plate-productivity"] = 6,
        ["plastic-bar-productivity"] = 6,
        ["rocket-fuel-productivity"] = 6,
        ["scrap-recycling-productivity"] = 5,
        ["asteroid-productivity"] = 5,
        ["physical-projectile-damage"] = 4,
        ["stronger-explosives"] = 4,
        ["worker-robot-speed"] = 4,
        -- ... etc
    }

    -- Cap/zero-out useless levels
    if tech_name == "artillery-shell-shooting-speed" and current_level >= 10 then
        return -10  -- hard animation cap, never research
    end
    if tech_name == "processing-unit-productivity" and current_level >= 25 then
        return -10  -- 300 % cap reached
    end
    if tech_name == "rocket-part-productivity" and current_level >= 30 then
        return -10
    end
    -- ... etc for other capped researches

    return weights[tech_name] or 0
end
```

---

## Data sources
- [Factorio Wiki — Technologies/Infinite technologies](https://wiki.factorio.com/Technologies)
- [Factorio Wiki — Processing unit productivity](https://wiki.factorio.com/Processing_unit_productivity_(research))
- [Factorio Wiki — Research productivity](https://wiki.factorio.com/Research_productivity_(research))
- [Factorio Wiki — Mining productivity](https://wiki.factorio.com/Mining_productivity_(research))
- [Factorio Wiki — Transport belt capacity](https://wiki.factorio.com/Transport_belt_capacity_(research))
- [Factorio Wiki — Electromagnetic plant](https://wiki.factorio.com/Electromagnetic_plant)
- [Factorio Wiki — Productivity](https://wiki.factorio.com/Productivity)
