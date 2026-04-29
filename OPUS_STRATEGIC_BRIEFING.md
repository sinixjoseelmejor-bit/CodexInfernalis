# CODEX INFERNO — BRIEFING STRATÉGIQUE COMPLET
### Document destiné au modèle de raisonnement Opus
### Source : scan complet de 30 fichiers GDScript (4 500+ lignes), 2026-04-29

> ⚠ Opus ne verra QUE ce document. Il ne verra pas le code source. Ce briefing est la seule source de vérité.

---

# 1. VUE D'ENSEMBLE DU JEU

## Genre et mécanique principale
**Codex Inferno** est un **roguelite twin-stick shooter** en vue du dessus (top-down), en 2D, développé sur **Godot 4.6**. La mécanique principale est une boucle d'arène : le joueur survit à des vagues d'ennemis pendant un temps imparti, tue les ennemis pour collecter des clés, achète des objets dans une boutique entre chaque vague, et progresse jusqu'au boss.

## Plateforme cible
- **Priorité mobile** (Android confirmé, export configuré)
- PC également supporté (Windows, D3D12)
- Viewport fixe : 1920×1080, mode `canvas_items` (scale to fit)
- Orientation forcée : paysage

## Objectif du joueur
Compléter 20 niveaux croissants en difficulté dans une seule arène. Les niveaux 10 et 20 sont des combats de boss (Golgota). Après la victoire au niveau 20, la run se réinitialise et le joueur retourne à la sélection de personnage.

## Boucle de gameplay core (game loop)
```
MainMenu → StoryIntro → SelectCharacter
  → [Arena] vague chronométrée
    → tuer ennemis → collecter clés + âmes
    → timer expire ou boss tué
  → [ShopMenu] dépenser clés pour items (rareté aléatoire)
    → choisir 1 item parmi 3 par caisse
    → reroll possible (coût croissant en âmes)
  → prochain niveau (level + 1)
    → boss au niveau 10, boss final au niveau 20
  → victoire → retour SelectCharacter (ou GameOver → MainMenu)
```

## Personnages jouables
| ID | Nom | Classe | HP | Speed | Magic | Attaque de base |
|----|-----|---------|----|----|-------|----------------|
| neophyte | NÉOPHYTE | PRÊTRE DU FEU | 5 | 3 | 4 | Fireballs directionnelles auto-visant |
| serayne | SERAYNE | LA MAGE | 3 | 3 | 5 | Invoque un ours qui charge les ennemis |
| unknown_2 | ??? | BIENTÔT | 0 | 0 | 0 | Verrouillé |

## Progression méta (cross-run)
- **Boss Souls** et **Eternal Souls** : accumulés sur toutes les runs, utilisés pour acheter des compétences dans la Forge Éternelle (SkillTree)
- **Unlocked chars** : "zealot" débloqué à 1 victoire, "paladin" à 5 victoires (pas encore implémentés comme personnages jouables)

---

# 2. ARCHITECTURE DU CODE

## Liste complète des 30 scripts (rôle et responsabilité)

### Couche Autoload (Singleton global)
| Fichier | Lignes | Responsabilité |
|---------|--------|----------------|
| `autoload/PlayerData.gd` | 522 | Singleton global. Stocke TOUTE l'état de la run : stats calculées, inventaire, âmes, niveau, compétences, buffs temporaires. Contient la base de données des 75+ items (ITEM_DB) et les arbres de compétences (SKILL_TREES). Gère la persistance (save/load). Contient aussi les variables d'entrée tactile : touch_move, touch_aim_world, touch_shooting. |

### Entités joueur/ennemis
| Fichier | Lignes | Responsabilité |
|---------|--------|----------------|
| `scenes/entities/Player.gd` | 682 | Classe principale du joueur. Gère : mouvement, animation, tir, invocation ours, dégâts, mort, tous les effets on-hit/on-kill de chaque item, revive, camera setup. CLASSE DIEU. |
| `scenes/entities/BaseEnemy.gd` | 153 | Classe de base pour les ennemis normaux. HP, dégâts, vitesse, état dead, flag grabbed (freeze ours), saignement, ralentissement. |
| `scenes/entities/Aldrich.gd` | 95 | Ennemi mêlée de base. Poursuite du joueur. |
| `scenes/entities/Brutus.gd` | 127 | Ennemi à distance. Tire des projectiles. Paramètres scalés depuis Arena1. |
| `scenes/entities/Booster.gd` | 100 | Ennemi avec charge en burst. Apparaît à partir du niveau 11. |
| `scenes/entities/Golgota.gd` | 263 | Boss unique. 3 phases. Laser, orbes, minions, shockwave. NE hérite PAS de BaseEnemy (extends CharacterBody2D directement). |
| `scenes/entities/Bear.gd` | 106 | Familier de Serayne. State machine : idle→move→attack. AOE damage + freeze. Extends AnimatedSprite2D (pas de physique). |

### Projectiles et effets de combat
| Fichier | Lignes | Responsabilité |
|---------|--------|----------------|
| `scenes/entities/Fireball.gd` | 88 | Projectile principal du joueur. Vit 8s. Spawn FireTrail toutes les 0.1s. |
| `scenes/entities/Grenade.gd` | 56 | Projectile arc (item auto_grenade). Explose avec AOE. |
| `scenes/entities/FireTrail.gd` | 34 | Trace visuelle laissée par les bottes de feu. Fade out 1s. |
| `scenes/entities/BulletExplosion.gd` | 30 | Sprite d'explosion visuelle (Grenade). |
| `scenes/entities/BrutusBullet.gd` | 27 | Projectile de Brutus. Simple trajectoire directe. |
| `scenes/entities/GolgotaOrb.gd` | 36 | Orbe du boss. Flotte sur place, damage + slow au contact. |
| `scenes/entities/GolgotaLaser.gd` | 82 | Laser du boss. Phase télégraphe (tracking optionnel) + phase active. |
| `scenes/entities/GolgotaShockwave.gd` | 60 | Shockwave radiale (phase critique boss). Expansion continue. |

### Pickups
| Fichier | Lignes | Responsabilité |
|---------|--------|----------------|
| `scenes/entities/Key.gd` | 27 | Clé ramassable. Tourne sur elle-même. Appelle arena.add_key() au contact. |
| `scenes/entities/BossSoul.gd` | 25 | Âme du boss. Vol vers le joueur après mort du boss. Déclenche la victoire. |

