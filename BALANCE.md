# CODEX INFERNALIS — FICHE DE BALANCE (état actuel)

*Mise à jour 2026-04-20 — valeurs extraites du code source*

---

## 1. STATS DE BASE (départ de chaque run)

| Stat     | Valeur de base | Min absolu |
|----------|----------------|------------|
| HP max   | 5              | —          |
| Dégâts   | 1              | —          |
| Vitesse  | 275            | —          |
| Cadence  | 0.85s          | 0.25s      |

---

## 2. UPGRADES DE RUN (shop entre les rounds)

Coûts : **10 → 25 → 50 → 100 → 200 âmes** (385 total / stat)

| Stat    | Formule                        | Nv.0  | Nv.1  | Nv.2  | Nv.3  | Nv.4  | Nv.5 MAX |
|---------|--------------------------------|-------|-------|-------|-------|-------|----------|
| HP max  | 5 + niveau × 2                 | 5     | 7     | 9     | 11    | 13    | 15       |
| Dégâts  | 1 + niveau                     | 1     | 2     | 3     | 4     | 5     | 6        |
| Vitesse | 275 + niveau × 20              | 275   | 295   | 315   | 335   | 355   | 375      |
| Cadence | 0.85 − niveau × 0.09 (min 0.25s)| 0.85s | 0.76s | 0.67s | 0.58s | 0.49s | 0.40s  |

---

## 3. FORMULE DE CALCUL FINALE

```
max_hp  = int((base_hp  + flat_hp)  × (1 + pct_hp))
damage  = int((base_dmg + flat_dmg) × (1 + pct_dmg))
speed   =     (base_spd + flat_spd) × (1 + pct_spd)
fire_cd = max(0.25s, (base_cd + flat_cd) × (1 − pct_cd))
```

---

## 4. ITEMS — COMMUNS (flat, stackables)

Probabilité d'apparaître dans une caisse : **60%** | Coût : **1 clé**

| ID             | Nom               | flat_hp | flat_dmg | flat_spd | flat_cd |
|----------------|-------------------|---------|----------|----------|---------|
| ampoule_vie    | Ampoule de Vie    | +2      |          |          |         |
| coeur_pierre   | Cœur de Pierre    | +3      |          |          |         |
| bouclier_bois  | Bouclier de Bois  | +4      |          |          |         |
| dent_loup      | Dent de Loup      |         | +1       |          |         |
| epee_courte    | Épée Courte       |         | +1       |          |         |
| pierre_aceree  | Pierre Acérée     |         | +2       |          |         |
| plume_rapide   | Plume Rapide      |         |          | +15      |         |
| bottes_course  | Bottes de Course  |         |          | +12      |         |
| anneau_vitesse | Anneau de Vitesse |         |          | +20      |         |
| bague_tir      | Bague du Tireur   |         |          |          | −0.08s  |

---

## 5. ITEMS — RARES (% + effet actif)

Probabilité : **30%** | Coût : **2 clés**

| ID             | Nom               | Passif              | Effet actif                        |
|----------------|-------------------|---------------------|------------------------------------|
| vampire_amulet | Amulette Vampire  | +8% HP max          | Soigne 2% des dégâts infligés      |
| fire_boots     | Bottes de Feu     | +12% vitesse        | Laisse une traînée de feu 2s       |
| thorn_shield   | Bouclier Épineux  | +8% dégâts          | Renvoie 15% des dégâts reçus       |
| rage_ring      | Anneau de Rage    | +8% dégâts          | +dégâts pendant 2s après un kill   |
| phantom_step   | Pas Fantôme       | +12% vitesse        | 1.5s d'invincibilité après un coup |

---

## 6. ITEMS — ÉPIQUES (% élevé + effet actif fort)

Probabilité : **10%** | Coût : **3 clés**

| ID             | Nom                 | Passif              | Effet actif                              |
|----------------|---------------------|---------------------|------------------------------------------|
| auto_grenade   | La Sainte Grenade   | +15% dégâts         | Lance une grenade toutes les 8s          |
| storm_ring     | Anneau de Tempête   | +12% cadence (pct)  | Salve de 8×(count) tirs toutes les 15s  |
| soul_harvester | Faucheur d'Âmes     | +20% HP max         | Double les âmes par kill                 |

> `storm_ring` se stack : 2 anneaux = 16 tirs par salve.

---

## 7. DPS COMPARATIF (upgrades max + items)

| Situation                                    | Dmg | fire_cd | DPS        |
|----------------------------------------------|-----|---------|------------|
| Base (aucun upgrade, aucun item)             | 1   | 0.85s   | 1.18/s     |
| Upgrades max (tout niveau 5)                 | 6   | 0.40s   | 15.0/s     |
| + Forge Éternelle complète (weapon skills)   | 6   | 0.40s   | 15.0/s *   |
| + thorn + rage + La Sainte Grenade           | 9   | 0.40s   | 22.5/s     |
| + storm_ring (12%) + bague_tir               | 9   | 0.25s†  | **36.0/s** |

> *Les skills arme sont comportementaux (double tir, pénétration…) — pas de bonus DPS flat.  
> †plancher 0.25s atteint avec bague_tir + storm_ring + cadence nv.5.

---

## 8. FORGE ÉTERNELLE — ARBRE ARME (permanent)

