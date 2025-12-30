# Game Design Document

## Concept
Play as a dark lord spreading corruption across a city. Real-time strategy with resource management.

## Core Loop
1. Corruption spreads from your portal
2. Corrupted tiles generate essence (resource)
3. Spend essence to spawn minions and build structures
4. Minions fight humans/military resistance
5. Win at 80% corruption, lose if essence hits 0

## Resources

### Essence
- Starting: 100
- Income: Corrupted tiles (+1/tile), corruption nodes (+2), kills (+10), possessions (+25)
- Drain: Dark lord upkeep (-2/s), minion upkeep (varies)
- Depleted = Game Over

## Units

### Minions (Player)
| Type    | Cost | Upkeep | Role                    |
|---------|------|--------|-------------------------|
| Crawler | 20   | 1      | Cheap swarm unit        |
| Brute   | 50   | 2      | Tanky front-line        |
| Stalker | 40   | 1      | Fast, flanker           |

### Enemies (AI)
- **Civilians**: Flee, no threat
- **Police**: Low damage, appear at 20% corruption
- **Military**: Medium damage, appear at 40%
- **Heavy Units**: High damage, appear at 60%

## Buildings

| Building        | Cost | Effect                          |
|-----------------|------|---------------------------------|
| Corruption Node | 50   | +2 essence/s, spreads corruption|
| Spawning Pit    | 100  | Spawn minions, capacity 5       |
| Portal          | 200  | Main base, 500 HP, lose if destroyed |

## Threat Escalation
- 20% corruption: Police respond
- 40% corruption: Military called in
- 60% corruption: Heavy units deployed
- 80% corruption: Victory!

## Controls (Planned)
- Click tile: Select/context menu
- Drag: Camera pan
- Scroll: Zoom (if implemented)
- Hotkeys: 1-3 spawn minions, Space pause