### Arène
| Fichier | Lignes | Responsabilité |
|---------|--------|----------------|
| `scenes/arenas/Arena1.gd` | 377 | Chef d'orchestre de la partie. Spawn des ennemis, timer des rounds, progression des niveaux, drop de clés, logique victoire/défaite, cheat codes de debug. Contient toutes les tables de scaling des ennemis. |

### Interface utilisateur
| Fichier | Lignes | Responsabilité |
|---------|--------|----------------|
| `scenes/ui/TouchControls.gd` | 135 | Double joystick mobile (caché sur desktop). Joystick gauche = mouvement, droite = visée/tir. Bouton pause. Toute la UI construite dynamiquement par code. |
| `scenes/ui/HUD.gd` | 344 | Affichage in-game : PV, niveau, timer, clés, âmes, items, barre de boss. |
| `scenes/ui/ShopMenu.gd` | 638 | Boutique inter-rounds. 4 caisses de rarités aléatoires. Choix 1 parmi 3. Reroll. Lock. Panel de stats. |
| `scenes/ui/SkillTreeOverlay.gd` | 355 | Forge Éternelle. Arbre de compétences per-personnage. Nœuds visuels avec connexions. Achat par boss souls + eternal souls. |
| `scenes/ui/SelectCharacter.gd` | 141 | Sélection du personnage. Affiche stats (points), lore, portrait. Accès à la Forge. |
| `scenes/ui/MainMenu.gd` | 135 | Menu principal. Boutons start/quit. |
| `scenes/ui/PauseMenu.gd` | 49 | Pause overlay. Toggle via ui_cancel. |
| `scenes/ui/GameOver.gd` | 34 | Écran de mort. Restart ou menu. |
| `scenes/ui/Intro.gd` | 35 | Écran titre (avant StoryIntro). |
| `scenes/ui/StoryIntro.gd` | 196 | Intro narrative. 9 panneaux de texte avec typage lettre par lettre, fond panoramique, musique en crossfade. |

### Effets visuels
| Fichier | Lignes | Responsabilité |
|---------|--------|----------------|
| `scenes/effects/EffectSprite.gd` | 63 | Sprite générique de VFX (éclairs, rafales de sceptre). Auto-détruit après animation. |

---

## Schéma des dépendances (qui appelle qui)

```
PlayerData (singleton global)
  ↑ lu/écrit par TOUS les scripts
  
Arena1.gd
  ├─ instancie → Aldrich, Brutus, Booster, Golgota, Key
  ├─ contient → Player, GameOver, ShopMenu, PauseMenu, HUD (en scène)
  ├─ lit/écrit → PlayerData (level, souls, unlocked_chars)
  └─ _on_round_continue ← ShopMenu.continue_round (signal)

Player.gd
  ├─ instancie → Fireball, Bear, Grenade, FireTrail, FxLightning, FxSceptre
  ├─ lit → PlayerData (tous les stats, items, buffs)
  ├─ écrit → PlayerData (reset indirect via Arena)
  └─ appelle get_first_node_in_group("hud") pour rafraîchir HP

Bear.gd
  ├─ recherche enemies (groupe "enemies")
  └─ vérifie/écrit .grabbed sur BaseEnemy

TouchControls.gd
  └─ écrit PlayerData.touch_move, touch_aim_world, touch_shooting

ShopMenu.gd
  ├─ lit PlayerData.ITEM_DB
  ├─ écrit PlayerData.items (via add_item)
  └─ appelle HUD.refresh_items(), HUD.refresh_souls()

SkillTreeOverlay.gd
  ├─ lit PlayerData.SKILL_TREES
  └─ appelle PlayerData.buy_skill(), reset_char_skills()

SelectCharacter.gd
  ├─ écrit PlayerData.selected_char
  └─ instancie SkillTreeOverlay

GolgotaLaser.gd, GolgotaOrb.gd, GolgotaShockwave.gd
  └─ instanciés par Golgota.gd

Golgota.gd
  └─ instancie BossSoul (sur mort)
```

---

## Autoloads / Singletons

**Un seul autoload : `PlayerData`**

Il est enregistré dans `project.godot` comme `PlayerData="*res://autoload/PlayerData.gd"` (le `*` signifie singleton).

Il joue le rôle de :
- **Base de données** : ITEM_DB (75+ items), SKILL_TREES (arbre par personnage)
- **Tables de stats de base** : BASE_HP_TABLE[1..9], BASE_DMG_TABLE[1..9], BASE_CD_TABLE[1..9]
- **État de la run** : items équipés, âmes, niveau, personnage sélectionné
- **Stats calculées** : max_hp, damage, speed, fire_cd, armor, crit_chance, etc.
- **Bus de messages pour l'input tactile** : touch_move, touch_aim_world, touch_shooting
- **Persistance** : sauvegarde/chargement du profil (boss_souls, eternal_souls, victoires, chars débloqués)

---

## Système de signaux

| Émetteur | Signal | Récepteur | Effet |
|----------|--------|-----------|-------|
| `Player` | `died` | `Arena1` → `GameOver.show_screen()` | Affiche l'écran de mort |
| `Player` | `died` | `Arena1` | `_game_over = true` (arrête le process) |
| `Player` | `hp_changed(current, max)` | (non connecté via signal en arène) | Appelé manuellement via `hud.refresh_hp()` |
| `BaseEnemy` | `died` | `Arena1._on_enemy_died(type)` | Accorde les âmes, active on_enemy_kill sur Player |
| `BaseEnemy` | `died` | `Arena1._try_drop_key(enemy)` | Peut spawner une clé |
| `ShopMenu` | `continue_round(remaining_keys)` | `Arena1._on_round_continue()` | Passe au niveau suivant |
| `GolgotaLaser` | `laser_done` | (non utilisé dans Golgota.gd actuel) | Signal déclaré mais Golgota utilise un timer interne |
| `SkillTreeOverlay` | `skill_changed` | `SelectCharacter._refresh_forge()` | Met à jour l'affichage des boss souls |
| `AnimatedSprite2D` | `animation_finished` | `Player._on_anim_finished()` | Fin d'attaque → retour idle |
| `AnimatedSprite2D` | `animation_finished` | `Golgota._die()` | Fin anim mort → queue_free |
| `Bear` | `animation_finished` | `Bear._on_attack_finished()` | Fin attaque → retour idle |

---

# 3. SYSTÈMES IMPLÉMENTÉS

## 3.1 Système de mouvement (JOUEUR)
**Fonctionnel :**
- Mouvement WASD / flèches
- Mouvement au joystick tactile (via PlayerData.touch_move)
- 8 directions (N, S, E, W, NE, NW, SE, SW)
- Animations directionnelles : idle, run, attack par direction (8×3 = 24 animations)
- Vitesse de base 275 px/s, modifiable par items

