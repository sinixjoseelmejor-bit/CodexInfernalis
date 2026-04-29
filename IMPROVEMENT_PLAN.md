# PLAN D'AMÉLIORATION CODEX INFERNO
### Priorisé par impact (risque × probabilité × bénéfice joueur)
### Source : OPUS_STRATEGIC_BRIEFING.md, 30 scripts, 4 500+ lignes
### Généré le 2026-04-29

---

## P0 — CORRECTIONS CRITIQUES (gameplay cassé / promesses non tenues)

### P0.1 — `hp_regen` est une stat fantôme
- **Problème** : `PlayerData.hp_regen` est affichée dans le panneau de stats de la boutique mais **aucune logique de régénération** n'existe dans `Player._physics_process`. Le joueur peut acheter un item augmentant hp_regen et ne voir aucun effet → trahison de confiance.
- **Solution** : Soit supprimer la stat (et son affichage), soit l'implémenter.
  ```gdscript
  # Dans Player._physics_process(delta)
  if PlayerData.hp_regen > 0.0 and PlayerData.hp < PlayerData.max_hp:
      _regen_acc += PlayerData.hp_regen * delta
      var heal := int(_regen_acc)
      if heal > 0:
          PlayerData.hp = min(PlayerData.max_hp, PlayerData.hp + heal)
          _regen_acc -= heal
          hud.refresh_hp()
  ```
- **Fichiers** : [scenes/entities/Player.gd](scenes/entities/Player.gd), [autoload/PlayerData.gd](autoload/PlayerData.gd)
- **Critère de succès** : un item avec `+1 hp_regen` rend visiblement 1 PV/s en arène, vérifiable au HUD.

### P0.2 — Serayne et les items à projectiles sont incompatibles
- **Problème** : Serayne n'appelle jamais `_spawn_bullet()`. Items achetables comme `double_canon` (projectile_count), `orbe_mana` (projectile bonus), `oeil_tenebres` (bonus dmg), une partie d'`orbe_mana` n'ont **aucun effet** sur elle. Le joueur dépense des clés pour rien.
- **Solution** : 2 options selon design intent.
  - **(A) Marquer les items "incompatibles serayne"** dans `ITEM_DB` (`incompatible_with: ["serayne"]`) → la boutique les filtre quand `selected_char == "serayne"`.
  - **(B) Mapper les bonus projectile sur l'ours** : `projectile_count` → +1 ours simultané ; `orbe_mana` → l'ours déclenche une AOE bonus tous les 10 hits ; `oeil_tenebres` → l'ours frappe plus fort à distance.
- **Fichiers** : [autoload/PlayerData.gd](autoload/PlayerData.gd) (filtrage ITEM_DB), [scenes/ui/ShopMenu.gd](scenes/ui/ShopMenu.gd) (génération des caisses), [scenes/entities/Bear.gd](scenes/entities/Bear.gd) (option B)
- **Critère de succès** : avec Serayne sélectionnée, soit les items projectile **n'apparaissent jamais** en boutique, soit ils ont un effet vérifiable sur le comportement de l'ours.

### P0.3 — Flag `dev_no_shoot` non documenté en production
- **Problème** : `PlayerData.dev_no_shoot` peut empêcher silencieusement le tir. Aucun toggle visible. Si la sauvegarde se corrompt avec `dev_no_shoot=true`, le joueur ne peut plus tirer sans comprendre pourquoi.
- **Solution** : Garder le flag derrière `OS.is_debug_build()` uniquement, ou le retirer définitivement de la sauvegarde.
- **Fichiers** : [autoload/PlayerData.gd](autoload/PlayerData.gd), [scenes/entities/Player.gd](scenes/entities/Player.gd)
- **Critère de succès** : en build release, `dev_no_shoot` est forcé à `false` au démarrage.

---

## P1 — PERFORMANCE MOBILE (plateforme prioritaire)

### P1.1 — Object pooling pour projectiles et VFX
- **Problème** : `Fireball.instantiate()` + `queue_free()` à chaque tir, **chaque** Fireball spawn une `FireTrail` toutes les 0.1s pendant 8s. Avec `fire_cd` bas + `auto_grenade` + `tempete_acier` (12 bullets simultanés), on peut atteindre **plusieurs centaines d'allocations/sec**. GC pressure et hitches sur Android bas de gamme.
- **Solution** : Implémenter un pool dans Arena ou un autoload `BulletPool`.
  ```gdscript
  # Pseudocode
  var _fireball_pool: Array[Fireball] = []
  func get_fireball() -> Fireball:
      if _fireball_pool.is_empty(): return FIREBALL.instantiate()
      return _fireball_pool.pop_back()
  func release_fireball(f: Fireball) -> void:
      f.reset(); f.visible = false; _fireball_pool.append(f)
  ```
  Pooler au minimum : `Fireball`, `FireTrail`, `Grenade`, `BrutusBullet`, `BulletExplosion`.
