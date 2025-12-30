# Game Design Document

## Core Concept

**Two parallel maps** - Dark World and Human World. Same terrain, different states. You are the Dark Lord trying to corrupt the Human World from the Dark World.

**Key tension:** You must expand into Human World to gather resources, but this raises threat level. At high threat, military invades YOUR Dark World. You can't hide forever.

## The Two Worlds

### Dark World (Corrupted World)
- Where Dark Lord spawns
- Same terrain as Human World but lifeless, corrupted aesthetic
- **Limited starting resources** - forces expansion
- Corruption spreads here first
- **NOT a safe haven** - military can invade at high threat

### Human World
- Normal world with civilians, military, animals, special beings
- **Resources abundant** (humans, animals = essence)
- Military defends, threat level rises with corruption
- Special forces can enter Dark World and cleanse corruption

## Portal System (Two-Way)

### Dark Lord Portals
- Open where corruption exists in Dark World
- Strategic placement choice (forest = safe, city = risky but resource-rich)
- Can close portals to retreat
- Require essence to place

### Military Portals (AI-Controlled)
- At high threat levels, military opens their OWN portals
- Spawn **dynamically near player corruption** (not fixed locations)
- Dark Lord **cannot prevent** military portal placement
- Military invades Dark World to cleanse corruption
- Closing your portals doesn't make you safe

**This creates key tension:**
- Low threat → You control portal locations
- High threat → Military forces entry on THEIR terms
- Can't turtle in Dark World forever

## Resources

### Essence
- **Starting:** 100
- **Dark World income:** Limited (forces expansion to Human World)
- **Human World income:**
  - Kill civilians: +10
  - Kill animals: +5
  - Corrupted tiles: +1/tile
  - Corruption nodes: +2/s
  - Possession: +25
- **Drain:** Dark lord upkeep (-2/s), minion upkeep (varies)
- **Depleted = Must harvest or Game Over**

### Evolution Points (Future)
- Consume special humans → Evolution points
- Consume special items → Evolution points
- Used for Dark Lord upgrades/evolution

## Units

### Minions (Player)
| Type    | Cost | Upkeep | Role                    |
|---------|------|--------|-------------------------|
| Crawler | 20   | 1      | Cheap swarm unit        |
| Brute   | 50   | 2      | Tanky front-line        |
| Stalker | 40   | 1      | Fast flanker            |

### Human World Entities
- **Civilians**: Flee, no threat, essence source (+10)
- **Animals**: Wander, no threat, essence source (+5) - extensible for special creatures
- **Police**: Low damage, investigate corruption
- **Military**: Medium damage, patrol and attack
- **Heavy Units**: High damage, armored
- **Special Humans**: Rare, give evolution points

### Dark Lord
- **Strong monster** - can fight enemies directly
- Has HP (not instant death)
- Can engage police/military but should avoid being overwhelmed
- Death = Game Over

### Special Forces (Invade Dark World)
- **Scouts**: Enter at medium threat, report portal locations
- **Cleansers**: Enter at high threat, remove corruption tiles
- **Strike Teams**: Enter at critical threat, hunt Dark Lord

## Buildings

| Building        | Cost | Effect                          |
|-----------------|------|---------------------------------|
| Corruption Node | 50   | +2 essence/s, spreads corruption|
| Spawning Pit    | 100  | Spawn minions, capacity 5       |
| Portal          | 20   | Travel between worlds           |

## Threat Level Escalation

| Level    | Human World Response          | Dark World Response                    |
|----------|-------------------------------|----------------------------------------|
| Low      | Police investigate            | Safe (for now)                         |
| Medium   | Military patrols              | Special forces scout portals           |
| High     | Heavy military deployed       | Military opens own portals, invades    |
| Critical | Full war, all units attack    | Coordinated assault to kill Dark Lord  |

### Threat Triggers
- Corruption percentage in Human World
- Civilians killed
- Military casualties
- Time spent in Human World

## Win/Lose Conditions

### Win
- Corrupt **100%** of Human World

### Lose
- Dark Lord dies
- All corrupted tiles cleansed in Dark World (corruption wiped out)

## Core Strategic Loop

1. **Expand in Dark World** (but limited resources drain)
2. **Open portal strategically** (location matters: safe vs resource-rich)
3. **Harvest Human World** (raises threat level)
4. **Threat rises** → Military invades Dark World
5. **Defend Dark World** while continuing expansion
6. **Race to corrupt everything** before being overwhelmed

## Controls

- **Arrow keys / WASD**: Pan camera
- **Mouse drag**: Pan camera
- **Click tile**: Select/context menu
- **Hotkeys**: 1-3 spawn minions
- **P**: Place portal
- **Tab/World Button**: Switch world view
- **Space**: (Debug) Spread corruption
