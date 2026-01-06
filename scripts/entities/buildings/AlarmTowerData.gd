extends RefCounted
## Alarm Tower configuration - entity-specific values (non-balance)
## Use preload pattern: const Data := preload("res://scripts/entities/buildings/AlarmTowerData.gd")
##
## Alarm towers are human buildings that civilians flee toward when threatened.
## When triggered, they increase threat level and attract nearby enemies.

const NAME := "Alarm Tower"
const DESCRIPTION := "Human defense structure - civilians trigger to raise alarm"

const SPRITE_PATH := "res://assets/sprites/buildings/alarm_tower.png"
const COLLISION_RADIUS := 8.0
const SPRITE_SIZE_RATIO := 1.5

# Trigger area - civilians entering this range can trigger the alarm
const TRIGGER_RADIUS := 20.0  # Pixels - area where civilians can activate

# Cooldown between alarms (prevents spam)
const ALARM_COOLDOWN := 30.0  # Seconds before tower can be triggered again

# Visual feedback
const ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 1.0)  # Normal state
const ALARM_COLOR := Color(1.0, 0.3, 0.3, 1.0)   # Flashing when triggered
const COOLDOWN_COLOR := Color(0.5, 0.5, 0.5, 1.0)  # Grayed out during cooldown
const ALARM_FLASH_DURATION := 0.5  # Seconds for alarm flash animation