- **Fichiers** : nouveau [autoload/BulletPool.gd](autoload/BulletPool.gd), [scenes/entities/Fireball.gd](scenes/entities/Fireball.gd), [scenes/entities/FireTrail.gd](scenes/entities/FireTrail.gd), [scenes/entities/Grenade.gd](scenes/entities/Grenade.gd), [scenes/entities/BrutusBullet.gd](scenes/entities/BrutusBullet.gd), [scenes/entities/Player.gd](scenes/entities/Player.gd) (call sites)
- **Critère de succès** : profilage 60s niveau 15 sur device cible — instances créées de Fireball/FireTrail < 50, FPS stable ≥ 50.

### P1.2 — Cache partagé de `SpriteFrames` joueur
- **Problème** : `_setup_animations()` charge ~200 fichiers PNG via `load()` synchrone à chaque `_ready()` du Player. Au respawn ou retour à la sélection, c'est rechargé.
- **Solution** : Construire une `SpriteFrames` ressource une seule fois (préchargée au `Intro.tscn`) et la stocker dans un singleton `Assets`. Le Player la lit, ne la construit plus.
- **Fichiers** : nouveau [autoload/Assets.gd](autoload/Assets.gd), [scenes/entities/Player.gd](scenes/entities/Player.gd) (`_setup_animations`, `_setup_animations_serayne`)
- **Critère de succès** : `_ready()` du Player < 50 ms sur device cible (mesuré avec `Time.get_ticks_msec()`).

### P1.3 — Récursion `StoryIntro._type_next()` sur mobile
- **Problème** : Le typage caractère-par-caractère via `await timer; _type_next()` accumule jusqu'à 300+ coroutines sur les longs panneaux. Risque de freeze ou crash mémoire sur Android bas de gamme.
- **Solution** : Convertir en boucle simple :
  ```gdscript
  func _type_panel(text: String) -> void:
      for i in text.length():
          if _skip_requested: label.text = text; return
          label.text = text.substr(0, i+1)
          _play_tick_sound()
          await get_tree().create_timer(CHAR_DELAY).timeout
  ```
- **Fichiers** : [scenes/ui/StoryIntro.gd](scenes/ui/StoryIntro.gd)
- **Critère de succès** : intro complète sur device cible sans hitch ni crash, mémoire stable (< +5 MB sur durée totale).

### P1.4 — `_effective_damage()` recalculé N fois par tir
- **Problème** : Avec `projectile_count = 3`, `_effective_damage()` est appelé 1 fois dans `_shoot()` puis ré-appelé dans chaque `_spawn_bullet()` → 4 appels, dont 3 itèrent sur tous les ennemis et tirent un nouveau `roll_crit()`. Crit divergent par balle, conditions item recalculées.
- **Solution** : Décider intentionnellement :
  - **Si crit-par-balle voulu** : ne plus appeler `_effective_damage()` dans `_shoot()`, calculer une seule fois par balle dans `_spawn_bullet()`.
  - **Si crit-par-tir voulu** : calculer une fois dans `_shoot()`, passer `dmg` et `is_crit` en paramètres à `_spawn_bullet()`.
- **Fichiers** : [scenes/entities/Player.gd](scenes/entities/Player.gd) (`_shoot`, `_spawn_bullet`, `_effective_damage`)
- **Critère de succès** : `_effective_damage()` appelé exactement N fois par tir où N est documenté ; le test unitaire (ou check console) confirme.

### P1.5 — `HUD.refresh_items()` reconstruit toute la grille
- **Problème** : Appelé à chaque achat et début de round. Détruit + recrée tous les nœuds UI items.
- **Solution** : Diff incrémentiel — comparer `PlayerData.items` au cache local, n'ajouter que les nouveaux nœuds, mettre à jour les compteurs in-place.
- **Fichiers** : [scenes/ui/HUD.gd](scenes/ui/HUD.gd)
- **Critère de succès** : achat d'un item dans un inventaire de 30 items déclenche < 5 ms de UI work (au lieu de reconstruire 30 nœuds).

---

## P2 — DETTE ARCHITECTURALE (maintenabilité long terme)

