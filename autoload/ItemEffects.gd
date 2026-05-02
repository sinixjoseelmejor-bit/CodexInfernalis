extends Node

# Handles all item trigger effects (on-hit, on-kill, wave-start).
# All functions receive the Player node to read/write its state.
# State (counters, bonus timers) stays on Player; logic lives here.

func on_enemy_hit(player: Node, enemy: Node, dmg: int, is_crit: bool) -> void:
	# vampire_amulet lifesteal (pct)
	var heal := PlayerData.calc_lifesteal(dmg)
	if heal > 0:
		player.hp = mini(player.hp + heal, PlayerData.max_hp)
		_refresh_hp(player)

	# griffe_mephisto: flat lifesteal per hit
	if PlayerData.lifesteal_flat_per_shot > 0:
		player.hp = mini(player.hp + PlayerData.lifesteal_flat_per_shot, PlayerData.max_hp)
		_refresh_hp(player)

	# oeil_gele: every 7th hit slows enemy 40% for 2s
	if PlayerData.item_count("oeil_gele") > 0:
		player._oeil_gele_counter += 1
		if player._oeil_gele_counter >= 7:
			player._oeil_gele_counter = 0
			if is_instance_valid(enemy) and enemy.has_method("slow"):
				enemy.slow(0.4, 2.0)

	# orbe_mana: every 10th hit fires a bonus projectile
	if PlayerData.item_count("orbe_mana") > 0:
		player._orbe_mana_counter += 1
		if player._orbe_mana_counter >= 10:
			player._orbe_mana_counter = 0
			if is_instance_valid(enemy):
				var bonus_dir := ((enemy as Node2D).global_position - (player as Node2D).global_position).normalized()
				player.call_deferred("fire_bonus_bullet", bonus_dir)

	# dague_asmodee: bleed 2 dmg/s for 3s
	if PlayerData.item_count("dague_asmodee") > 0:
		if is_instance_valid(enemy) and enemy.has_method("apply_bleed"):
			enemy.apply_bleed(2, 3.0)

	# marteau_fissure: crit → bleed 2 dmg/s for 3s
	if is_crit and PlayerData.item_count("marteau_fissure") > 0:
		if is_instance_valid(enemy) and enemy.has_method("apply_bleed"):
			enemy.apply_bleed(2, 3.0)

	# amulette_baal: every 3rd hit → 20×stacks dmg to nearest enemy
	if PlayerData.item_count("amulette_baal") > 0:
		player._baal_counter += 1
		if player._baal_counter >= 3:
			player._baal_counter = 0
			player.trigger_baal()


func on_enemy_kill(player: Node) -> void:
	var rage_stacks := PlayerData.item_count("rage_ring")
	if rage_stacks > 0:
		player._enraged    = true
		player._rage_timer = player.RAGE_DURATION + float(rage_stacks - 1) * 1.0

	if PlayerData.item_count("sang_courroux") > 0:
		PlayerData.set_timed_buff("courroux", 5.0)

	if PlayerData.item_count("anneau_phlegethon") > 0:
		PlayerData.set_timed_buff("phlegethon_speed", 3.0)

	if PlayerData.item_count("talisman_ire") > 0:
		player._ire_bonus = minf(
			player._ire_bonus + 0.03 * float(PlayerData.item_count("talisman_ire")), 0.30)

	if PlayerData.item_count("chapelet_condamnes") > 0:
		PlayerData.bonus_armor_round = mini(
			PlayerData.bonus_armor_round + 2 * PlayerData.item_count("chapelet_condamnes"), 10)


func on_wave_start(player: Node) -> void:
	if PlayerData.item_count("cor_guerre") > 0:
		player._cor_guerre_active = true
		player._cor_guerre_timer  = player.COR_GUERRE_DUR
	player._oeil_gele_counter  = 0
	player._orbe_mana_counter  = 0
	player._ire_bonus          = 0.0
	player._baal_counter       = 0
	player._stationary_timer   = 0.0
	PlayerData.bonus_armor_round = 0


func _refresh_hp(player: Node) -> void:
	var hud := player.get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_hp(player.hp, PlayerData.max_hp)
	player.hp_changed.emit(player.hp, PlayerData.max_hp)
