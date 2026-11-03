# Convenções de espaço, colisão e apresentação

## Coordenadas e pivôs

- Toda a simulação usa pixels lógicos no viewport 640 × 360: X cresce para a direita, Y para baixo. Posições e direções são globais no espaço da arena; direções de disparo são normalizadas.
- A arena jogável é `Rect2(34, 70, 572, 258)`. Jogador e inimigos são limitados pelo centro com uma margem; a imagem do pátio não define colisões.
- `player_position` e `enemy["position"]` são a origem de combate e de ordenação por Y. Os visuais recebem essa posição arredondada, sem devolver o arredondamento à simulação.
- A origem local do ator é o centro de combate, não o canto da textura nem a extremidade dos pés. O corpo estende-se sobretudo para Y negativo; sombras têm deslocamento local positivo (jogador: 8 px; inimigos: 7 px). Preservar estas origens ao substituir atlas.
- Espelhar a arte em torno de `(0, 0)` com uma transformação local e restaurar a transformação depois de desenhar. Não espelhar a posição global, hitboxes ou direção de mira.
- O pivô partilhado da arma vem de `PlayerState.weapon_grip`: Y = -6 px; X interpola suavemente de 0 a 7 px entre mira lateral e vertical, sem saltos de limiar. A apresentação acrescenta bob/recuo; a origem física do tiro usa o pivô sem estes efeitos mais `aim * weapon.muzzle_offset` (16 px por defeito).
- Animações, capa, flutuação e queda alteram apenas a apresentação. Não deslocam hitboxes nem a origem física do ator.

## Colisões atuais

Os sistemas guardam entidades em arrays e resolvem colisões matematicamente. Não existem `PhysicsBody2D`, `Area2D` nem máscaras físicas ativas. Um grupo de nós ou uma textura nunca autoriza dano.

| Interação | Regra atual | Fonte |
| --- | --- | --- |
| Tiro do jogador → inimigo | Segmento contra círculo; só o alvo mais próximo; consome um tiro | `ProjectileSystem`, `EnemySettings.hit_radius` (10 px por defeito) |
| Tiro hostil → jogador | Segmento contra círculo de 11 px; consome o tiro mesmo durante proteção | `HostileProjectiles` |
| Inimigo → jogador | Distância estritamente menor que `contact_radius` (15 px por defeito) | `EnemySystem.touches` |
| Inimigo → inimigo | Separação com passes limitados, redistribuindo movimento bloqueado por limites | `EnemySystem`, `separation_distance` |
| Ator → limite | Clamp com margem de 8 px por defeito | `PlayerState`, `EnemySettings.body_margin` |
| Spawn pendente | Não move, não recebe tiros e não causa contacto; só ativa fora da distância segura | `EnemySystem`, `ProjectileSystem` |

Contacto e tiros hostis passam pelo mesmo controlo de dano na arena: só em combate, fora da proteção de dano e do dash. O último passo com movimento de dash continua protegido. Pausa e morte impedem avanço da simulação. Não há fogo amigo nem colisão entre projéteis.

### Reserva para futuros obstáculos físicos

Quando se introduzirem corpos físicos, usar estas camadas 2D. Os números de camada são índices de 1 a 5; a máscara é o bit correspondente. Esta tabela é uma reserva de nomes, não uma configuração já ativa no projeto.

| Camada | Nome | Bit | Consulta prevista |
| --- | --- | --- | --- |
| 1 | `world` | 1 | Obstáculos sólidos consultados por atores e tiros |
| 2 | `player` | 2 | Alvo de contacto inimigo e tiros hostis |
| 3 | `enemies` | 4 | Alvos de tiros do jogador |
| 4 | `player_projectiles` | 8 | Consulta `world` e `enemies` (máscara 5) |
| 5 | `hostile_projectiles` | 16 | Consulta `world` e `player` (máscara 3) |

Manter a separação de inimigos e a aplicação de dano num único sistema. Ao migrar uma interação para física, desativar a resolução matemática equivalente para evitar impactos duplicados. Validar obstáculos e navegação antes de ativar estas máscaras.

## Grupos

Reservar `player_visuals`, `enemy_visuals` e `arena_ui` para consultas de apresentação se forem necessárias. Atualmente os visuais são geridos por referências explícitas (`player_visual`, `enemy_views`, `hud_view`); nenhum grupo é necessário ou registado. Não usar grupos para contagem de inimigos, recompensas ou aplicação de dano: os arrays e o estado da run são a fonte de verdade. Nós futuros de obstáculos podem usar `arena_obstacles`, mantendo a colisão definida pela camada `world`.

## Ordem de desenho

| Ordem | Conteúdo | Implementação atual |
| --- | --- | --- |
| Mundo, Z = 0 | Pátio, faixa superior, rasto de dash, flash, partículas, tiros do jogador, tiros hostis, nessa sequência | `_draw()` da arena |
| Mundo, Z = 1 | Atores, ordenados pelo Y da origem arredondada | `world.y_sort_enabled = true`; todos os visuais de ator com Z local 0 |
| Mundo, Z = 2 | Cues de spawn/dash/melhoria/cura/fim de onda, depois escurecimento de pausa/escolha/resultados | `overlay` |
| Canvas, layer = 3 | HUD, botões, menus e tooltips | `ArenaHud` |

Dentro do Exilado: sombra → capa → arma quando aponta para cima → corpo → arma nos restantes ângulos. Dentro do inimigo: aviso de spawn isolado; após ativação, sombra → aviso de ataque → corpo → vida.

Os projéteis e partículas atuais ficam atrás dos atores. Qualquer alteração desta prioridade deve ser verificada em combate denso; aumentar Z de um ator individual quebra a ordenação partilhada por Y. Elementos de UI pertencem ao CanvasLayer e não participam na ordenação do mundo.

