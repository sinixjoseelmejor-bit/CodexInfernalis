extends Node

# Decoupled input state for touch/gamepad abstract input.
# Written by TouchControls, read by Player — PlayerData stays data-only.

var touch_move        : Vector2 = Vector2.ZERO
var touch_aim_world   : Vector2 = Vector2.ZERO
var touch_shooting    : bool    = false
