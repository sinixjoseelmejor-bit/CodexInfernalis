# CODEX INFERNALIS — PROPOSITION DE BALANCE
### Inspirée de Brotato & Risk of Rain

---

## PHILOSOPHIE

**Brotato** maintient toujours une "friction" : même au wave 15, chaque ennemi demande 2-4 tirs pour mourir.
La courbe DPS du joueur suit la courbe HP des ennemis — personne ne devient Dieu avant les dernières vagues.

**Risk of Rain** traite les boss comme un défi de chorégraphie : tu dois esquiver des patterns pendant 20-60 secondes,
pas juste vider une barre de vie en 8 secondes. La survie est précieuse tout au long du run.

**Problèmes actuels identifiés :**
- DPS max (55/s) vs Aldrich 3 HP = kills instantanés dès niveau 3 → aucune friction
- Golgota 400 HP à DPS max ~40/s = mort en ~10s → pas un vrai boss
- Brutus ignorable (portée 500px, cadence 0.6s) → pas assez menaçant en late
- Items % dégâts s'accumulent trop vite (20% + 10% + 10% + 15% = 55% dmg d'un coup)
- Cadence plancher 0.2s (5 tirs/s) est extrême et diminue la sensation de chaque tir

---

## 1. STATS DE BASE — MODIFICATIONS

| Stat       | ACTUEL          | PROPOSÉ         | Raison                                       |
|------------|-----------------|-----------------|----------------------------------------------|
| HP max     | 5               | 5               | Inchangé — démarrage fragile est correct      |
| Dégâts     | 1               | 1               | Inchangé                                      |
| Vitesse    | 250             | **275**         | +10% de réactivité de base, feel plus nerveux |
| Fire CD    | 0.90s           | **0.85s**       | Tir légèrement plus rapide dès le départ      |
| Floor CD   | 0.20s (min)     | **0.25s (min)** | Empêche les valeurs absurdes en late          |

---

## 2. UPGRADES DE RUN — MODIFICATIONS

Les coûts restent identiques : **10 → 25 → 50 → 100 → 200 âmes** (385 total / stat)

| Stat       | Formule ACTUELLE                | Formule PROPOSÉE                | Différence au max      |
|------------|----------------------------------|----------------------------------|------------------------|
| HP max     | 5 + lvl × 2                     | **inchangé**                     | max 15 → 15 (=)        |
| Dégâts     | 1 + lvl                         | **inchangé**                     | max 6 → 6 (=)          |
| Vitesse    | 250 + lvl × 25                  | **275 + lvl × 20**               | max 375 → 375 (=)      |
| Cadence    | 0.90 − lvl × 0.12               | **0.85 − lvl × 0.09**            | max 0.30s → **0.40s**  |

> La cadence est le levier principal. Réduire le gain par niveau de 0.12 → 0.09 serre la cadence max
> à 0.40s (était 0.30s), soit ~2.5 tirs/s au lieu de ~3.3 tirs/s avec items pris en compte.

**Tableau cadence détaillé (comparatif) :**

| Niveau | ACTUEL   | PROPOSÉ  |
|--------|----------|----------|
| 0      | 0.90s    | 0.85s    |
| 1      | 0.78s    | 0.76s    |
| 2      | 0.66s    | 0.67s    |
| 3      | 0.54s    | 0.58s    |
| 4      | 0.42s    | 0.49s    |
| 5 MAX  | **0.30s**| **0.40s**|

---

## 3. ITEMS — COMMUNS (inchangés)

Les flat bonuses sont sains. Ils apportent une progression claire sans courbe exponentielle.
**Aucun changement.**

