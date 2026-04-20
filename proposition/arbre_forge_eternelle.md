# Forge Éternelle — Arbre Arme (Proposition)

## Philosophie
Chaque nœud transforme **comment l'arme fonctionne**, pas juste des chiffres.
Pour débloquer les 6 nœuds il faut battre le boss **minimum 6 fois** (coût 1 âme-boss chacun).
La structure reste le losange diamant à 4 colonnes / 4 rangées.

---

## Disposition de l'arbre

```
                  ┌─────────────────┐
                  │   DOUBLE TIR    │   row 0, col 1  (racine)
                  └────────┬────────┘
           ┌───────────────┴───────────────┐
  ┌────────┴────────┐             ┌────────┴────────┐
  │  PÉNÉTRATION    │             │    VÉLOCITÉ     │   row 1, col 0 & 2
  └────────┬────────┘             └────────┬────────┘
  ┌────────┴────────┐             ┌────────┴────────┐
  │    EXPLOSION    │             │    RICOCHET     │   row 2, col 0 & 2
  └────────┬────────┘             └────────┬────────┘
           └───────────────┬───────────────┘
                  ┌────────┴────────┐
                  │ TEMPÊTE D'ACIER │   row 3, col 1  (final)
                  └─────────────────┘
```

---

## Fiches des 6 nœuds

### 1. DOUBLE TIR  `double_tir`
- **Rangée / Colonne** : 0 / 1  |  **Coût** : 1 âme-boss  |  **Prérequis** : aucun
- **Effet** : chaque tir lance **2 projectiles côte à côte** (écart latéral fixe de 18 px).
- **Implémentation** : dans `_shoot()`, spawner un second fireball décalé de
  `dir.rotated(PI/2) * 18` par rapport au premier. Aucun changement de cadence.

---

### 2. PÉNÉTRATION  `penetration`
- **Rangée / Colonne** : 1 / 0  |  **Coût** : 1 âme-boss  |  **Prérequis** : `double_tir`
- **Effet** : les projectiles **traversent les ennemis** sans disparaître (max 3 touches par balle).
- **Implémentation** : ajouter `var _hits_left := 3` sur Fireball.
  Dans `_on_body_entered`, décrémenter au lieu de `queue_free` tant que `_hits_left > 0`.
  Si le joueur n'a pas la compétence, comportement normal.

---

### 3. VÉLOCITÉ  `velocite`
- **Rangée / Colonne** : 1 / 2  |  **Coût** : 1 âme-boss  |  **Prérequis** : `double_tir`
- **Effet** : vitesse des projectiles **+60%** (600 → 960 px/s).
- **Implémentation** : dans `Fireball.gd`, lire
  `var spd := 960.0 if PlayerData.has_skill("velocite") else 600.0`.
  Simple, pas de nouvelle variable à synchroniser.

---

### 4. EXPLOSION  `explosion`
- **Rangée / Colonne** : 2 / 0  |  **Coût** : 1 âme-boss  |  **Prérequis** : `penetration`
- **Effet** : à l'impact, crée une **explosion de rayon 80 px** qui inflige les dégâts du joueur à
  tous les ennemis touchés (une seule fois par projectile).
- **Implémentation** : spawner une scène `BulletExplosion` (Area2D ephémère, durée 0.15 s)
  positionnée au point d'impact. Dans son `_ready()`, itérer `get_overlapping_bodies()`
  et appeler `take_damage()` sur ceux du groupe `"enemies"`.
  Ajouter un petit sprite flash (cercle blanc → transparent) pour la lisibilité.

---

### 5. RICOCHET  `ricochet`
- **Rangée / Colonne** : 2 / 2  |  **Coût** : 1 âme-boss  |  **Prérequis** : `velocite`
- **Effet** : après avoir touché un ennemi, le projectile **rebondit vers l'ennemi le plus proche**
  (une seule fois). Si aucun ennemi à portée (< 350 px), le projectile disparaît normalement.
- **Implémentation** : flag `var _bounced := false` sur Fireball.
  À l'impact : si pas encore rebondi, chercher l'ennemi le plus proche dans le groupe
  `"enemies"` (excluant la cible actuelle), recalculer `_dir`, `_bounced = true`, continuer.

---

### 6. TEMPÊTE D'ACIER  `tempete_acier`
- **Rangée / Colonne** : 3 / 1  |  **Coût** : 1 âme-boss  |  **Prérequis** : `explosion` + `ricochet`
- **Effet** : toutes les **10 secondes**, déclenche une **salve de 12 projectiles** omnidirectionnels
  qui héritent de **toutes** les propriétés débloquées (pénétration, explosion, ricochet).
  Visuellement : flash violet + 12 flammes en étoile.
- **Implémentation** : timer indépendant dans `Player.gd` (comme `_storm_timer`).
  La salve appelle `_shoot_burst(12)` qui spawne 12 fireballs avec `angle = i * TAU / 12`.
  Chaque fireball voit les skills via `PlayerData.has_skill()` normalement.

---

## Récapitulatif coûts / chemin minimum

| Ordre recommandé       | Âmes-boss cumulées |
|------------------------|--------------------|
| Double Tir             | 1                  |
| Pénétration            | 2                  |
| Vélocité               | 3                  |
| Explosion              | 4                  |
| Ricochet               | 5                  |
| Tempête d'Acier        | 6                  |

> Débloquer l'arbre complet = **6 victoires sur le boss minimum**.
> Le joueur peut choisir l'ordre des branches, mais `Tempête d'Acier` force à tout faire.

---

## Impact balance estimé

| Situation                          | DPS approximatif |
|------------------------------------|------------------|
| Aucun skill arme                   | ~12/s baseline   |
| + Double Tir                       | ×2 → ~24/s       |
| + Pénétration (multi-hit)          | ×1.5 situationnel|
| + Vélocité (meilleur hit-rate)     | +10–15% effectif |
| + Explosion (splash)               | fort en couloir  |
| + Ricochet (chain)                 | fort pack dense  |
| + Tempête d'Acier (burst 12 tirs)  | pic DPS ×3 / 10s |

> Double Tir est volontairement fort car c'est le premier skill — récompenser
> la première victoire boss avec un changement visible immédiat.