### P2.1 — Player.gd est une classe Dieu (682 lignes)
- **Problème** : Tous les effets on-hit/on-kill/timer-passif des items sont inline dans `Player.gd`. Ajouter un item au-delà de ~100 cassera la lisibilité. Modifier l'effet d'un item nécessite de naviguer dans une fonction de 50+ lignes.
- **Solution** : Pattern handler — un `Resource` ou un dict par item définit ses callbacks.
  ```gdscript
  # autoload/ItemEffects.gd
  var on_hit_handlers: Dictionary = {
      "oeil_gele": func(player, enemy, ctx): ...,
      "dague_asmodee": func(player, enemy, ctx): ...,
  }
  func trigger_on_hit(player, enemy):
      for item_id in PlayerData.items:
          if on_hit_handlers.has(item_id):
              on_hit_handlers[item_id].call(player, enemy, _ctx)
  ```
  Refactor en 3 phases (on-hit, on-kill, passif-tick) pour limiter le risque.
- **Fichiers** : nouveau [autoload/ItemEffects.gd](autoload/ItemEffects.gd), [scenes/entities/Player.gd](scenes/entities/Player.gd)
- **Critère de succès** : `Player.gd` < 350 lignes ; ajouter un nouvel item ne touche que `ItemEffects.gd` + `ITEM_DB`.

### P2.2 — Branching personnage hardcodé (`if selected_char == "serayne"`)
- **Problème** : Chaque nouveau personnage (zealot, paladin, unknown_2) demandera des `if/elif` dans `Player._setup_animations`, `_shoot`, `_invoke_bear`. Le 3ème slot est déjà prévu (`SelectCharacter.CHARACTERS`).
- **Solution** : Définir une `CharacterDef` (Resource) par personnage :
  ```
  res://data/characters/neophyte.tres
  res://data/characters/serayne.tres
  ```
  Avec : `id`, `display_name`, `class_name_str`, `splashart`, `sprite_frames`, `attack_strategy` (enum: PROJECTILE | SUMMON | ...). `Player._ready()` lit la CharacterDef de PlayerData.selected_char et configure tout sans branching.
- **Fichiers** : nouveau dossier `data/characters/`, [scenes/entities/Player.gd](scenes/entities/Player.gd), [scenes/ui/SelectCharacter.gd](scenes/ui/SelectCharacter.gd), [autoload/PlayerData.gd](autoload/PlayerData.gd)
- **Critère de succès** : ajouter un 3ème personnage = créer un fichier `.tres` + ses assets, **zéro modification** dans `Player.gd`.