| ID             | Nom              | flat_hp | flat_dmg | flat_spd | flat_cd |
|----------------|------------------|---------|----------|----------|---------|
| ampoule_vie    | Ampoule de Vie   | +2      |          |          |         |
| coeur_pierre   | Cœur de Pierre   | +3      |          |          |         |
| bouclier_bois  | Bouclier de Bois | +4      |          |          |         |
| dent_loup      | Dent de Loup     |         | +1       |          |         |
| epee_courte    | Épée Courte      |         | +1       |          |         |
| pierre_aceree  | Pierre Acérée    |         | +2       |          |         |
| plume_rapide   | Plume Rapide     |         |          | +15      |         |
| bottes_course  | Bottes de Course |         |          | +12      |         |
| anneau_vitesse | Anneau de Vitesse|         |          | +20      |         |
| bague_tir      | Bague du Tireur  |         |          |          | −0.08s  |

---

## 4. ITEMS — RARES (% rebalancés)

Principe Brotato : les items de vitesse/survie sont undervalued, les items de dégâts sont overvalued.
→ nerf léger des % dégâts, buff des % vitesse (la vitesse aide à esquiver, renforce le gameplay).

| ID             | Nom               | ACTUEL pct     | PROPOSÉ pct      | Changement              |
|----------------|-------------------|----------------|------------------|-------------------------|
| vampire_amulet | Amulette Vampire  | +10% HP max    | **+8% HP max**   | −2% (léger nerf)        |
| fire_boots     | Bottes de Feu     | +8% vitesse    | **+12% vitesse** | +4% (buff !)            |
| thorn_shield   | Bouclier Épineux  | +10% dégâts    | **+8% dégâts**   | −2% (léger nerf)        |
| rage_ring      | Anneau de Rage    | +10% dégâts    | **+8% dégâts**   | −2% (léger nerf)        |
| phantom_step   | Pas Fantôme       | +8% vitesse    | **+12% vitesse** | +4% (buff !)            |

> En bufant la vitesse, on encourage un gameplay plus mobile et frénétique — exactement l'esprit de Brotato.
> Le reflect de thorn_shield et l'enrage de rage_ring restent inchangés (effets actifs).

---

## 5. ITEMS — ÉPIQUES (% fortement réduits)

Les épiques actuels représentent +55% de dégâts combinés (20+10+10+15). C'est trop.
Cible : les épiques restent puissants, mais ne font pas exploser la courbe à eux seuls.

| ID             | Nom                | ACTUEL pct_dmg/cd | PROPOSÉ pct_dmg/cd | Changement          |
|----------------|--------------------|-------------------|--------------------|---------------------|
| auto_grenade   | Grenade Auto.      | +20% dégâts       | **+15% dégâts**    | −5%                 |
| storm_ring     | Anneau de Tempête  | +15% cadence      | **+12% cadence**   | −3%                 |
| soul_harvester | Faucheur d'Âmes    | +25% HP max       | **+20% HP max**    | −5%                 |

> L'effet actif de soul_harvester (âmes ×(1+count)) reste inchangé — c'est la mécanique économique.

---

## 6. GRIMOIRE ÉTERNEL — SKILL TREE (rebalancé)

Le nœud final `MAÎTRISE NOIRE` à +15% dmg permanent est trop fort (empilé sur les items).
On réduit tous les % offensifs, on améliore légèrement les défensifs pour donner de vraies options.

```
         [SOUFFLE INFERNAL]    inchangé
              +1 dégât (flat)
           /                \
  [CUIR DE DÉMON]      [ÂMES LÉGÈRES]
   +3 HP → +4 HP         +15% → +12% vitesse
        |                       |
  [SANG MAUDIT]        [FRAPPE RAPIDÉE]
   +5 HP → +6 HP         +8% → +6% cadence
           \                   /
          [MAÎTRISE NOIRE]
           +15% → +10% dégâts
```

| Nœud            | ACTUEL       | PROPOSÉ       | Raison                                        |
|-----------------|--------------|---------------|-----------------------------------------------|
| Souffle Infernal| +1 dmg       | **inchangé**  | Nœud racine doit sentir la puissance          |
| Cuir de Démon   | +3 HP        | **+4 HP**     | Branche défensive plus attrayante              |
| Âmes Légères    | +15% vitesse | **+12%**      | 15% empilé avec boots était trop fort          |
| Sang Maudit     | +5 HP        | **+6 HP**     | Branche défensive plus attrayante              |
| Frappe Rapidée  | +8% cadence  | **+6%**       | Cadence déjà nerfée via upgrade, évite l'excès|
| Maîtrise Noire  | +15% dégâts  | **+10%**      | Permanent = doit rester modéré, pas dominant  |