Coût : **1 âme de boss** par nœud | Déblocage total : **6 victoires minimum**

```
              [DOUBLE TIR]       row 0 — racine
             /             \
    [PÉNÉTRATION]       [VÉLOCITÉ]      row 1
             \                 /
    [EXPLOSION]         [RICOCHET]      row 2
             \                 /
           [TEMPÊTE D'ACIER]            row 3 — final
```

| Nœud            | Effet                                         | Prérequis               |
|-----------------|-----------------------------------------------|-------------------------|
| Double Tir      | 2 projectiles côte à côte par tir             | —                       |
| Pénétration     | Traverse jusqu'à 3 ennemis                    | Double Tir              |
| Vélocité        | Projectiles +60% plus rapides                 | Double Tir              |
| Explosion       | Chaque impact crée une explosion 80px         | Pénétration             |
| Ricochet        | Rebondit vers l'ennemi le plus proche         | Vélocité                |
| Tempête d'Acier | Salve de 12 tirs omnidirectionnels / 10s      | Explosion + Ricochet    |

---

## 9. ENNEMIS

### Aldrich (goule de base)

| Stat      | Valeur                                    |
|-----------|-------------------------------------------|
| HP        | 3 (base, surchargeable par Arena1)        |
| Dégâts    | 1 (contact)                               |
| Vitesse   | 90                                        |
| Drop clé  | 17% (base, décroît par niveau via Arena1) |

### Brutus (démon à distance — niveau 2+)

| Stat       | Valeur                          |
|------------|---------------------------------|
| HP         | 15 + (niveau − 2) × 4           |
| Vitesse    | 55                              |
| Portée tir | 500px                           |
| Cadence    | 0.6s                            |
| Dégâts     | 1 par balle                     |

| Niveau | HP Brutus |
|--------|-----------|
| 2      | 15        |
| 3      | 19        |
| 4      | 23        |
| 5      | 27        |
| 6      | 31        |

### Golgota (boss final — niveau 7)

| Stat       | Phase 3 (>66% HP) | Phase 2 (33–66%) | Phase 1 (<33%)    |
|------------|-------------------|------------------|-------------------|
| HP total   | 700               | —                | —                 |
| Vitesse    | 35                | 48               | 60                |
| Lasers     | 1                 | 3 (±40°)         | 5 (±30° ±65°)     |
| Télégraphe | 1.2s              | 0.9s             | 0.6s              |
| CD laser   | 6.0s              | 4.5s             | 3.0s              |
| Orbes/vague| 5                 | 8                | 12                |
| CD orbes   | 2.5s              | 2.0s             | 1.5s              |
| Spawn ennemi| —               | 3 Aldrich / 12s  | 5 Aldrich / 7s    |

> En phase 1, seul le laser central suit le joueur. Les lasers latéraux sont fixes.

---

## 10. SPAWNS PAR NIVEAU

### Aldrich

| Niveau | Intervalle          | Count/vague | Approx/round (90s) |
|--------|---------------------|-------------|---------------------|
| 1      | 2.35s               | 1           | ~38                 |
| 2      | 2.13s               | 1           | ~42                 |
| 3      | 1.91s               | 2           | ~94                 |
| 4      | 1.69s               | 2           | ~107                |
| 5      | 1.47s               | 3           | ~184                |
| 6      | 1.25s               | 3           | ~216                |
| 7 (boss)| ∞ (aucun spawn)   | —           | —                   |

### Brutus (niveau 2+)

`max(9.0, 22.0 − (niveau−2) × 1.5)`

| Niveau | Intervalle |
|--------|------------|
| 2      | 22.0s      |
| 3      | 20.5s      |
| 4      | 19.0s      |
| 5      | 17.5s      |
| 6      | 16.0s      |

---

## 11. CLÉS — DROP RATE

`max(0.03, 0.15 − (niveau−1) × 0.024)` + base Aldrich.gd 17%

| Niveau | Drop rate Arena | Clés/round (approx) |
|--------|-----------------|----------------------|
| 1      | 17.0%           | ~4.5                 |
| 2      | 14.6%           | ~4.2                 |
| 3      | 12.2%           | ~7.6                 |
| 4      | 9.8%            | ~6.9                 |
| 5      | 7.4%            | ~8.9                 |
| 6      | 5.0%            | ~7.1                 |

### Coût des caisses

| Rareté | Coût  | Probabilité | Pool  |
|--------|-------|-------------|-------|
| Commun | 1 clé | 60%         | 10    |
| Rare   | 2 clés| 30%         | 5     |
| Épique | 3 clés| 10%         | 3     |

---

## 12. ÉCONOMIE ÂMES (estimations)

Base : 1 âme/kill (+1 par soul_harvester possédé)

| Niveau | ~Aldrich tués | ~Brutus tués | ~Âmes (sans harvester) |
|--------|---------------|--------------|------------------------|
| 1      | 25            | 0            | ~25                    |
| 2      | 28            | 2            | ~30                    |
| 3      | 63            | 3            | ~66                    |
| 4      | 71            | 4            | ~75                    |
| 5      | 122           | 5            | ~127                   |
| 6      | 144           | 5            | ~149                   |

> Total pour maxer tous les upgrades : **1540 âmes** — nécessite plusieurs runs.  
> Total pour l'arbre Forge Éternelle : **6 boss kills**.