**Partiellement implémenté :**
- L'effet phlegethon_speed plafonne la vitesse à 550.0, mais le calcul est inline dans `_physics_process` (pas centralisé)

**Absent :**
- Pas de dash/esquive
- Pas de mécanique de terrain (obstacles, zones de ralentissement)

---

## 3.2 Système de tir (JOUEUR)
**Fonctionnel :**
- Auto-tir à cadence fixe (PlayerData.fire_cd)
- 3 modes d'auto-vise : priorité (1) touch_aim_world, (2) souris si mouvement récent (2.0s), (3) auto-aim vers ennemi le plus proche dans 400px
- Auto-aim avec prédiction de trajectoire (calcul du temps de vol + interception)
- Multi-projectiles (PlayerData.projectile_count), spread de 15° par projectile
- Animation d'attaque : démarre, attend frame 1, then tire (délai visuel)
- Vitesse d'animation attaque = float(frame_count) / fire_cd (synchronisé avec la cadence)

**Particularité Serayne :**
- Au lieu de tirer une fireball, invoque un ours une fois par attaque
- L'ours est limité à 1 instance active simultanée

**Absent :**
- Pas de ciblage manuel sur mobile (seulement crosshair visuel)
- Pas de variante de projectile par arme (toutes les Fireball sont identiques)

---

## 3.3 Système d'ennemis
**Fonctionnel :**
- **Aldrich** : ennemi mêlée, poursuite directe du joueur
- **Brutus** : ennemi à distance, tir de projectiles, se positionne hors de portée mêlée
- **Booster** : charge en burst vers le joueur
- **Golgota** : boss à 3 phases avec laser, orbes, minions, shockwave
- Scaling de stats via tables d'indices (niveau 1–19)
- Flag `grabbed` sur BaseEnemy (freeze si ours attaque)
- Saignement (apply_bleed) et ralentissement (slow) sur BaseEnemy
- Dispersion automatique si 90% des ennemis sont groupés dans un rayon de 180px

**Partiellement implémenté :**
- Aldrich utilise NavigationAgent (chemin trouvé) mais les détails de la navigation sont dans le fichier non montré ici
- Golgota n'hérite pas de BaseEnemy, donc ne supporte pas grabbed/bleed/slow (intentionnel pour le boss)