### P2.3 — `Arena1._process()` (~100 lignes) responsabilités multiples
- **Problème** : Spawn Aldrich, spawn Brutus, spawn Booster, check boss, timer round, fin de round — tout dans un seul `_process`.
- **Solution** : Extraire en sous-systèmes (méthodes ou nodes enfants) :
  - `_tick_spawners(delta)` (un Timer Godot par type d'ennemi serait encore plus propre)
  - `_tick_round_clock(delta)`
  - `_tick_boss_state(delta)`
- **Fichiers** : [scenes/arenas/Arena1.gd](scenes/arenas/Arena1.gd)
- **Critère de succès** : `_process()` < 30 lignes ; chaque sous-tick testable indépendamment.

### P2.4 — PlayerData mélange "données" et "bus de messages"
- **Problème** : `touch_move`, `touch_aim_world`, `touch_shooting` sont des **événements temps réel** stockés dans le singleton de **données**. Mélange de responsabilités.
- **Solution** : Créer un autoload `Input2` dédié à l'input (touch + mouse abstrait). PlayerData garde uniquement stats/items/save.
- **Fichiers** : nouveau [autoload/Input2.gd](autoload/Input2.gd), [autoload/PlayerData.gd](autoload/PlayerData.gd) (retirer touch_*), [scenes/ui/TouchControls.gd](scenes/ui/TouchControls.gd), [scenes/entities/Player.gd](scenes/entities/Player.gd) (`_get_aim_dir`)
- **Critère de succès** : `grep "touch_" autoload/PlayerData.gd` retourne 0 ligne.

### P2.5 — Golgota n'hérite pas de BaseEnemy
- **Problème** : Asymétrie qui force des safety checks (`"grabbed" in _target` dans Bear.gd). Aucun saignement/slow ne fonctionne sur le boss. Décision implicite non documentée.
- **Solution** : 2 options.
  - **(A) Documenter** : ajouter un commentaire en tête de Golgota.gd expliquant le choix (boss immune by design), garder le code Bear safety check tel quel.
  - **(B) Refactor** : extraire une interface `IDamageable` ou faire hériter Golgota de BaseEnemy avec `immune_to_status = true`.
- **Fichiers** : [scenes/entities/Golgota.gd](scenes/entities/Golgota.gd), [scenes/entities/BaseEnemy.gd](scenes/entities/BaseEnemy.gd) (option B), [scenes/entities/Bear.gd](scenes/entities/Bear.gd)
- **Critère de succès** : la décision est **explicite** dans le code (commentaire ou type).

---

## P3 — BALANCE & COHÉRENCE

### P3.1 — Anomalie Brutus spawn interval niveau 11
- **Problème** : `BRUTUS_INTERVAL[10]=4.0` puis `[11]=5.0`. Régression de difficulté au moment où les Boosters arrivent. Probablement un trade-off intentionnel mais non documenté.
- **Solution** : Soit confirmer et **commenter le tableau** ; soit lisser la courbe. Tester en jeu sur le passage 10→11.
- **Fichiers** : [scenes/arenas/Arena1.gd](scenes/arenas/Arena1.gd)
- **Critère de succès** : courbe lissée OU commentaire `# +1s pour absorber arrivée Booster` au-dessus du tableau.

### P3.2 — Magic numbers à extraire
- **Problème** : `60 dmg cap Golgota`, `80px bear offset`, `275 vitesse base`, `5/3/8/50 souls par ennemi`, `100/50 eternal souls fin run`, `15° spread`, etc. dispersés.
- **Solution** : Centraliser dans `PlayerData` (ou nouveau `BalanceConst.gd`) en `const` nommées avec commentaire de design intent.
- **Fichiers** : [autoload/PlayerData.gd](autoload/PlayerData.gd), [scenes/arenas/Arena1.gd](scenes/arenas/Arena1.gd), [scenes/entities/Player.gd](scenes/entities/Player.gd), [scenes/entities/Golgota.gd](scenes/entities/Golgota.gd)
- **Critère de succès** : `grep -nE "= [0-9]+\.?[0-9]* *#" scenes/` ne montre plus de magic number critique sans constante.

### P3.3 — Cap clés floor 2 (12/round) potentiellement trop serré
- **Problème** : Au niveau 11+, ~150 kills nécessaires pour saturer le drop à 8% × 12 max. Si la courbe d'achat exige plus de clés, ratio frustrant.
- **Solution** : Instrumenter une session test (compter clés effectivement obtenues vs dépensées niveau 11–19), ajuster `KEY_DROP_FLOOR2_CAP` ou taux 8% si gap > 2 caisses common manquées.
- **Fichiers** : [scenes/arenas/Arena1.gd](scenes/arenas/Arena1.gd)
- **Critère de succès** : à niveau 15, le joueur peut ouvrir au moins 3 caisses common par round avec un build moyen.

### P3.4 — Rééquilibrage du DMG_CAP=60 sur Golgota
- **Problème** : Conçu pour empêcher les builds burst de OS le boss, mais peut frustrer les builds crit qui fonctionnent normalement contre les ennemis. Asymétrie boss/normal non visible joueur.
- **Solution** : Afficher visuellement le cap (chiffre flottant rouge "60 (CAPPED)" si le dmg réel dépassait 60). Permet feedback joueur, valide la décision design.
- **Fichiers** : [scenes/entities/Golgota.gd](scenes/entities/Golgota.gd) (`take_damage`), [scenes/ui/HUD.gd](scenes/ui/HUD.gd) (damage numbers si système existe)
- **Critère de succès** : à un coup qui devrait faire 200 dmg, l'affichage montre "60" + indicateur de cap.

---

## P4 — FONCTIONNALITÉS MANQUANTES

### P4.1 — 3ème personnage (slot "Unknown_2 — BIENTÔT")
- **Problème** : UI existe, slot vide. La refonte P2.2 (CharacterDef) est un prérequis.
- **Solution** : Prérequis P2.2 → créer `data/characters/zealot.tres` ou similaire avec sa stratégie d'attaque (option : `BEAM` continuous, `MELEE` swing, etc.).
- **Fichiers** : `data/characters/`, assets sprites, [scenes/ui/SelectCharacter.gd](scenes/ui/SelectCharacter.gd) (CHARACTERS array → unlock logic).
- **Critère de succès** : un 3ème slot jouable, distinct mécaniquement de Neophyte/Serayne, end-to-end run possible.

### P4.2 — Système de malédictions (acquisition)
- **Problème** : `has_curse()`, `get_curse_soul_multiplier()`, `curse_chaos` sont câblés mais aucun mécanisme d'acquisition.
- **Solution** : Décider du design — pacte volontaire en boutique ? drop boss ? fragment de skill tree ? Implémenter au moins un point d'entrée.
- **Fichiers** : [autoload/PlayerData.gd](autoload/PlayerData.gd), [scenes/ui/ShopMenu.gd](scenes/ui/ShopMenu.gd) ou nouveau [scenes/ui/CurseAltar.gd](scenes/ui/CurseAltar.gd)
- **Critère de succès** : un joueur peut acquérir `curse_chaos` et constater le `×0.80 spawn_interval` en arène.

### P4.3 — Settings menu (bouton existant non implémenté)
- **Problème** : `Intro.gd` a un `settings_btn` orphelin.
- **Solution** : Petite scène avec : volume musique, volume SFX, taille joystick (mobile), reset progression (avec confirmation).
- **Fichiers** : nouveau [scenes/ui/SettingsMenu.tscn](scenes/ui/SettingsMenu.tscn), [scenes/ui/Intro.gd](scenes/ui/Intro.gd)
- **Critère de succès** : bouton fonctionnel, settings persistent dans le save.

### P4.4 — Visualisation des buffs/debuffs actifs
- **Problème** : `cor_guerre`, `sang_courroux`, `anneau_phlegethon` activent des buffs avec timers. Le joueur n'a aucun feedback visuel — il voit juste le résultat numérique en boutique.
- **Solution** : Bandeau d'icônes au-dessus du HP avec timer remaining (style Hades / Vampire Survivors).
- **Fichiers** : [scenes/ui/HUD.gd](scenes/ui/HUD.gd), [autoload/PlayerData.gd](autoload/PlayerData.gd) (exposer les timed buffs)
- **Critère de succès** : tuer un ennemi avec sang_courroux affiche une icône + barre 5s.

### P4.5 — Nettoyage signal `laser_done` orphelin
- **Problème** : `GolgotaLaser.laser_done` émis mais jamais écouté (Golgota utilise un timer interne).
- **Solution** : Soit câbler Golgota pour l'écouter (et supprimer le timer), soit supprimer le signal.
- **Fichiers** : [scenes/entities/GolgotaLaser.gd](scenes/entities/GolgotaLaser.gd), [scenes/entities/Golgota.gd](scenes/entities/Golgota.gd)
- **Critère de succès** : `grep "laser_done" scenes/` est cohérent (émis ↔ connecté).

---

## P5 — POLISH & ACCESSIBILITÉ

### P5.1 — Cheat codes accessibles sur mobile
- Bouton dev secret (5 taps coin écran en debug build).
- **Fichiers** : [scenes/ui/TouchControls.gd](scenes/ui/TouchControls.gd), [scenes/arenas/Arena1.gd](scenes/arenas/Arena1.gd).

### P5.2 — Échelle UI configurable (joystick, HUD)
- Sliders dans Settings (P4.3).

### P5.3 — `restart` GameOver vérifiable
- Tester que `reset_run()` + reload effectifs (Q open dans le brief).

---

# ROADMAP SUGGÉRÉE (ordre d'exécution)

| Sprint | Items | Livrable utilisateur |
|--------|-------|----------------------|
| **S1 (1 sem)** | P0.1, P0.2, P0.3 | Promesses tenues : pas de stat fantôme, pas d'item placebo |
| **S2 (1 sem)** | P1.1, P1.2 | FPS stable mobile niveau 15+ |
| **S3 (3 jours)** | P1.3, P1.4, P1.5 | Plus de hitch sur intro/UI |
| **S4 (1–2 sem)** | P2.1 (handler items), P2.2 (CharacterDef) | Refacto qui débloque P4.1 |
| **S5 (1 sem)** | P2.3, P2.4, P2.5, P3.1, P3.2 | Codebase propre, balance commentée |
| **S6 (1–2 sem)** | P4.1 3ème perso, P4.2 curses, P4.4 buff UI | Contenu nouveau visible joueur |
| **S7 (3 jours)** | P4.3 settings, P4.5, P5.* | Polish final |

---

**Recommandation tactique** : exécuter P0 + P1 **avant** tout refacto P2. Les bugs visibles (hp_regen, Serayne) érodent la confiance plus vite que la dette interne, et le pooling débloque le test mobile honnête sur lequel toutes les autres décisions de balance reposent.
