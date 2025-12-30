# 7-Day Jam Scope

## Priority: Two-World Loop First
Get dual worlds working → portals connecting them → essence harvesting in Human World → threat escalation → military invasion of Dark World.

## Day-by-Day Targets

### Days 1-2: Foundation (DONE)
- [x] Project setup, autoloads
- [x] Dual-world TileMap generation (same terrain, different visuals)
- [x] Corruption spread mechanic (per-world)
- [x] Basic HUD showing essence/corruption/threat
- [x] Portal system (place, link, travel between worlds)
- [x] Fog of war (per-world)
- [x] Bottom toolbar (Buildings, Orders, Evolve)

### Days 3-4: Entities & Resources
- [ ] Civilian scene (wander in Human World, flee from Dark Lord)
- [ ] Animal scene (wander in Human World, essence source)
- [ ] Kill mechanic: Dark Lord/minions kill → essence gain
- [ ] Dark World resource scarcity (limited passive income)
- [ ] Human World resource abundance (entities to harvest)

### Days 5-6: Combat & Threat
- [ ] Minion spawning (from Spawning Pit or toolbar)
- [ ] Basic minion AI (follow, attack, defend)
- [ ] Police spawn at low threat (Human World)
- [ ] Military spawn at medium threat (Human World)
- [ ] Special forces spawn at high threat (enter Dark World!)
- [ ] Military portal system (AI opens portals at high threat)
- [ ] Corruption cleansing (special forces remove Dark World corruption)

### Day 7: Win/Lose & Polish
- [ ] Win screen at 100% Human World corruption
- [ ] Lose screen if Dark Lord dies
- [ ] Lose screen if all Dark World corruption cleansed
- [ ] Balance tuning (threat escalation speed, resource rates)
- [ ] Sound effects (optional)
- [ ] Title screen (optional)

## Minimum Viable Product
1. Two worlds with same terrain, different visuals
2. Portal travel between worlds
3. Essence that flows from Human World harvesting
4. Spawnable minions
5. Killable civilians/animals for essence
6. Threat escalation with military response
7. Military invasion of Dark World at high threat
8. Win at 100% Human corruption / Lose if Dark Lord dies or corruption wiped

## Cut If Running Out of Time
- Evolution system (just use essence for everything)
- Special humans/items (just civilians and animals)
- Multiple minion types (just use Crawler)
- Corruption cleansing (military just fights, doesn't cleanse)
- Military portals (military spawns in Human World only)
- Animals (just civilians)
- Sound/music
- Menus

## Stretch Goals (Post-Jam)
- Evolution tree for Dark Lord
- Special humans with unique abilities to consume
- Special items scattered in Human World
- Building upgrades
- Multiple maps/biomes
- Save/load
- Advanced AI behaviors
- Possession mechanic (convert humans to minions)

## Core Loop Summary
```
Dark World (limited resources)
       ↓ open portal
Human World (harvest essence, raises threat)
       ↓ threat rises
Military invades Dark World
       ↓ defend + expand
Race to 100% corruption before overwhelmed
```