---

## 7. ENNEMIS — MODIFICATIONS

### Aldrich : introduire un scaling HP par niveau

**Problème actuel :** Aldrich reste à 3 HP du niveau 1 au 6. Dès niveau 3 avec dmg upgrade 2,
le joueur fait 3 dmg → 1-shot Aldrich en permanence. Zéro friction.

**Référence Brotato :** en wave 1-5, les enemies demandent 2-4 tirs. Wave 15-20, encore 2-4 tirs.
La courbe suit le joueur.

**Formule proposée :** `hp = int(3 × pow(1.35, niveau − 1))`

| Niveau | HP Aldrich ACTUEL | HP Aldrich PROPOSÉ | Tirs nécessaires (dmg=6 upgrades max) |
|--------|-------------------|--------------------|---------------------------------------|
| 1      | 3                 | **3**              | 3 tirs (dmg=1 base)                   |
| 2      | 3                 | **4**              | 2 tirs (dmg=2)                        |
| 3      | 3                 | **5**              | 2 tirs (dmg=3)                        |
| 4      | 3                 | **7**              | 2 tirs (dmg=4)                        |
| 5      | 3                 | **10**             | 2 tirs (dmg=5)                        |
| 6      | 3                 | **13**             | 2 tirs (dmg=6 max) ou 1 si dmg+items  |

> Résultat : le joueur tire toujours en rafale, les corps tombent rapidement, mais il faut quand même viser.
> Sentiment frénétique préservé, trivialité éliminée.

**Modification code Arena1.gd :**
```gdscript
# Remplacer :
a.key_drop_chance = max(0.03, 0.15 - (_level - 1) * 0.024)
# Ajouter après :
a.hp = int(3 * pow(1.35, _level - 1))
```
*(Aldrich.gd doit avoir `var hp := 3` comme valeur par défaut, puis Arena1 override)*

---

### Brutus : HP scaling plus agressif

**Problème actuel :** en niveau 6, Brutus a 31 HP — mourait en ~5 tirs à DPS max original.
Avec le DPS nerf, on devrait maintenir la même TTK (time-to-kill) en augmentant le HP.

**Formule actuelle :** `15 + (niveau − 2) × 4`
**Formule proposée :** `15 + (niveau − 2) × 6`

| Niveau | HP ACTUEL | HP PROPOSÉ | TTK à DPS max proposé (36/s) |
|--------|-----------|------------|-------------------------------|
| 2      | 15        | **15**     | ~0.4s (inchangé)              |
| 3      | 19        | **21**     | ~0.6s                         |
| 4      | 23        | **27**     | ~0.75s                        |
| 5      | 27        | **33**     | ~0.9s                         |
| 6      | 31        | **39**     | ~1.1s — Brutus est une vraie menace |

**Modification code Arena1.gd :**
```gdscript
# Remplacer :
b.hp = 15 + (_level - 2) * 4
# Par :
b.hp = 15 + (_level - 2) * 6
```

---

### Golgota : HP triplé pour un vrai combat de boss

**Problème actuel :** 400 HP à DPS max original (~40/s) = 10 secondes. Pas un boss, c'est un miniboss.

**Référence Risk of Rain :** un boss doit survivre assez longtemps pour deployer PLUSIEURS cycles de patterns.
Golgota a orbes (2.5s) + laser (6s) → un bon combat = 3-4 cycles lasers = **au moins 25-30 secondes**.

| HP Golgota | DPS joueur typique (~10/s) | DPS joueur max (36/s) | Cycles laser (6s) |
|------------|---------------------------|----------------------|-------------------|
| 400 ACTUEL | 40s                       | **10s** ← trop court | 1-2               |
| **700 PROPOSÉ** | **70s**            | **19s**              | 3-4 cycles max    |