**Absent :**
- Pas d'ennemi de soin (Booster soigne les autres par son nom, mais son implémentation est une charge)
- Pas d'ennemi d'élite (version renforcée d'un ennemi normal)
- Seul 1 boss (Golgota), pas de boss alternatif

---

## 3.4 Système d'items (ÉQUIPEMENT)
**Fonctionnel :**
- 75+ items dans ITEM_DB avec 3 rarités (common/rare/epic)
- Effets calculés dans `PlayerData._recompute()` à chaque ajout
- Effets on-hit/on-kill dans `Player.on_enemy_hit()` et `on_enemy_kill()`
- Items à compteur (stacks multiples possible)
- Items à timer (buffs temporaires via PlayerData.set_timed_buff)
- Items passifs (bonus permanents recalculés dans _recompute)

**Effets on-hit implémentés (dans Player.on_enemy_hit)** :
- Lifesteal (vampire_amulet) : pourcentage des dégâts récupéré en PV
- oeil_gele : tous les 7 coups, 40% slow 2s sur l'ennemi touché
- orbe_mana : tous les 10 coups, tire un projectile bonus vers l'ennemi
- dague_asmodee : saignement 2 dmg/s pendant 3s
- marteau_fissure : critique → saignement 2 dmg/s pendant 3s
- griffe_mephisto : lifesteal plat par coup (lifesteal_flat_per_shot)
- amulette_baal : tous les 3 coups, 20×stacks dégâts à l'ennemi le plus proche

**Effets on-kill implémentés (dans Player.on_enemy_kill)** :
- rage_ring : +2s de rage par stack (+1s par stack supplémentaire), ×1.5 dégâts pendant rage
- sang_courroux : buff "courroux" 5s, +3 dégâts/stack pendant le buff
- anneau_phlegethon : buff vitesse 3s, max 550 px/s
- talisman_ire : +3% dégâts par stack par kill, cap +30%
- chapelet_condamnes : +2 armure par stack par kill, cap 10

**Effets passifs sur dégâts (dans Player._effective_damage)** :
- cor_guerre : ×1.3 dégâts pendant 5s au début de chaque vague
- miroir_supplies : 5%/stack de doubler les dégâts
- oeil_tenebres : +15%/stack si ennemi le plus proche > 300px
- bandeau_inquisiteur : +20%/stack si stationnaire depuis 1s+
- rage_condamne (mercy burst) : ×1.30 dégâts si <25% PV
- sang_courroux buff actif : +3/stack de dégâts bruts

**Effets passifs de défense (dans Player.take_damage)** :
- orbe_limbes : bouclier absorbant 1 attaque, recharge 8s
- phantom_step : +0.4s d'iframes par stack
- plume_rapide : +0.1s d'iframes par stack
- thorn_shield : réfléchit 15%/stack des dégâts reçus à tous les ennemis dans 280px
- Armor (calc_damage_taken dans PlayerData)
- Dodge chance (calc_damage_taken dans PlayerData)

**Items automatiques (hors hit/kill, dans Player._physics_process)** :
- fire_boots : FireTrail toutes les 0.15s en se déplaçant
- auto_grenade : Grenade toutes les 6.0s
- rune_foudre : foudre sur l'ennemi le plus proche toutes les 5.0s (50×stacks dégâts)
- sceptre_tartare : explosion 120px toutes les 4.0s (60×stacks dégâts, AOE)
- tempete_acier (skill) : 12 projectiles en cercle toutes les 10.0s

**Absent :**
- Pas de système de combo ou synergie d'items explicitement géré
- Pas de limite de stacks sur la plupart des items
- Pas de visualisation in-game des effets actifs (buffs/debuffs)

---

## 3.5 Système d'arbre de compétences (Forge Éternelle)
**Fonctionnel :**
- Arbre visuel avec connexions (Line2D) entre nœuds
- 3 états : acheté (or), disponible (violet), verrouillé (gris)
- Reset avec hold 5 secondes
- Coût : 1 boss soul + eternal_souls variables
- Persistance entre runs

**Partiellement implémenté :**
- L'arbre est défini dans PlayerData.SKILL_TREES (données), mais le contenu exact des compétences disponibles par personnage n'est pas fourni dans ce scan
- Les compétences (ex: "tempete_acier", "velocite") sont vérifiées dans le code mais la liste complète n'est pas documentée

---

## 3.6 Système de boutique
**Fonctionnel :**
- 4 emplacements par round, rarité pondérée par niveau
- Choix 1 parmi 3 items par caisse (modal)
- Lock de caisse (persistant entre rounds, max 2 locks)
- Reroll (coûts : 20, 40, 70, 110, puis +50 par reroll supplémentaire)
- Panel de stats détaillé avec décomposition (base + niveau + items)
- Pause automatique du jeu pendant la boutique
- Affichage dans l'éditeur (flag @tool)

---

## 3.7 Système tactile mobile
**Fonctionnel :**
- Détection automatique (DisplayServer.is_touchscreen_available())
- Joystick gauche flottant (spawn au point de toucher)
- Viseur droit (crosshair déplacé par drag)
- Bouton pause injecte InputEventAction("ui_cancel")
- Dead zone 14px, rayon 90px
- Positions dynamiques (% du viewport)

**Absent :**
- Pas de bouton pour les cheat codes sur mobile
- Pas d'accessibilité (taille minimale configurable)

---

## 3.8 Système narratif
**Fonctionnel :**
- 9 panneaux de texte avec typage lettre par lettre (son de frappe par caractère)
- Fond panoramique avec ken burns (pan gauche 10s)
- Crossfade musique (boucle sans coupure)
- Skip panel (bouton dédié)
- Avance au click

---

# 4. POINTS FORTS

## Architecture et design

**1. PlayerData comme couche de données pure**
L'unique autoload centralise toutes les stats calculées. `_recompute()` est appelé à chaque changement d'état (add_item, level up) et reconstruit tout. Aucun script n'a besoin de calculer lui-même ses stats — il lit directement depuis PlayerData. Élimine les désynchronisations.

**2. Items entièrement data-driven**
Les 75+ items sont des dictionnaires dans ITEM_DB. Ajouter un item ne nécessite que de l'ajouter au dictionnaire + ses effets dans `_recompute()` ou les handlers on-hit/on-kill. Pas de classe par item.

**3. Tables de scaling explicites**
Les constantes d'Arena1 (ALDRICH_HP, BRUTUS_CD, etc.) sont des arrays indexés par niveau. L'intention de chaque courbe de progression est immédiatement lisible. Facilite les ajustements de balance.

**4. Signaux découplés correctement**
Player n'appelle pas directement Arena. Arena ne connaît pas Player.gd directement. Les signaux `died`, `continue_round` créent le couplage minimal nécessaire.

**5. TouchControls totalement séparé**
L'input mobile est isolé dans un CanvasLayer séparé. Le Player ne sait pas qu'il est sur mobile — il lit PlayerData.touch_move comme n'importe quelle autre stat.

**6. Dispersion automatique des clusters**
Mécanisme anti-cheesing élégant : si 90% des ennemis sont groupés dans 180px, ils sont téléportés vers les bords avec stagger de 0.7s/ennemi. Évite le camping dans un coin.

**7. Phases boss avec state machine propre**
`_check_phase()` gère les transitions avec des seuils clairs (66%/33% HP). Toutes les variables de phase (_cur_orb_count, _cur_laser_cd, etc.) sont modifiées ensemble à la transition. Lisible.

**8. Laser avec télégraphe jouable**
GolgotaLaser implémente une phase de télégraphe (fade-in progressif + tracking optionnel) séparée de la phase active. Le joueur a un signal visuel clair avant d'être touché. Bonne game feel.

**9. AtlasTexture slicing dynamique**
Les animations de mort (Golgota, Serayne) sont slicées depuis des spritesheets à la volée via AtlasTexture. Pas besoin de pre-découper les frames.

**10. Prédiction de trajectoire de l'auto-aim**
L'auto-aim calcule où l'ennemi SERA quand la balle l'atteint (prédiction = position + velocity * travel_time). Significativement plus précis qu'un aim direct, sans être du homing tracking.

---

# 5. POINTS FAIBLES & PROBLÈMES DÉTECTÉS

## 5.1 Problèmes architecturaux majeurs

### Player.gd est une CLASSE DIEU (682 lignes)
Player.gd gère simultanément :
- Animation setup (2 personnages différents)
- Mouvement + input
- Tir + auto-aim + prédiction
- Tous les effets on-hit de 15+ items (inline dans on_enemy_hit)
- Tous les effets on-kill de 5+ items (inline dans on_enemy_kill)
- Tous les timers d'items passifs (fire_boots, grenade, lightning, sceptre, tempete)
- Gestion de mort et revive
- Camera setup

**Risque** : Toute ajout d'item ou personnage nécessite de modifier cette classe unique. Difficile à maintenir au-delà de ~100 items.

### Character branching inline (sélection de personnage)
Dans `_shoot()` et `_setup_animations()`, le code vérifie `PlayerData.selected_char == "serayne"` et branche. Ce n'est pas du polymorphisme — c'est du if/else hardcodé. Chaque nouveau personnage requiert de modifier Player.gd.

### Arena1._process() ~100 lignes
La fonction `_process()` gère : spawning d'Aldrich, spawning de Brutus, spawning de Booster, vérification du boss, timer de round, fin de round. Trop de responsabilités dans une seule fonction de process.

### Couplage fort via PlayerData comme bus de messages
TouchControls écrit sur PlayerData.touch_move/touch_aim_world. Player lit ces valeurs dans _get_aim_dir(). PlayerData est utilisé comme un bulletin board d'événements temps réel, pas seulement comme stockage de données statiques. Cela mélange deux responsabilités dans le singleton.

### Golgota n'hérite pas de BaseEnemy
Golgota extends CharacterBody2D directement. Il ne peut pas recevoir de saignement, de ralentissement, ni être grabbed. Une safety check explicite (`"grabbed" in _target`) a été ajoutée dans Bear.gd pour éviter un crash. Cette asymétrie est contournée mais n'est pas documentée.

---

## 5.2 Problèmes de performance mobile

### Pas d'object pooling
Chaque tir spawn un nouveau nœud `Fireball.instantiate()` + ajout à la scène + `queue_free()` à la mort. Avec fire_cd rapide (items), auto_grenade, tempete_acier (12 bullets d'un coup), FireTrail toutes les 0.15s, le nombre de nœuds instanciés/libérés par seconde peut être très élevé. Sur mobile bas de gamme, c'est un GC pressure important.

### FireTrail spawnée dans Fireball
Chaque Fireball spawn une FireTrail toutes les 0.1s durant son vol. Si le joueur a fire_cd bas (beaucoup de projectiles en vol simultanément), l'accumulation de FireTrail nodes devient exponentielle.

### _effective_damage() recalcule tout à chaque tir
La fonction itère sur tous les ennemis de la scène 2 fois (pour oeil_tenebres et pour un autre check), appelle roll_crit(), vérifie 10+ conditions item. Elle est appelée dans _shoot() une fois par fire_cd, mais aussi indirectement dans `_spawn_bullet()` à chaque projectile. Si projectile_count = 3, elle est appelée 3 fois par tir avec 3 lancers de crit différents.

> **Note critique** : `_last_is_crit` est set dans `_effective_damage()` et lu dans `_spawn_bullet()`. Avec count=3, chaque bullet peut avoir un résultat de crit différent, ce qui est peut-être l'intention, mais `_shoot()` appelle `_effective_damage()` une fois pour stocker le dmg, puis `_spawn_bullet()` re-appelle `_effective_damage()` pour chaque bullet. Il y a une incohérence potentielle.

### SpriteFrames construit entièrement à chaque _ready()
`_setup_animations()` et `_setup_animations_serayne()` chargent tous les fichiers PNG via `load()` synchrone à l'initialisation. 8 directions × 3 types × 7-9 frames = ~200 fichiers chargés au démarrage. Pas de cache partagé entre instances.

### HUD.refresh_items() reconstruit toute la grille
Appelé après chaque achat d'item et à chaque début de round. Reconstruit tous les nœuds UI d'items depuis zéro à chaque appel.

### StoryIntro._type_next() est récursive via await
La fonction s'appelle elle-même avec `await get_tree().create_timer(CHAR_DELAY).timeout`. Sur un texte de 500 caractères, cela crée 500 coroutines imbriquées dans la call stack. Sur mobile bas de gamme avec des textes longs, risque de crash par stack overflow ou memory pressure.

---

## 5.3 Code dupliqué et magic numbers

### Magic numbers dans Player.gd
- Réduction de vitesse phlegethon : `0.05 * float(...)` → pas de constante nommée
- Soul bonus dans Arena : les valeurs 1, 3, 8, 50 (âmes par ennemi) sont hardcodées dans _on_enemy_died
- Golgota DMG_CAP=60 : non documenté comme décision de design

### Vecteur de spawn Bear hardcodé
`global_position + _last_aim_dir.normalized() * 80.0` : 80px est une valeur magique, dépendante de la scale du sprite joueur.

### Base speed référencée dans ShopMenu mais pas dans PlayerData comme constante
La vitesse de base est 275 (inférée du panneau de stats de ShopMenu), mais elle n't est pas stockée comme constante nommée dans PlayerData.

### _fire_timer override dans _shoot()
```gdscript
$AnimatedSprite2D.sprite_frames.set_animation_speed(atk_anim, float(fc) / PlayerData.fire_cd)
```
Cette ligne écrase la vitesse d'animation de 15.0 FPS définie dans `_setup_animations()` à chaque tir. Si fire_cd est modifié par item entre deux tirs, la vitesse d'animation change dynamiquement. C'est fonctionnel mais potentiellement source de comportements visuels inattendus.

### Récompenses victoire hardcodées
```gdscript
PlayerData.eternal_souls += 100 if _level == 20 else 50
```
Valeurs magiques sans constante nommée.

---

## 5.4 Fonctionnalités absentes ou TODO implicites

- **Unlocked chars "zealot" et "paladin"** : débloqués dans PlayerData mais n'ont ni assets ni scripts ni entrée dans SelectCharacter.CHARACTERS. Les clés sont dans unlocked_chars mais sans effet.
- **Cursed items** : PlayerData a des méthodes has_curse() et get_curse_soul_multiplier(), suggérant un système de malédictions, mais aucun script ne définit ou applique de malédictions visibles.
- **hp_drain_rate** : PlayerData a un champ hp_drain_rate, Player l'utilise pour drainer le HP. Aucun item dans le scan ne le set directement — peut être lié aux malédictions.
- **hp_regen** : PlayerData.hp_regen existe, référencé dans ShopMenu stats panel, mais aucune logique de régénération n'est dans Player._physics_process.
- **dev_no_shoot flag** : PlayerData.dev_no_shoot existe (empêche le tir) mais n'est pas défini ni toggleable dans un menu visible.
- **Signal laser_done** : GolgotaLaser émet ce signal mais Golgota ne l'écoute pas (utilise un timer interne à la place). Le signal est déclaré mais orphelin.
- **Unknown character (slot 3)** : SelectCharacter affiche "??? — BIENTÔT" comme troisième slot verrouillé. Le développeur prévoit un troisième personnage.
- **Settings menu** : Intro.gd a un bouton "settings_btn" non implémenté.
- **Restart depuis GameOver** : GameOver a un bouton restart mais l'implémentation exacte (reset_run + reload scène) n'est pas confirmée dans ce scan.

---

# 6. DONNÉES CHIFFRÉES

## Stats de base du joueur (niveau 1, sans items)
| Stat | Valeur base |
|------|------------|
| HP | BASE_HP_TABLE[1] (valeur exacte dans PlayerData) |
| Dégâts | BASE_DMG_TABLE[1] |
| Vitesse | 275 px/s |
| Fire CD | BASE_CD_TABLE[1] secondes |
| Armure | 0 |
| Crit chance | 5% |
| Crit multiplier | via PlayerData.crit_multiplier |
| Projectiles | 1 |
| Pickup range | 80 px |
| HP regen | 0/s |
| Lifesteal | 0% |
| Dodge | 0% |

*Note : les valeurs exactes des tables de stats de base (BASE_HP_TABLE, BASE_DMG_TABLE, BASE_CD_TABLE) se trouvent dans PlayerData.gd lignes non scannées ici.*

## Stat caps connus
| Stat | Cap |
|------|-----|
| Vitesse phlegethon | 550 px/s |
| Bonus dégâts talisman_ire | +30% |
| Bonus armure chapelet/round | 10 |
| Dégâts par coup sur Golgota (DMG_CAP) | 60 |
| Boosters simultanés | 2 |
| Clés droppées floor 2 /round | 12 |

## Scaling ennemis (tous les niveaux)

### Aldrich (mêlée, niveau 1–19)
| Niv | HP | ATK | Speed |
|-----|-----|-----|-------|
| 1  | 4   | 4   | 90    |
| 2  | 6   | 5   | 92    |
| 3  | 8   | 5   | 94    |
| 4  | 11  | 6   | 96    |
| 5  | 14  | 7   | 100   |
| 6  | 18  | 8   | 105   |
| 7  | 22  | 10  | 110   |
| 8  | 27  | 12  | 115   |
| 9  | 33  | 14  | 120   |
| 10 | 40  | 17  | 126   |
| 11 | 48  | 19  | 132   |
| 12 | 58  | 21  | 138   |
| 13 | 70  | 24  | 145   |
| 14 | 84  | 27  | 152   |
| 15 | 100 | 30  | 160   |
| 16 | 120 | 34  | 168   |
| 17 | 143 | 38  | 176   |
| 18 | 170 | 42  | 185   |
| 19 | 200 | 47  | 194   |

### Brutus (distance, niveau 2–19)
| Niv | HP  | ATK | Shoot CD | Bullet Speed | Range | Spawn Interval |
|-----|-----|-----|----------|-------------|-------|---------------|
| 2  | 22  | 6  | 0.80 | 280 | 500 | 15.0 |
| 3  | 26  | 7  | 0.75 | 300 | 500 | 12.0 |
| 4  | 32  | 8  | 0.70 | 320 | 520 | 10.0 |
| 5  | 38  | 9  | 0.65 | 340 | 520 | 8.5  |
| 6  | 46  | 11 | 0.60 | 360 | 540 | 7.0  |
| 7  | 55  | 13 | 0.55 | 380 | 540 | 6.0  |
| 8  | 66  | 15 | 0.50 | 400 | 560 | 5.0  |
| 9  | 80  | 17 | 0.50 | 420 | 560 | 4.5  |
| 10 | 96  | 20 | 0.45 | 440 | 580 | 4.0  |
| 11 | 110 | 22 | 0.43 | 460 | 600 | 5.0  |
| 12 | 124 | 24 | 0.41 | 480 | 615 | 4.8  |
| 13 | 140 | 27 | 0.39 | 500 | 630 | 4.6  |
| 14 | 158 | 30 | 0.37 | 520 | 645 | 4.4  |
| 15 | 178 | 33 | 0.35 | 540 | 660 | 4.2  |
| 16 | 200 | 37 | 0.33 | 560 | 675 | 4.0  |
| 17 | 226 | 41 | 0.31 | 580 | 690 | 3.8  |
| 18 | 254 | 46 | 0.29 | 600 | 700 | 3.6  |
| 19 | 285 | 51 | 0.27 | 620 | 700 | 3.4  |

### Booster (charge, niveau 11–19)
| Niv | HP  | Spawn Interval |
|-----|-----|----------------|
| 11 | 80  | 25.0s |
| 12 | 95  | 25.0s |
| 13 | 112 | 25.0s |
| 14 | 133 | 25.0s |
| 15 | 157 | 25.0s |
| 16 | 185 | 25.0s |
| 17 | 218 | 25.0s |
| 18 | 255 | 25.0s |
| 19 | 300 | 25.0s |

### Golgota (Boss)
| Stat | Boss niveau 10 | Boss niveau 20 |
|------|---------------|---------------|
| HP max | 1800 | 3600 |
| Dégâts mêlée | 30 | 50 |
| Dégâts laser | 25 | 40 |
| DMG cap subi | 60 | 60 |

### Phases de Golgota
| Phase | Seuil HP | Orbes/CD | Lasers | Laser CD | Speed | Télégraphe | Minions CD | Shockwave |
|-------|----------|---------|--------|---------|-------|-----------|------------|---------|
| 3 | >66% | 5 @ 2.5s | 1 | 6.0s | 35 | 1.2s | — | — |
| 2 | 33–66% | 8 @ 2.0s | 3 | 4.5s | 48 | 0.9s | 12.0s | — |
| 1 | <33% | 12 @ 1.5s | 5 | 3.0s | 60 | 0.6s | 7.0s | 8.0s / 20 dmg |

### Laser spread angles par phase
- Phase 3 : [0°]
- Phase 2 : [0°, -40°, +40°]
- Phase 1 : [0°, -30°, +30°, -65°, +65°]

## Durées des rounds (secondes)
| Niveau | Durée |
|--------|-------|
| 1 | 30s |
| 2 | 34s |
| 3 | 38s |
| 4 | 41s |
| 5 | 45s |
| 6 | 49s |
| 7 | 53s |
| 8 | 56s |
| 9 | 60s |
| 10 | Boss (pas de timer) |
| 11 | 55s |
| 12 | 58s |
| 13 | 61s |
| 14 | 64s |
| 15 | 67s |
| 16 | 70s |
| 17 | 73s |
| 18 | 76s |
| 19 | 80s |
| 20 | Boss (pas de timer) |

## Spawn rate des ennemis
- **Formule** : `max(0.40, 1.40 × 0.78^(level-1))` secondes entre spawns
- **Exemple niveau 1** : 1.40s | **niveau 5** : ~0.57s | **niveau 9** : ~0.26s (plafonné à 0.40s)
- **Modificateur curse_chaos** : ×0.80 sur l'intervalle de spawn et l'intervalle de Brutus
- **Cap ennemis simultanés** : 45
- **Ennemis par spawn** : 1 (niv 1–3), 2 (niv 4–5), 3 (niv 6–7), 4 (niv 8–10), 5 (niv 11+)

## Drop rates de clés
| Condition | Taux |
|-----------|------|
| Niveaux 1–2, 5 premiers kills | 30% |
| Normal (niveau ≤10) | 14% |
| Floor 2 (niveau ≥11) | 8% (max 12/round) |
| Niveaux boss | 0% |
| Victoire boss | +5 clés directement |

## Récompenses en âmes par ennemi
| Ennemi | Âmes base |
|--------|-----------|
| Aldrich | 1 |
| Brutus | 3 |
| Booster | 8 |
| Boss | 50 |
| Formule : `max(1, ceil(base × (1 + soul_bonus_rate) × curse_soul_multiplier))` |

## Récompenses fin de run
| Condition | Eternal Souls |
|-----------|--------------|
| Victoire boss niveau 10 | 50 |
| Victoire boss niveau 20 | 100 |

## Probabilités de rareté boutique par niveau
| Niveau | Epic | Rare | Common |
|--------|------|------|--------|
| 1 | 0% | 10% | 90% |
| 2 | 2% | 18% | 80% |
| 3 | 5% | 25% | 70% |
| 4 | 10% | 35% | 55% |
| 5 | 15% | 45% | 40% |
| 6 | 25% | 45% | 30% |
| 7 | 40% | 40% | 20% |
| 8 | 55% | 35% | 10% |
| 9+ | 70% | 25% | 5% |

## Coûts boutique
| Rareté | Clés | Reroll 1 | Reroll 2 | Reroll 3 | Reroll 4 | Reroll 5+ |
|--------|------|---------|---------|---------|---------|----------|
| Common | 1 | 20 âmes | 40 âmes | 70 âmes | 110 âmes | +50/reroll |
| Rare | 4 | | | | | |
| Epic | 8 | | | | | |

## Constantes du joueur
| Constante | Valeur |
|-----------|--------|
| IFRAMES base | 0.5s |
| IFRAMES + phantom_step | +0.4s par stack |
| IFRAMES + plume_rapide | +0.1s par stack |
| DEATH_DELAY | 2.5s (avant signal died) |
| AUTO_AIM_RANGE | 400 px |
| MOUSE_OVERRIDE_DUR | 2.0s |
| RAGE_DURATION | 2.0s (+1.0s/stack supplémentaire) |
| GRENADE_CD | 6.0s |
| TRAIL_CD | 0.15s |
| TEMPETE_CD | 10.0s |
| COR_GUERRE_DUR | 5.0s |
| Bear spawn offset | 80 px du joueur dans direction de visée |
| Spread multi-projectiles | 15° par projectile |

## Constantes de l'ours (Bear)
| Constante | Valeur |
|-----------|--------|
| SPEED | 420.0 px/s |
| RANGE | 350.0 px (rayon de détection) |
| ATTACK_DIST | 60.0 px (distance d'attaque) |
| AOE_RADIUS | 120.0 px (rayon de dégâts) |

## Constantes d'animation joueur
| Animation | FPS |
|-----------|-----|
| run (toutes directions) | 10.0 |
| idle (toutes directions) | 5.0 |
| attack (neophyte/serayne) | float(frame_count) / fire_cd (dynamique) |
| death (neophyte) | 8.0 |
| death (serayne) | 8.0 (6 frames, 3×2 spritesheet, 341×256px/frame) |

## Constantes de la caméra
| Paramètre | Valeur |
|-----------|--------|
| Zoom | 1.2× |
| Limite gauche | 0 |
| Limite haut | 0 |
| Limite droite | 1920 |
| Limite bas | 1080 |
| Position smoothing speed | 6.0 |

## Constantes de la dispersion d'ennemis
| Paramètre | Valeur |
|-----------|--------|
| Intervalle de vérification | 2.0s |
| Rayon de cluster | 180 px |
| Seuil de déclenchement | 90% des ennemis |
| Délai entre téléportations | 0.7s par ennemi |

## Constantes du joystick mobile
| Paramètre | Valeur |
|-----------|--------|
| Rayon joystick | 90.0 px |
| Dead zone | 14.0 px |
| Base (cercle extérieur) | 200×200 px |
| Knob (cercle intérieur) | 88×88 px |
| Crosshair viseur | 64×64 px |
| Position joystick gauche | 11.5% x, 80% y |
| Position viseur droit | 87.5% x, 87% y |

## Items à effets numérotés (effets exacts connus)
| Item | Effet exact |
|------|-------------|
| rune_foudre | 50 × stacks dégâts, toutes les 5.0s, ennemi le plus proche |
| sceptre_tartare | 60 × stacks dégâts, toutes les 4.0s, AOE 120px sur ennemi le plus proche |
| amulette_baal | 20 × stacks dégâts, tous les 3 hits, ennemi le plus proche |
| thorn_shield | 15% × stacks des dégâts reçus réfléchis, rayon 280px |
| oeil_gele | 40% slow 2.0s sur ennemi, tous les 7 hits |
| orbe_mana | projectile bonus vers ennemi, tous les 10 hits |
| dague_asmodee | saignement 2 dmg/s pendant 3.0s |
| marteau_fissure | crit → saignement 2 dmg/s pendant 3.0s |
| orbe_limbes | bouclier 1 attaque, recharge 8.0s |
| sang_courroux | on-kill : buff 5.0s → +3 dmg/stack |
| anneau_phlegethon | on-kill : buff vitesse 3.0s → max 550 px/s, +5%/stack |
| talisman_ire | on-kill : +3%/stack dmg (cap +30%) |
| chapelet_condamnes | on-kill : +2 armor/stack (cap 10) |
| miroir_supplies | 5%/stack de doubler les dégâts |
| oeil_tenebres | +15%/stack dmg si ennemi le plus proche > 300px |
| bandeau_inquisiteur | +20%/stack dmg si stationnaire ≥1s |
| sang_courroux buff | +3 dmg bruts/stack pendant le buff |
| mercy burst (interne) | <25% HP → rage_condamne 5.0s (×1.30 dmg), CD 20.0s |

---

# 7. QUESTIONS OUVERTES

## 7.1 Architecture

**Q1 : Comment ajouter un 3ème personnage ?**
Actuellement, les personnages sont définis dans SelectCharacter.CHARACTERS (hardcodé), les animations dans Player.gd (branches if/else), et les SKILL_TREES dans PlayerData. Pour ajouter un personnage, il faut modifier 3 fichiers différents sans interface unifiée. Y a-t-il un plan pour centraliser cela ?

**Q2 : Les items sont-ils vraiment stackables sans limite ?**
item_count() retourne le nombre d'instances d'un même item. La plupart des effets multiplient par item_count. Rien n'empêche d'avoir 10 rune_foudre. Est-ce intentionnel (build extrêmes) ou y a-t-il des caps prévus ?

**Q3 : La base de données d'items (ITEM_DB 75+) — les effets exactement ?**
Ce scan n'a pas extrait le contenu complet de ITEM_DB. Les effets passifs calculés dans `_recompute()` ne sont pas tous documentés ici. Des items comme "fire_boots", "auto_grenade", "double_canon", "vampire_amulet", "phantom_step" sont référencés dans le code mais leurs valeurs exactes sont dans PlayerData.gd non-listé ici.

**Q4 : hp_regen est dans PlayerData mais pas dans Player._physics_process**
Le panel de stats de ShopMenu affiche hp_regen. Player ne l'applique pas. Est-ce un bug ou une fonctionnalité différée ?

**Q5 : dev_no_shoot est utilisé mais jamais settable**
`PlayerData.dev_no_shoot` est lu dans _shoot() pour bloquer le tir. Il n'y a pas de toggle visible dans le code. Est-ce un reste de debugging ou une fonctionnalité prévue ?

---

## 7.2 Balance

**Q6 : Pourquoi Brutus spawn interval re-monte au niveau 11 ?**
BRUTUS_INTERVAL[10]=4.0, BRUTUS_INTERVAL[11]=5.0 — il y a une remontée d'intervalle au niveau 11 (plus rare). Intentionnel pour équilibrer l'arrivée des Boosters ?

**Q7 : Le cap de clés floor2 (12/round) est-il adapté au nombre d'ennemis ?**
Au niveau 11+, 5 ennemis spawntent par cycle, avec ~0.40s d'intervalle minimum. En 55-80s de round, on peut tuer plusieurs centaines d'ennemis. 12 clés maximum au taux de 8% = ~150 kills pour saturer le drop. Est-ce la courbe voulue ?

**Q8 : La Serayne a 3 HP de base contre 5 pour Neophyte**
Les statssheet dans SelectCharacter.CHARACTERS montrent hp=3 pour Serayne. Mais HP dans le jeu est une stat numérique (PlayerData.max_hp), pas directement les "points" affichés dans le menu. Les 3 points visuels correspondent-ils exactement à 3 PV dans PlayerData ?

**Q9 : Difficulté relative des deux boss**
Le boss niveau 10 (standard) a 1800 HP et DMG 30/laser 25. Le boss niveau 20 a 3600 HP et DMG 50/laser 40. Le joueur au niveau 20 a 9+ niveaux d'items. Est-ce que la courbe de puissance du joueur dépasse suffisamment la courbe du boss pour que niveau 20 soit plus difficile que niveau 10 mais pas trivial ?

---

## 7.3 Techniques / bugs potentiels

**Q10 : Y a-t-il un NavigationServer mesh configuré pour Aldrich ?**
Aldrich utilise `_find_path_to_player()` avec NavigationAgent, mais l'arène doit avoir un NavigationRegion2D avec un mesh baked pour que la navigation fonctionne. Ce mesh est dans la scène Arena1.tscn (non examinée ici). S'il n'est pas baked, Aldrich n'a pas de chemin valide.

**Q11 : La prédiction auto-aim fonctionne-t-elle avec Brutus ?**
La prédiction utilise `(nearest as CharacterBody2D).velocity`. Brutus utilise bien CharacterBody2D + move_and_slide, donc velocity est bien défini. Mais si Brutus est à l'arrêt en train de viser (mode shooting), velocity = 0 et la prédiction = position actuelle (correct). OK.

**Q12 : L'ours peut-il mourir ?**
Bear.gd ne définit pas de méthode take_damage() ni de hp. L'ours est indestructible. Est-ce intentionnel ?

**Q13 : Que se passe-t-il si _active_bear est non null mais que le nœud est queue_free'd ?**
`is_instance_valid(_active_bear)` est vérifié dans `_invoke_bear()`. Si l'ours se détruit lui-même (fin d'animation, hors scène), `_active_bear` sera invalide au prochain appel → un nouvel ours pourra spawner. Correct. Mais il n'y a pas de `_active_bear = null` explicite dans Bear.gd — la référence dans Player reste invalide jusqu'au prochain is_instance_valid check.

**Q14 : La récursion de StoryIntro._type_next() peut-elle causer un stack overflow ?**
Avec CHAR_DELAY=0.04s et `await timer`, chaque appel suspend via une coroutine. Ce n'est pas un stack overflow classique mais une accumulation de coroutines. Godot 4 gère les coroutines proprement, mais sur du texte de 300+ caractères avec des devices lents, cela crée 300 coroutines suspendues simultanément. Problème probable sur mobile très bas de gamme.

**Q15 : fire_cd peut-il être modifié entre le spawn d'un Fireball et sa collision ?**
Non, car `dmg` est calculé au spawn et stocké dans Fireball.init(). Mais `_last_is_crit` dans Player est partagé : si un item applique un effet entre le spawn et la collision, cela n'affecte pas le crit déjà calculé. OK en pratique.

---

## 7.4 Décisions de design non documentées

**Q16 : Pourquoi Golgota a un DMG_CAP=60 mais pas les ennemis normaux ?**
Le commentaire dans le code dit "Carapace d'Orgueil — plafonne chaque coup pour lisser les builds burst". Pourquoi uniquement sur le boss ? Les ennemis normaux peuvent donc mourir en 1 coup si les dégâts sont suffisants.

**Q17 : Le système de malédictions est-il implémenté ?**
PlayerData a has_curse(), get_curse_soul_multiplier(), et Arena1 les utilise pour spawn_interval. Mais aucune mécanique de comment le joueur acquiert une malédiction n'est visible dans ce scan.

**Q18 : Le Serayne ne tire aucun projectile — comment les items "projectile" s'appliquent-ils ?**
Serayne n'appelle jamais `_spawn_bullet()`. Les items comme orbe_mana (bonus projectile), tempete_acier (12 projectiles), auto_grenade, et l'invocation de l'ours sont tous disponibles. Mais "double_canon" (projectile_count+1) n'a aucun effet sur Serayne puisqu'il n'y a pas de boucle de spawn_bullet. Est-ce intentionnel ?

---

# ANNEXE : FLUX DE SCÈNES

```
MainMenu.tscn
  → [Bouton Start] → Intro.tscn
  
Intro.tscn
  → [Bouton Play] → StoryIntro.tscn
  
StoryIntro.tscn
  → [9 panneaux + fade] → SelectCharacter.tscn
  
SelectCharacter.tscn
  → [Bouton Entrer] → Arena1.tscn (avec reset_run())
  → [Bouton Retour] → MainMenu.tscn
  → [Bouton Grimoire] → SkillTreeOverlay (overlay dans la même scène)
  
Arena1.tscn (scène principale de jeu)
  └─ Enfants : Player, HUD, ShopMenu, PauseMenu, GameOver, TouchControls
  
  → [Player.died] → GameOver visible (rester sur Arena1.tscn)
  → [ShopMenu visible] → pause jeu
  → [Boss niveau 20 tué] → reset_run() → SelectCharacter.tscn
  → [Game Over restart] → Arena1.tscn (rechargement)
  → [Game Over menu] → MainMenu.tscn
```

---

*Document généré le 2026-04-29 à partir du scan de 30 fichiers GDScript du projet Codex Inferno.*  
*Modèle source utilisé pour la génération : Claude Sonnet 4.6*
