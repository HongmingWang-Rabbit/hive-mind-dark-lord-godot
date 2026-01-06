extends RefCounted
## Military Portal configuration - human military gateway
## Use preload pattern: const Data := preload("res://scripts/entities/buildings/MilitaryPortalData.gd")
##
## Military portals spawn when threat level >= 70%.
## Enemies walk through to invade the Corrupted World.
## Player cannot close or destroy these portals.

const NAME := "Military Portal"
const DESCRIPTION := "Human military gateway to invade Corrupted World"

const SPRITE_PATH := "res://assets/sprites/buildings/military_portal_gate.png"
const COLLISION_RADIUS := 10.0
const TRAVEL_TRIGGER_RADIUS := 14.0  # Larger than collision for easier entry
const SPRITE_SIZE_RATIO := 2.0

# Visual state
const ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
