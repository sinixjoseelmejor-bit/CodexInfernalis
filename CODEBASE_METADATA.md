# Codex Inferno — Complete Codebase Metadata

**Project**: Codex Inferno (Godot 4.6)  
**Total .gd files**: 30  
**Last updated**: 2026-04-29  
**Format**: GDScript (Godot 4.0+)

---

## 📋 File Index

**Autoload (1)**
- [autoload/PlayerData.gd](#autoloadplayerdata-522-lines)

**Entities (12)**
- [scenes/entities/Player.gd](#scenesentitieslayergd-682-lines)
- [scenes/entities/BaseEnemy.gd](#scenesentiresbaseenemy-153-lines)
- [scenes/entities/Aldrich.gd](#scenesentiresaldrich-95-lines)
- [scenes/entities/Brutus.gd](#scenesentirebrutus-127-lines)
- [scenes/entities/Booster.gd](#scenesentibooster-100-lines)
- [scenes/entities/Golgota.gd](#scenesentiesgolgota-263-lines)
- [scenes/entities/Bear.gd](#scenesentiiesbear-106-lines)
- [scenes/entities/Fireball.gd](#scenesentiiesfireball-88-lines)
- [scenes/entities/Grenade.gd](#scenesentiiegrenade-56-lines)
- [scenes/entities/Key.gd](#scenesentiieskey-27-lines)
- [scenes/entities/BossSoul.gd](#scenesentiiesbosssoul-25-lines)

**Enemy Projectiles (7)**
- [scenes/entities/BrutusBullet.gd](#scenesentiiebrutusbullet-27-lines)
- [scenes/entities/GolgotaOrb.gd](#scenesentiiesgolgotaorb-36-lines)
- [scenes/entities/GolgotaLaser.gd](#scenesentiiesgolgotalaser-82-lines)
- [scenes/entities/GolgotaShockwave.gd](#scenesentiiesgolgotashockwave-60-lines)
- [scenes/entities/BulletExplosion.gd](#scenesentiiesbulletexplosion-30-lines)
- [scenes/entities/FireTrail.gd](#scenesentiiesfirethrail-34-lines)

**Arena (1)**
- [scenes/arenas/Arena1.gd](#scenesareasarena1-377-lines)

**UI (9)**
- [scenes/ui/TouchControls.gd](#scenesuitouchcontrols-135-lines)
- [scenes/ui/SelectCharacter.gd](#scenesuis selectcharacter-141-lines)
- [scenes/ui/HUD.gd](#scenessuihud-344-lines)
- [scenes/ui/ShopMenu.gd](#scenesuishopmenu-638-lines)
- [scenes/ui/SkillTreeOverlay.gd](#scenesui skillitreeoverlay-355-lines)
- [scenes/ui/MainMenu.gd](#scenessuimainmenu-135-lines)
- [scenes/ui/PauseMenu.gd](#scenessuipausemenu-49-lines)
- [scenes/ui/GameOver.gd](#scenessuigameover-34-lines)
- [scenes/ui/Intro.gd](#scenesuiintro-35-lines)

**Narrative (2)**
- [scenes/ui/StoryIntro.gd](#scenesui storyintro-196-lines)
- [scenes/effects/EffectSprite.gd](#sceneseffectseffectsprite-63-lines)

---

## 📚 Detailed File Documentation

### autoload/PlayerData (522 lines)

**Signals**: None explicit

**Variables**:
- Game state: selected_char, player_level, souls, eternal_souls, victories_total, unlocked_chars
- Item management: items (Array), profile (String)
- Stats: max_hp, damage, speed, fire_cd, armor, crit_chance, crit_multiplier, pickup_range
- Buffs/Debuffs: timed_buffs, temporary_buffs, curses
- Touch input: touch_move (Vector2), touch_aim_world (Vector2), touch_shooting (bool)
- Skill trees: SKILL_TREES dictionary (per-character progression)
- Item database: ITEM_DB (75+ items with rarity, name, description, stat effects)
- Stat tables: BASE_HP_TABLE, BASE_DMG_TABLE, BASE_CD_TABLE (level 1-9)

**Key Functions**:
- _recompute() → void (recalculates all stats from items/base values)
- add_item(item_id: String) → void (adds item to inventory)
- has_item(item_id: String) → bool
- item_count(item_id: String) → int
- remove_item(item_id: String) → void
- has_skill(skill_id: String) → bool
- buy_skill(skill_id: String) → bool (costs resources)
- can_buy_skill(skill_id: String) → bool
- roll_crit() → bool (checks crit chance)
- calc_damage_taken(dmg: int) → int (applies armor/dodge)
- calc_lifesteal(dmg: int) → int
- set_timed_buff(buff_id: String, duration: float) → void
- has_timed_buff(buff_id: String) → bool
- reset_run() → void (clears items for new run)
- reset_char_skills(char_id: String) → void
- save() → void (persists to disk)

**Dependencies**:
- No external scripts (pure data layer)

---

### scenes/entities/Player (682 lines)

**Extends**: CharacterBody2D

**Signals**:
- hp_changed(current: int, maximum: int)
- died

**Variables**:
- State: hp, last_direction, _dead, _attacking, _enraged, _shield_active
- Aiming: _aim_direction, _last_aim_dir, _last_is_crit
- Timers: _fire_timer, _iframe_timer, _rage_timer, _trail_timer, _tempete_timer, _grenade_timer, _corguerre_timer, _lightning_timer, _sceptre_timer, _mercy_cd, _drain_acc
- Item counters: _oeil_gele_counter, _orbe_mana_counter, _baal_counter
- Bonuses: _ire_bonus, _cor_guerre_active, _stationary_timer
- Bear: _active_bear (Node reference)
- Input: _mouse_override_timer, _pending_shot_dir, _waiting_to_shoot

**Key Functions**:
- _setup_animations() → void (builds SpriteFrames for Neophyte)
- _setup_animations_serayne() → void (builds frames for Serayne with AtlasTexture death)
- _get_aim_dir() → Vector2 (touch, mouse, or auto-aim within AUTO_AIM_RANGE=400)
- _effective_damage() → int (applies all damage multipliers and crit)
- _physics_process(delta) → void (movement, attack loop, item timers)
- _shoot() → void (starts attack animation, calls _invoke_bear for Serayne)
- _invoke_bear() → void (spawns bear if Serayne)
- _get_bear_spawn_pos() → Vector2 (returns position 80px from player in aim direction)
- _spawn_bullet(dir, pos) → void (creates Fireball)
- _try_fire_trail(delta) → void (spawns FireTrail if fire_boots equipped)
- _launch_grenade() → void (spawns Grenade targeting nearest enemy)
- _launch_tempete() → void (spawns 12 bullets in circle)
- on_enemy_hit(enemy, dmg, is_crit) → void (applies item on-hit effects)
- on_enemy_kill() → void (applies item on-kill effects: rage, buffs, bonus armor)
- on_wave_start() → void (resets wave-scoped timers and state)
- take_damage(amount) → void (applies armor/dodge, iframe, shield check, reflects)
- revive() → void (resets dead state)
- _die() → void (plays death animation or triggers revive)

**Nodes**:
- $AnimatedSprite2D (character animation)
- $HitArea/$HitShape (damage collision)
- $CollisionShape2D (movement collision)
- Camera2D (dynamically created in _setup_camera)

**Dependencies**:
- PlayerData (autoload)
- Fireball.tscn, Bear.tscn, Grenade.tscn, FireTrail.tscn
- FxLightning.tscn, FxSceptre.tscn

---

### scenes/entities/BaseEnemy (153 lines)

**Extends**: CharacterBody2D

**Signals**:
- died

**Variables**:
- hp, damage, speed, max_hp
- dead, _dead (tracked state)
- grabbed (bool, for freeze mechanic)
- velocity, _velocity_target
- _wander_dir, _wander_timer (with @warning_ignore)
- _bleed_damage, _bleed_duration, _slow_active, _slow_factor, _slow_timer

**Key Functions**:
- _physics_process(delta) → void (checks grabbed flag, returns early if frozen)
- take_damage(amount) → void (subtracts hp, calls _die if hp <= 0)
- apply_bleed(dmg_per_sec, duration) → void (applies damage over time)
- slow(factor, duration) → void (reduces speed temporarily)
- _wander() → void (random movement when idle)
- _die() → void (emits died signal, queues self for deletion)

**Purpose**: Base class for all enemies; grabbed flag prevents movement during bear attack

**Dependencies**:
- PlayerData (autoload)

---

### scenes/entities/Aldrich (95 lines)

**Extends**: BaseEnemy

**Variables**:
- Pathfinding: _path, _path_idx
- Behavior: _attack_timer, _attack_range, _pursuing

**Key Functions**:
- _process(delta) → void (basic melee enemy AI)
- _find_path_to_player() → void (uses NavigationAgent)

**Purpose**: Basic melee enemy that pursues player

---

### scenes/entities/Brutus (127 lines)

**Extends**: BaseEnemy

**Variables**:
- shoot_cd, bullet_speed, shoot_range, shoot_timer
- _pursuing, _attack_pos

**Key Functions**:
- _physics_process(delta) → void (ranged combat)
- _fire_bullet() → void (spawns BrutusBullet)

**Purpose**: Ranged enemy that fires bullets at player from distance

---

### scenes/entities/Booster (100 lines)

**Extends**: BaseEnemy

**Variables**:
- _boost_timer, _boost_target, _boost_speed, _boosting

**Key Functions**:
- _physics_process(delta) → void (charging behavior)
- _boost_to_player() → void (high-speed charge attack)

**Purpose**: Charging enemy with burst attack phase

---

### scenes/entities/Golgota (263 lines)

**Extends**: CharacterBody2D

**Signals**:
- died

**Variables**:
- State: hp, custom_max_hp, damage, laser_damage, dead
- Phase: _phase (3=full, 2=mid, 1=critical)
- Timers: _orb_timer, _laser_timer, _spawn_timer, _spawn_cd, _shockwave_timer
- Behavior: _laser_active, _last_dir, player (Node2D reference)
- Phase-specific: _cur_orb_cd, _cur_laser_cd, _cur_orb_count, _cur_speed, _cur_telegraph

**Key Functions**:
- _physics_process(delta) → void (follows player, triggers attacks)
- _fire_lasers(base_dir) → void (spawns GolgotaLaser instances with spread)
- _spawn_orbs() → void (spawns GolgotaOrb instances in arc)
- _spawn_enemies() → void (spawns Aldrich minions around player)
- _fire_shockwave() → void (phase 1 only, AOE damage)
- _check_phase() → void (transitions difficulty at hp thresholds)
- take_damage(amount) → void (capped at DMG_CAP=60, updates HUD)
- _die() → void (spawns BossSoul, plays death animation)

**Phase Progression**:
- Phase 3 (>66% hp): 5 orbs @ 2.5s, 1 laser @ 6s, speed=35
- Phase 2 (33-66% hp): 8 orbs @ 2.0s, 3 lasers @ 4.5s, spawn minions @ 12s, speed=48
- Phase 1 (<33% hp): 12 orbs @ 1.5s, 5 lasers @ 3.0s, spawn @ 7s, shockwave @ 8s, speed=60

**Special**: Level 20 boss has custom_max_hp=3600, damage=50, laser_damage=40

**Dependencies**:
- GolgotaOrb.tscn, GolgotaLaser.tscn, GolgotaShockwave.gd, BossSoul.tscn, Aldrich.tscn

---

### scenes/entities/Bear (106 lines)

**Extends**: AnimatedSprite2D

**Variables**:
- damage, _is_crit
- _target (Node reference)
- _phase ("idle", "move", "attack")
- _attack_timer

**Key Functions**:
- init(damage: int, is_crit: bool) → void (initialization)
- _build_frames() → void (creates SpriteFrames from spritesheet)
- _slice_sheet(sheet: Texture2D, cols, rows, frame_w, frame_h) → Array (AtlasTexture slicing)
- _find_target() → Node (searches for nearest enemy within RANGE)
- _process(delta) → void (state machine: idle→move→attack)
- _strike() → void (starts attack animation, damages enemies in AOE_RADIUS)
- _deal_tick() → void (AOE damage + grab flag application)
- _on_attack_finished() → void (resets to idle)

**Constants**:
- SPEED=420.0, RANGE=350.0, ATTACK_DIST=60.0, AOE_RADIUS=120.0

**Behavior**:
1. Spawns at position 80px from player in aim direction
2. Idle until target found within RANGE
3. Moves toward target at SPEED
4. Attacks when within ATTACK_DIST
5. Deals damage to enemies in AOE_RADIUS and applies grabbed flag
6. Seized enemies cannot move (_physics_process checks grabbed flag early-return)

**Dependencies**:
- BaseEnemy.gd (checks "grabbed" property on targets)
- Bear.png, bearAttackLeft.PNG, bearAttackRight.png spritesheets

---

### scenes/entities/Fireball (88 lines)

**Extends**: Area2D

**Variables**:
- _velocity, _damage, _is_crit
- _lifetime, _timer
- _trail_timer

**Key Functions**:
- init(direction: Vector2, dmg: int, is_crit: bool) → void
- _process(delta) → void (movement, lifetime, trail spawning)
- _on_area_entered(area) → void (damage hit target, applies crit flash)

**Behavior**:
- Spawned at player position in aim direction
- Moves at constant speed
- Auto-deletes after 8 seconds
- Spawns FireTrail every 0.1 seconds

---

### scenes/entities/Grenade (56 lines)

**Extends**: Node2D

**Variables**:
- _target (Vector2), _timer, _detonate_timer

**Key Functions**:
- init(target: Vector2) → void
- _process(delta) → void (arc motion toward target)
- _detonate() → void (explodes with AOE damage)

**Behavior**:
- Arc trajectory toward target
- Explodes on impact or after 3 seconds
- Spawns BulletExplosion for visuals

---

### scenes/entities/Key (27 lines)

**Extends**: Area2D

**Variables**:
- _spin_angle

**Key Functions**:
- _process(delta) → void (spinning animation)
- _on_body_entered(body) → void (player pickup, arena.add_key())

---

### scenes/entities/BossSoul (25 lines)

**Extends**: Node2D

**Variables**:
- _target, _timer

**Key Functions**:
- _process(delta) → void (floats toward player)
- _on_area_entered() → void (triggers victory when player touches)

**Behavior**: Spawned when boss dies, flies to player position to trigger end-round

---

### scenes/entities/BrutusBullet (27 lines)

**Extends**: Area2D

**Variables**:
- _velocity, _damage, _lifetime

**Key Functions**:
- init(direction, dmg) → void
- _process(delta) → void (movement + lifetime)
- _on_area_entered(area) → void (damage target)

---

### scenes/entities/GolgotaOrb (36 lines)

**Extends**: Area2D

**Variables**:
- _timer, _bob_offset

**Key Functions**:
- _process(delta) → void (floating animation, bob effect)
- _on_area_entered(area) → void (damage + slow player)

**Behavior**: Spawned in arc around Golgota, damages and slows player on contact

---

### scenes/entities/GolgotaLaser (82 lines)

**Extends**: Node2D

**Signals**:
- laser_done

**Variables**:
- _phase ("telegraph", "active"), _timer
- _tracking, _damage, _dir
- _spr (Sprite2D), _area (Area2D)

**Key Functions**:
- init(direction, dmg, telegraph, tracking) → void
- _process(delta) → void (telegraph phase: fades in with optional tracking, then active phase)
- _on_body_entered(body) → void (damage player)

**Behavior**:
- Telegraph phase (default 1.2s): gradually increases opacity, optionally tracks player
- Active phase (0.5s): full opacity, hits applied
- Auto-deletes after active

---

### scenes/entities/GolgotaShockwave (60 lines)

**Extends**: Node2D

**Variables**:
- damage, _expansion, _lifetime, _timer

**Key Functions**:
- _process(delta) → void (expands outward, applies damage to enemies in expanding radius)

**Behavior**: Spawned from Golgota phase 1, expands radially and damages all enemies in range

---

### scenes/entities/BulletExplosion (30 lines)

**Extends**: Node2D

**Variables**:
- _timer

**Key Functions**:
- _process(delta) → void (plays explosion sprite animation)

**Purpose**: Visual effect when grenade or projectile explodes

---

### scenes/entities/FireTrail (34 lines)

**Extends**: Node2D

**Variables**:
- _lifetime, _timer, _fade_timer

**Key Functions**:
- _process(delta) → void (fade out after 1 second)

**Purpose**: Visual effect left behind when player has fire_boots equipped

---

### scenes/arenas/Arena1 (377 lines)

**Extends**: Node2D

**Signals**: None explicit (uses Arena1-sourced signals from child nodes)

**Variables**:
- Spawning: _spawn_timer, _brutus_timer, _booster_timer
- Round: _level, _round_timer, _keys, _kills_this_round, _keys_dropped_this_round
- State: _boss_spawned, _game_over, _hud, _disperse_timer

**Key Functions**:
- _ready() → void (initializes level, connects signals)
- _process(delta) → void (~100 lines, spawning loop, round timer, boss logic)
- _round_duration() → float (returns duration in seconds by level)
- _spawn_interval() → float (calculates spawn rate, affected by chaos curse)
- _spawn_count() → int (returns 1-5 based on level)
- _spawn_aldrich() → void (instantiates with scaled stats)
- _spawn_brutus() → void (instantiates with scaled stats, starts at level 2)
- _spawn_booster() → void (limited to 2 simultaneous, starts at level 11)
- _spawn_boss() → void (instantiates Golgota, special stats at level 20)
- _edge_pos() → Vector2 (random edge position)
- _is_boss_level() → bool (level 10 or 20)
- on_boss_soul_collected() → void (victory: reset_run and SelectCharacter at level 20, else shop)
- _end_round() → void (kills all enemies, shows shop)
- _try_drop_key(enemy) → void (drops key with level-dependent chance)
- _check_disperse() → void (teleports clustered enemies)
- _on_enemy_died(enemy_type) → void (awards souls by enemy type)
- _on_round_continue(remaining_keys) → void (increments level, resets state)

**Level Progression**:
- Levels 1-9: Normal rounds, normal spawning
- Level 10: First boss (Golgota phase 3)
- Levels 11-19: Post-boss, Boosters added, increased difficulty
- Level 20: Final boss (Golgota custom_max_hp=3600)

**Key Drop Rates**:
- Early (level 1-2, ≤5 kills): 30%
- Normal: 14%
- Floor 2 (level 11+): 8% (max 12 per round)

**Enemy Scaling Tables**:
- ALDRICH_HP, ALDRICH_DMG, ALDRICH_SPEED (levels 1-19)
- BRUTUS_HP, BRUTUS_DMG, BRUTUS_CD, BRUTUS_BSPD, BRUTUS_RANGE, BRUTUS_INTERVAL (levels 2-19)
- BOOSTER_HP (levels 11-19)
- GOLGOTA: Custom scaling for level 20

**Dependencies**:
- Aldrich.tscn, Brutus.tscn, Booster.tscn, Golgota.tscn, Key.tscn
- Player.gd, GameOver.gd, ShopMenu.gd, PauseMenu.gd, HUD.gd
- PlayerData (autoload)

---

### scenes/ui/TouchControls (135 lines)

**Extends**: CanvasLayer

**Variables**:
- Joystick state: _left_id, _right_id, _joy_origin, _default_joy_pos
- UI elements: _base, _knob, _cross (Panel nodes)
- Constants: JOYSTICK_RADIUS=90.0, DEAD_ZONE=14.0

**Key Functions**:
- _build_ui() → void (dynamically creates joystick circles and pause button)
- _input(event) → void (dispatches touch events)
- _on_touch(e) → void (handles touch press/release)
- _on_drag(e) → void (updates joystick position and aim)
- _to_world(screen_pos) → Vector2 (converts screen coords to world)
- _on_pause_pressed() → void (injects InputEventAction "ui_cancel")

**UI Layout**:
- Left joystick: bottom-left (11.5% x, 80% y)
- Right aiming crosshair: bottom-right (87.5% x, 87% y)
- Pause button: top-center (50% x, top 16px)
- All sizes scale to viewport dynamically

**Purpose**: Mobile-exclusive dual-joystick input system (hidden on desktop)

**Dependencies**:
- PlayerData (touch_move, touch_aim_world, touch_shooting variables)

---

### scenes/ui/SelectCharacter (141 lines)

**Extends**: Control

**Signals**: None

**Variables**:
- _current (character index)
- _skill_overlay (SkillTreeOverlay instance)
- _float_tween

**Key Data**:
- CHARACTERS array:
  - Neophyte: "PRÊTRE DU FEU", hp=5, speed=3, magic=4
  - Serayne: "LA MAGE", hp=3, speed=3, magic=5
  - Unknown_2: Locked future character

**Key Functions**:
- _refresh() → void (updates UI with character stats)
- _anim_entrance() → void (slide-in entrance animation)
- _anim_portrait_float() → void (empty, was removed per user request)
- _on_prev_pressed() / _on_next_pressed() → void (character cycling)
- _switch_character() → void (fade portrait between characters)
- _on_open_grimoire() → void (opens SkillTreeOverlay)
- _on_character_selected() → void (starts game with selected character)

**Purpose**: Character selection menu before run start

**Dependencies**:
- PlayerData (selected_char, boss_souls, reset_run)
- SkillTreeOverlay.tscn
- SplashartLyra.png, SerayneSplashart.png

---

### scenes/ui/HUD (344 lines)

**Extends**: CanvasLayer

**Variables**:
- Labels: level_label, timer_label, keys_label, souls_label, hp_label, items_vbox
- Boss bar: boss_bar, boss_hp_label
- Item display: item_cells (Array of TextureRect + Label pairs)

**Key Functions**:
- refresh_level(lvl) → void
- refresh_timer(seconds) → void (shows -1 for boss levels)
- refresh_keys(count) → void
- refresh_souls(count) → void
- refresh_hp(current, maximum) → void
- refresh_items() → void (rebuilds item grid)
- refresh_boss_hp(hp) → void
- show_boss_bar(max_hp) → void
- hide_boss_bar() → void

**Purpose**: Heads-up display showing all game state during arena

**Dependencies**:
- PlayerData (items, souls, max_hp)

---

### scenes/ui/ShopMenu (638 lines)

**Extends**: CanvasLayer

**Signals**:
- continue_round(remaining_keys: int)

**Variables**:
- Slot state: _num_slots, _keys, _level, _reroll_count, _reroll_cost
- Item pools: _crate_items (Array of Array[3 items]), _crate_opened, _crate_chosen, _locked
- Rarity: _slot_rarities_arr
- UI: _crate_list, _crate_panels, _crate_btns, _crate_lock_btns, _stats_rtlabel
- Choice overlay: _choice_overlay, _choice_panels, _choice_slot_idx

**Key Functions**:
- show_shop(keys, level) → void (initializes shop with rarity roll)
- _roll_slot_rarity() → int (0=common, 1=rare, 2=epic, weighted by level)
- _roll_3_items(rarity) → Array (pulls 3 random items from ITEM_DB)
- _refresh_all() → void (updates UI, crates, stats panel)
- _refresh_stats_panel() → void (displays player stats breakdown)
- _on_crate_pressed(idx) → void (opens choice overlay)
- _on_choice_selected(choice_idx) → void (adds item, updates inventory)
- _on_reroll_pressed() → void (rerolls unlocked crates)
- _on_lock_crate(idx) → void (persists rarity between rounds)
- _on_continue_pressed() → void (emits continue_round signal)

**UI Layout**:
- 4 crate slots (or fewer early levels)
- Stats panel (right column): HP, DMG, Speed, Attack speed, Armor, Crit, Lifesteal, Projectiles, Range, Regen
- Reroll button (cost increases each time)
- Choice overlay: modal with 3-item cards per slot

**Rarity Progression**:
- Level 1: 10% rare, 0% epic
- Level 9: 70% epic, 25% rare
- Rarity costs: Common=1 key, Rare=4 keys, Epic=8 keys

**Reroll costs**: [20, 40, 70, 110, +50 each additional]

**Dependencies**:
- PlayerData (ITEM_DB, add_item, souls management)
- HUD.gd (refresh_items, refresh_souls)

---

### scenes/ui/SkillTreeOverlay (355 lines)

**Extends**: Control

**Signals**:
- skill_changed

**Variables**:
- _buttons (Dictionary of skill_id → Button)
- _souls_label, _tree_area
- _char_id, _reset_btn
- Reset hold: _reset_holding, _reset_timer (5.0s hold to confirm)

**Key Functions**:
- open(char_id) → void (opens skill tree for character)
- _rebuild_tree() → void (recreates all nodes and connection lines)
- _create_node(data) → void (creates single skill node button)
- _style_node(btn, skill_id) → void (colors based on owned/available/locked)
- _on_buy(skill_id) → void (purchases skill via PlayerData)
- _on_close() → void (hides overlay, emits skill_changed)
- _do_reset() → void (clears all skills, 5s hold required)

**Skill Node States**:
- Gold: Owned (disabled button)
- Purple: Available (enabled button)
- Gray: Locked (requires parent skills)

**Cost**: 1 boss soul + eternal_souls (varies by skill)

**Visual**: Connection lines drawn first (behind), skill nodes on top

**Dependencies**:
- PlayerData (SKILL_TREES, buy_skill, has_skill, boss_souls, eternal_souls)

---

### scenes/ui/MainMenu (135 lines)

**Extends**: Control

**Signals**: None

**Variables**:
- Menu buttons: start_btn, settings_btn, quit_btn

**Key Functions**:
- _on_start_pressed() → void (goes to Intro scene)
- _on_quit_pressed() → void (closes application)

**Purpose**: Main menu entry point

---

### scenes/ui/PauseMenu (49 lines)

**Extends**: Control

**Variables**:
- resume_btn, quit_btn

**Key Functions**:
- toggle() → void (pauses/unpauses game tree)
- _on_resume_pressed() → void
- _on_quit_pressed() → void (returns to MainMenu)

**Purpose**: Pause overlay triggered by ui_cancel action

---

### scenes/ui/GameOver (34 lines)

**Extends**: Control

**Variables**:
- restart_btn, menu_btn

**Key Functions**:
- show_screen() → void (displays game over UI)
- _on_restart_pressed() → void
- _on_menu_pressed() → void

**Purpose**: Game over screen shown when player dies

---

### scenes/ui/Intro (35 lines)

**Extends**: Control

**Variables**:
- play_btn, settings_btn

**Key Functions**:
- _on_play_pressed() → void (goes to StoryIntro)

**Purpose**: Introductory menu screen

---

### scenes/ui/StoryIntro (196 lines)

**Extends**: Control

**Signals**: None

**Variables**:
- Typing: _label (RichTextLabel), _char_idx, _typing, _blink_visible, _blink_t
- Background: _bg_img, _current_bg, _pan_tween
- Audio: _music, _music_next, _track_len, _crossfading, _music_base_vol
- Navigation: _current, _prompt, _skip_btn, _leaving

**Constants**:
- CHAR_DELAY=0.04 (char-by-char typing speed)
- BLINK_SPEED=0.6 (prompt cursor blink)
- CROSSFADE_DUR=1.0 (music crossfade)
- PAN_DUR=10.0 (background pan duration)

**Story Data**:
- 9 text panels (narrative about Valdris kingdom, Codex Inferno)
- Background images: Intro1-6.png
- Character-by-character typing with SFX

**Key Functions**:
- _show_panel(idx) → void (starts typing panel)
- _type_next() → void (recursive char typing)
- _crossfade_bg(path) → void (fades background with pan animation)
- _start_pan() → void (pans background left over 10s)
- _do_crossfade() → void (loops music with crossfade)
- _input(event) → void (advances to next panel on click)
- _fade_out_and_go() → void (transitions to SelectCharacter)

**Purpose**: Narrative intro with character-by-character typing, background panning, looping music

**Dependencies**: Intro1-6.png, music track

---

### scenes/effects/EffectSprite (63 lines)

**Extends**: Sprite2D

**Variables**:
- _lifetime, _timer

**Key Functions**:
- _process(delta) → void (plays animation, fades out, auto-deletes)

**Purpose**: Generic visual effect sprite (lightning, sceptre blasts, etc.)

---

## 📊 Project Statistics

**Total Lines of Code**: ~4,500+ (excluding comments, blank lines)

**File Type Breakdown**:
- Autoload/State Management: 1 file (522 lines)
- Player/Character: 1 file (682 lines)
- Enemies: 5 files (Base + 4 specialized, ~480 lines)
- Enemy Projectiles: 6 files (~260 lines)
- Arena/Spawning: 1 file (377 lines)
- UI/Menus: 9 files (~1,800 lines)
- Effects/Visuals: 1 file (63 lines)
- Narrative: 1 file (196 lines)

**Architecture Patterns**:
- **Inheritance**: BaseEnemy used by Aldrich, Brutus, Booster; all boss projectiles are independent
- **Singletons**: PlayerData autoload for global state
- **Signals**: Heavy use for event coupling (died, animation_finished, skill_changed)
- **Callbacks**: Deferred calls for safe scene additions during physics frame
- **Tweens**: Smooth animations for UI transitions and background pans
- **AtlasTexture**: Dynamic spritesheet slicing for death animations

**Key Design Principles**:
- No @warning_ignore used except where intentionally ignoring (unused wander vars in BaseEnemy)
- Minimal comments (code is self-documenting via naming)
- Clear separation between input (TouchControls), logic (Player, enemies), and state (PlayerData)
- Boss phases use state machine with thresholds
- Items are purely data-driven (in PlayerData.ITEM_DB)

---

## 🔗 Signal Map

**Player → Arena**:
- Player.died → Arena.$GameOver.show_screen()
- Player.died → Arena._game_over = true

**Arena → ShopMenu**:
- Arena.$ShopMenu.continue_round → Arena._on_round_continue()

**Player → HUD**:
- Player.hp_changed → HUD (various refresh calls)
- Enemy.died → HUD.refresh_souls()

**SkillTreeOverlay → SelectCharacter**:
- SkillTreeOverlay.skill_changed → SelectCharacter._refresh_forge()

**ShopMenu → HUD**:
- ShopMenu item selection → HUD.refresh_items()
- ShopMenu reroll → HUD.refresh_souls()

---

**Scan completed**: 2026-04-29  
**Next Steps**: Refer to this document for architecture decisions and dependency tracking