**Modification Golgota.gd :** `hp = 700` (au lieu de 400)

---

## 8. SHOP — PETIT AJUSTEMENT ÉCONOMIE

**Problème :** le premier reroll coûte 50 âmes = 2 rounds complets de farm au niveau 1.
Dans Brotato, le reroll est encouragé — il fait partie du gameplay de draft.

**Proposé :** premier reroll à **30 âmes** (au lieu de 50), +50 par reroll suivant.

**Modification ShopMenu.gd :** `_reroll_cost := 30` au lieu de `_reroll_cost := 50`

---

## 9. DPS COMPARATIF — ACTUEL vs PROPOSÉ

### Version ACTUELLE (max tout)

| Situation                              | Dmg | fire_cd | DPS      |
|----------------------------------------|-----|---------|----------|
| Base (no upgrades)                     | 1   | 0.90s   | 1.11/s   |
| Upgrades max (nv.5 tout)               | 6   | 0.30s   | 20.0/s   |
| + skill tree complet                   | 8   | 0.276s  | 29.0/s   |
| + thorn + rage + auto_grenade          | 11  | 0.276s  | 39.9/s   |
| + storm_ring + bague_tir               | 11  | 0.202s  | **54.5/s** ← trop |

### Version PROPOSÉE (max tout)

| Situation                              | Dmg | fire_cd | DPS      |
|----------------------------------------|-----|---------|----------|
| Base (no upgrades)                     | 1   | 0.85s   | 1.18/s   |
| Upgrades max (nv.5 tout)               | 6   | 0.40s   | 15.0/s   |
| + skill tree complet                   | 7*  | 0.376s  | 18.6/s   |
| + thorn + rage + auto_grenade (8+8+15%)| 9   | 0.376s  | 23.9/s   |
| + storm_ring (12%) + bague_tir         | 9   | 0.25s†  | **36.0/s** ✓ |

> *`int(7 × 1.10) = 7` — note: arrondi à l'entier peut légèrement varier
> †floor à 0.25s atteint avec bague_tir + storm + Frappe Rapidée

**Réduction DPS max : 54.5 → 36.0 = −34%**
Le jeu reste frénétique, les ennemis ne deviennent plus triviaux.

---

## 10. FRICTION PAR NIVEAU (version proposée)

Aldrich tirs-avant-mort avec des dégâts typiques de progression normale :

| Niveau | HP Aldrich | Dmg joueur typique | Tirs pour tuer | Sensation               |
|--------|------------|--------------------|----------------|-------------------------|
| 1      | 3          | 1                  | 3 tirs         | Fragile, doit courir    |
| 2      | 4          | 2                  | 2 tirs         | Rapide mais présent     |
| 3      | 5          | 3                  | 2 tirs         | Flux constant           |
| 4      | 7          | 4                  | 2 tirs         | Vagues denses           |
| 5      | 10         | 5                  | 2 tirs         | Chaos contrôlé (Brotato)|
| 6      | 13         | 6                  | 2-3 tirs       | Survie intense          |

> Toujours 2 tirs → toujours besoin de viser → frénétique mais pas vide.

---

## 11. RÉSUMÉ DES CHANGEMENTS À APPLIQUER

### PlayerData.gd

```gdscript
# Base stats
var speed   := 275.0          # était 300.0 (base + 250, maintenant 275)
var fire_cd := 0.85           # était 0.9

# _recompute() :
var base_spd := 275.0 + lvl_speed * 20.0        # était 250 + lvl * 25
var base_cd  := 0.85 - lvl_fire_cd * 0.09       # était 0.90 - lvl * 0.12
fire_cd = max(0.25, (base_cd + flat_cd) * (1.0 - pct_cd))  # floor 0.25 (était 0.20)
```

### ITEM_DB (PlayerData.gd)

