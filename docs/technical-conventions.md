# Convenções de espaço, colisão e apresentação

## Coordenadas e pivôs

- Toda a simulação usa pixels lógicos no viewport 640 × 360: X cresce para a direita, Y para baixo. Posições e direções são globais no espaço da arena; direções de disparo são normalizadas.
- A arena jogável é `Rect2(34, 70, 572, 258)`. Jogador e inimigos são limitados pelo centro com uma margem; a imagem do pátio não define colisões.
- `player_position` e `enemy["position"]` são a origem de combate e de ordenação por Y. Os visuais recebem essa posição arredondada, sem devolver o arredondamento à simulação.
- A origem local do ator é o centro de combate, não o canto da textura nem a extremidade dos pés. O corpo estende-se sobretudo para Y negativo; sombras têm deslocamento local positivo (jogador: 8 px; inimigos: 7 px). Preservar estas origens ao substituir atlas.
- Espelhar a arte em torno de `(0, 0)` com uma transformação local e restaurar a transformação depois de desenhar. Não espelhar a posição global, hitboxes ou direção de mira.
- O pivô da arma do Exilado é `(0, -2)`, ou `(7, -2)` quando `aim.y < -0.6`. A apresentação acrescenta bob/recuo; a origem física do tiro usa o pivô sem estes efeitos mais `aim * weapon.muzzle_offset` (16 px por defeito).
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
| Mundo, Z = 2 | Escurecimento de pausa/escolha/resultados | `overlay` |
| Canvas, layer = 3 | HUD, botões, menus e tooltips | `ArenaHud` |

Dentro do Exilado: sombra → capa → arma quando aponta para cima → corpo → arma nos restantes ângulos. Dentro do inimigo: aviso de spawn isolado; após ativação, sombra → aviso de ataque → corpo → vida.

Os projéteis e partículas atuais ficam atrás dos atores. Qualquer alteração desta prioridade deve ser verificada em combate denso; aumentar Z de um ator individual quebra a ordenação partilhada por Y. Elementos de UI pertencem ao CanvasLayer e não participam na ordenação do mundo.

## Verificação ao acrescentar arte ou entidades

Verificar as quatro direções, diagonais, limites, sobreposição de atores e mira para cima. Confirmar que o tiro nasce no mesmo lado da arma, que a sombra não muda de centro ao espelhar e que efeitos visuais não mudam os valores de combate. Os testes de combate cobrem colisão por segmento, alvo mais próximo, proteção, spawn pendente, separação e reset; o alinhamento da arte exige revisão no motor.

## Charger prototype

`default_charger.tres` supplies four HP, slow approach, a locked-direction 0.85 s warning, a 300 px/s charge for 0.45 s and 0.8 s stationary recovery. Bounds end a charge early. Active charge movement uses segment contact; its swept path expires on the next simulation step. Existing dash/damage protection still gates damage. Wave five introduces one charger per five spawns, overriding the ranged slot when both coincide.

The angular armored silhouette is drawn in code under the repository MIT license; it is prototype art. Parallel amber lines mark the contact corridor, a trail marks the rush, and a dim body plus overhead arc marks recovery. Reduced-flash settings suppress hit flashes. `tests/charger_smoke.gd` covers 30/60/120/144/240 Hz, locked aim, stationary warning/recovery, swept contact, walls, cleanup and wave composition. `tools/capture_charger.gd` captures all three attack stages.


## Guardian prototype

`default_guardian.tres` defines a slow eight-HP enemy with a larger body/contact radius, 20% knockback and 1.1 rad/s facing rotation. Its front 120-degree shield halves incoming player-shot damage, rounded up with a minimum of one. Shots outside the front arc deal double damage. The front is determined from the incoming shot direction against the simulation facing vector; art position does not affect armor. Because facing turns slowly, circling exposes the weak sides. The guardian never becomes immune to basic shots.

Wave seven introduces one per seven spawns, with guardian selection taking priority over charger and ranged slots. The broad rectangular armor, visible shield arc and rear crack are original code-drawn placeholder art under the repository MIT license. A dedicated sprite remains future art work. `tests/guardian_smoke.gd` covers armor, flanking, upgraded damage, knockback, turning at five step rates, spawn cadence and cleanup. `tools/capture_guardian.gd` captures front/side/rear shield orientations.