## Verificação ao acrescentar arte ou entidades

Verificar as quatro direções, diagonais, limites, sobreposição de atores e mira para cima. Confirmar que o tiro nasce no mesmo lado da arma, que a sombra não muda de centro ao espelhar e que efeitos visuais não mudam os valores de combate. Os testes de combate cobrem colisão por segmento, alvo mais próximo, proteção, spawn pendente, separação e reset; o alinhamento da arte exige revisão no motor.

## Charger prototype

`default_charger.tres` supplies four HP, slow approach, a locked-direction 0.85 s warning, a 300 px/s charge for 0.45 s and 0.8 s stationary recovery. Bounds end a charge early. Active charge movement uses segment contact; its swept path expires on the next simulation step. Existing dash/damage protection still gates damage. The wave-five encounter introduces one charger per five spawns; later ratios follow the configured encounter recipe.

The angular armored silhouette is drawn in code under the repository MIT license; it is prototype art. Parallel amber lines mark the contact corridor, a trail marks the rush, and a dim body plus overhead arc marks recovery. Reduced-flash settings suppress hit flashes. `tests/charger_smoke.gd` covers 30/60/120/144/240 Hz, locked aim, stationary warning/recovery, swept contact, walls, cleanup and wave composition. `tools/capture_charger.gd` captures all three attack stages.


## Guardian prototype

`default_guardian.tres` defines a slow eight-HP enemy with a larger body/contact radius, 20% knockback and 1.1 rad/s facing rotation. Its front 120-degree shield halves incoming player-shot damage, rounded up with a minimum of one. Shots outside the front arc deal double damage. The front is determined from the incoming shot direction against the simulation facing vector; art position does not affect armor. Because facing turns slowly, circling exposes the weak sides. The guardian never becomes immune to basic shots.

The wave-seven encounter introduces one per seven spawns; later ratios follow the configured encounter recipe. The broad rectangular armor, visible shield arc and rear crack are original code-drawn placeholder art under the repository MIT license. A dedicated sprite remains future art work. `tests/guardian_smoke.gd` covers armor, flanking, upgraded damage, knockback, turning at five step rates, spawn cadence and cleanup. `tools/capture_guardian.gd` captures front/side/rear shield orientations.


## Short combat feedback cues

`CombatFeedback` holds at most 32 cues for up to 0.55 simulation seconds (melee 0.16 s; critical 0.3 s), replacing the oldest at capacity. Spawn activation produces a ring, successful dash produces chevrons, a selected upgrade produces six short rays, actual healing produces a plus sign, and wave clear produces paired arcs. These are original vector primitives under the repository MIT license, independent of hitboxes and combat results.

Healing emits only for a positive amount actually restored, including drop collection and intermission recovery. Full-health pickup attempts do not produce a cue. Spawn activation emits only after its warning and proximity safety checks. Cues draw above actors and below modal dimming/HUD. Their timers freeze during pause, death and upgrade selection; restart clears them. Reduced motion keeps positions/radii fixed while fading, and reduced flashes lowers their opacity. They never flash the screen or shake the camera.

`tests/feedback_smoke.gd` verifies event-driven creation, failed actions, full-health healing, paused lifetime, expiry, capacity and reset. `tools/capture_feedback.gd` captures normal and reduced settings. Existing particle bursts remain separately bounded at 160.


## Crowned sentinel elite

`default_elite.tres` reuses sentinel movement/cast presentation with an original code-drawn crown and gold ground halo. Its attack locks the first direction during a 1.05 s stationary warning and announces eight equally spaced spokes. At release, eight projectile events use those exact directions, at 110 px/s and 20 damage, followed by a 3 s cooldown. Shared hostile-projectile caps, swept player collision and dash protection apply normally. The Siege recipe uses a one-off `opener` to spawn exactly one elite inside the ordinary wave budget. Killing it grants the same one kill and healing-drop roll as other enemies; global elite rewards remain unimplemented.

`tests/elite_smoke.gd` verifies fixed warnings, eight-shot directions, damage/speed, cooldown and one-off encounter placement at five step rates. `tools/capture_elite.gd` captures the warning. Dedicated final elite art and human difficulty testing remain pending.


## Section 2 melee and critical hits

Right-click/E triggers a forward melee swing through `PlayerState.melee` and `MeleeSystem`. `default_melee.tres` defines 2 damage, 32 px reach plus target radius, a 120-degree cone, 0.45 s cooldown, 0.16 s animation and 170 knockback. Pending spawns are ignored. Every target is hit at most once per accepted swing. Melee shares impact/defeat events, armor rules, kill/drop/reward counters and critical feedback with projectiles. No invulnerability is added by swinging. Gunfire is suppressed during the swing animation; dash remains independent. Pause/reset/choice flows require releasing melee before attacking again.

Keen Edge is a temporary blessing with three ranks, each adding ten percentage points of critical chance to bullets and melee. Base chance is zero; critical multiplier is two. Each bullet rolls once at creation, while a melee swing rolls once per eligible target. `HitRules` applies the critical multiplier before guardian frontal reduction/flank vulnerability. A short X cue and audio accent identify a landed critical. No ammo/reload/status-effect system is added.

Hand and sleeve primitives connect shoulders to both weapon grips, with the same smoothed base pivot used by the physical muzzle. Upward weapon occlusion remains behind the body. Recoil/bob/melee rotation affect presentation only. `tools/capture_aim.gd` renders eight directions at enlarged engine scale; unit checks sample grip continuity over 360 angles. Dedicated final pixel-art poses remain Section 5 work.