```gdscript
"vampire_amulet": {..., "pct_hp":   0.08},  # était 0.10
"fire_boots":     {..., "pct_speed": 0.12},  # était 0.08
"thorn_shield":   {..., "pct_damage":0.08},  # était 0.10
"rage_ring":      {..., "pct_damage":0.08},  # était 0.10
"phantom_step":   {..., "pct_speed": 0.12},  # était 0.08
"auto_grenade":   {..., "pct_damage":0.15},  # était 0.20
"storm_ring":     {..., "pct_fire_cd":0.12}, # était 0.15
"soul_harvester": {..., "pct_hp":   0.20},   # était 0.25
```

### SKILL_TREES (PlayerData.gd)

```gdscript
{"id":"demon_skin",   ..., "flat_hp":4},         # était 3
{"id":"light_souls",  ..., "pct_speed":0.12},     # était 0.15
{"id":"cursed_blood", ..., "flat_hp":6},          # était 5
{"id":"swift_strike", ..., "pct_fire_cd":0.06},   # était 0.08
{"id":"dark_mastery", ..., "pct_damage":0.10},    # était 0.15
```

### Arena1.gd

```gdscript
# Dans _spawn_aldrich() — ajouter après key_drop_chance :
a.hp = int(3 * pow(1.35, _level - 1))

# Dans _spawn_brutus() :
b.hp = 15 + (_level - 2) * 6    # était * 4

# Remplacer les constantes :
const BASE_SPAWN_INTERVAL  := 3.00   # était 2.35
const MIN_SPAWN_INTERVAL   := 0.60   # était 0.35
const BRUTUS_BASE_INTERVAL := 22.0   # était 18.0
const BRUTUS_MIN_INTERVAL  := 9.0    # était 8.0

# Remplacer _spawn_interval() et _spawn_count() par :
func _spawn_interval() -> float:
    return max(MIN_SPAWN_INTERVAL, BASE_SPAWN_INTERVAL * pow(0.74, _level - 1))

func _spawn_count() -> int:
    return 1    # flux continu, plus de bursts
```

### Golgota.gd

```gdscript
var hp := 700    # était 400
```

### ShopMenu.gd

```gdscript
var _reroll_cost := 30    # était 50
```

---

## 12. SPAWNS — ANALYSE ET REFONTE

### Le problème : deux pics de difficulté brutaux

La formule `_spawn_count = 1 + (niveau-1) / 2` (division entière) passe de 1 → 2 → 3 en créant
des paliers qui doublent brusquement le nombre d'ennemis sur un seul niveau.

**Aldrich spawné par round de 90s (ACTUEL) :**

| Niveau | Intervalle | Count | Total/round | Croissance |
|--------|------------|-------|-------------|------------|
| 1      | 2.35s      | 1     | **38**      | —          |
| 2      | 2.13s      | 1     | **42**      | +11%       |
| 3      | 1.91s      | **2** | **94**      | **+124% ← pic** |
| 4      | 1.69s      | 2     | **107**     | +14%       |
| 5      | 1.47s      | **3** | **184**     | **+72% ← pic**  |
| 6      | 1.25s      | 3     | **216**     | +17%       |

En niveau 3 la difficulté double d'un coup. En niveau 5 elle re-saute de 72%.
Entre les deux pics (3→4, 5→6) la progression est quasi nulle (+14%, +17%).
Le joueur est soit submergé soit sur-puissant selon le niveau.

---

### La solution : croissance exponentielle lisse (~35%/niveau)

**Remplacer les deux fonctions par une seule formule :**

```gdscript
# count = 1 toujours : flux continu au lieu de bursts
# intervalle = décroissance exponentielle régulière
func _spawn_interval() -> float:
    return max(0.60, 3.0 * pow(0.74, _level - 1))

func _spawn_count() -> int:
    return 1
```

**Résultat :**

| Niveau | Intervalle | Total/round | Croissance |
|--------|------------|-------------|------------|
| 1      | 3.00s      | **30**      | —          |
| 2      | 2.22s      | **40**      | +35%       |
| 3      | 1.64s      | **55**      | +35%       |
| 4      | 1.22s      | **74**      | +35%       |
| 5      | 0.90s      | **100**     | +35%       |
| 6      | 0.66s      | **136**     | +36%       |

Chaque niveau apporte exactement ~35% d'ennemis supplémentaires. Pas de surprise, pas de mur.

> **Note :** level 1 passe de 38 à 30 spawns. C'est intentionnel — le départ est légèrement plus calme
> pour que le joueur comprenne les mécaniques avant d'être submergé.

---

### Flux continu vs bursts

Avec count=1, les ennemis arrivent un par un en flux régulier plutôt qu'en vagues de 2-3.

| Aspect          | Bursts (actuel)                    | Flux continu (proposé)            |
|-----------------|------------------------------------|-----------------------------------|
| Sensation       | "Vague d'ennemis" soudaine         | Pression constante et montante    |
| Danger          | Pics de danger ponctuels           | Tension permanente                |
| Stratégie       | Réagir aux bursts                  | Toujours en mouvement             |
| Référence       | —                                  | **Brotato** (ennemis en continu)  |

---

### Brutus — ajustements mineurs

Le Brutus n'a pas de problème de paliers (formule linéaire), mais avec ses HP augmentés (×6)
il devient plus menaçant. Ajuster légèrement l'intervalle pour compenser :

**Formule actuelle :** `max(8.0, 18.0 − (niveau−2) × 1.5)`
**Formule proposée :** `max(9.0, 22.0 − (niveau−2) × 1.5)`

| Niveau | Brutus ACTUEL | Brutus PROPOSÉ | Brutus/round (proposé) |
|--------|--------------|----------------|------------------------|
| 2      | 18.0s        | **22.0s**      | 4 Brutus               |
| 3      | 16.5s        | **20.5s**      | 4-5 Brutus             |
| 4      | 15.0s        | **19.0s**      | 5 Brutus               |
| 5      | 13.5s        | **17.5s**      | 5 Brutus               |
| 6      | 12.0s        | **16.0s**      | 5-6 Brutus             |
| min    | 8.0s         | **9.0s**       | —                      |

> Avec 39 HP au niveau 6 (×6 HP) et TTK de ~2s à DPS max, 5-6 Brutus par round
> signifie 1-2 vivants simultanément en permanence. C'est la pression voulue.

---

### Analyse finale : ennemis vivants simultanément (estimé)

Avec les nouvelles valeurs (Aldrich HP proposé, DPS joueur ~12/s en milieu de run) :

| Niveau | Aldrich vivants en simultané | Brutus vivants en simultané |
|--------|------------------------------|------------------------------|
| 1      | ~3-5                         | 0                            |
| 2      | ~5-8                         | 0-1                          |
| 3      | ~8-12                        | 1                            |
| 4      | ~12-18                       | 1-2                          |
| 5      | ~18-25                       | 1-2                          |
| 6      | ~25-35                       | 2                            |

Niveau 6 : 25-35 Aldrich + 2 Brutus = **écran rempli mais survivable** → sensation Brotato/Risk of Rain.

---

## 13. CE QUI NE CHANGE PAS ET POURQUOI

| Système                 | Raison de garder               |
|-------------------------|-------------------------------|
| HP upgrades (5→15)      | Progression saine et lisible   |
| Dmg upgrades (1→6)      | Même chose                     |
| Coûts upgrades          | Tension économique correcte    |
| Drop keys               | Courbe actuelle fonctionne bien|
| Âmes par kill           | soul_harvester reste intéressant|
| Orbes Golgota           | Bon pattern de base à esquiver |
| Laser Golgota           | Bon moment fort du combat      |
| ~~Spawn rate Aldrich~~   | **MODIFIÉ** — voir section 11  |
| Commons items           | Flat bonuses sont sains        |

---

*Proposition basée sur l'analyse du 2026-04-19 — toutes les valeurs sont calculées, pas estimées*
