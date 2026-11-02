# Sword Ablaze

Top-down pixel-art shooter em GDScript, ambientado num Céu em ruínas. Combate rápido, arenas e progressão roguelite são o foco inicial. O protagonista escolhido é **The Exile**: capuz e máscara claros, capa turquesa, equipamento leve e arma com lâmina.

**Arena Shooter + Roguelite primeiro. Campaign mais tarde.** O XP será transversal aos modos; o hub roguelite concentrará a progressão persistente e as skill trees. Melhorias temporárias de uma run serão separadas da progressão global.

## Estado atual

Protótipo de combate jogável, ainda sem menus, áudio, XP, gravação ou hub. O jogador já usa um primeiro visual do Exilado; arena e inimigos mantêm placeholders. A arte gerada serve como referência e base provisória, não como atlas de animação final.

- Movimento, mira, disparo, colisão contínua dos tiros, dano, morte e reinício.
- Ondas crescentes, pausa entre rondas, recuperação de vida e dash.
- Recuo dos inimigos, separação, partículas, flash de disparo e pausa manual.
- Corpo do Exilado espelhado, capa reativa e arma com mira independente.
- Testes automáticos do combate e capturas reais do motor para verificar o visual.

## Abrir e executar

1. Instalar **Godot 4.5.1 Standard** (sem .NET), versão de referência.
2. Clonar o repositório e importar `project.godot`.
3. Carregar **F5** para executar o projeto.

Pelo terminal: `godot --editor --path .` ou `godot --path .`, com o executável no PATH.

| Controlo | Ação |
| --- | --- |
| WASD / setas | Mover |
| Rato | Apontar |
| Botão esquerdo / Espaço | Disparar |
| Shift | Dash na direção do movimento, ou da mira quando parado |
| Escape | Pausar / retomar |
| R | Reiniciar, incluindo durante pausa ou após morrer |

### Regras do protótipo

- Jogador: 5 HP; contacto causa 1 de dano, com 0,85 s de proteção entre impactos.
- Inimigo básico: 2 HP; persegue o jogador e sofre recuo ao receber tiros.
- Ondas: 5 inimigos inicialmente, mais 2 por ronda até 40 por onda; máximo de 18 em simultâneo.
- Spawns: longe do jogador; intervalo começa em 1,6 s e desce até 0,4 s. A velocidade dos inimigos também aumenta, até um limite.
- Limpar uma onda: recupera 1 HP, até ao máximo, e inicia uma pausa de 3 s.
- Dash: duração de 0,14 s e recarga de 1,2 s; proteção de contacto enquanto o dash está ativo.
- Morte e pausa congelam a simulação. R limpa a partida e regressa à primeira onda.

Perder foco pausa o jogo; Escape retoma. Após pausa ou reinício, largar o disparo antes de voltar a disparar.

Os valores são provisórios e precisam de playtesting.

## Checklist de desenvolvimento

`[x]` significa implementado no protótipo; não significa equilibrado ou pronto para lançamento. `[ ]` significa trabalho pendente. Itens marcados **Decidir** são propostas que precisam de definição antes de implementação. A ordem das fases indica prioridade, sem datas comprometidas. Esta lista é um plano vivo, não uma promessa de incluir todas as propostas no lançamento.

### 1. Fundação técnica

- [x] Criar projeto Godot 4.5.1, GDScript e renderer Compatibility.
- [x] Configurar viewport 640 × 360, janela 1280 × 720, escala inteira e filtro nearest.
- [x] Criar cena principal funcional e pastas para cenas, scripts, assets e recursos.
- [x] Criar repositório, licença MIT e guia de contribuição.
- [x] Separar simulação de projéteis num componente com eventos de impacto e eliminação.
- [x] Separar spawn, movimento, separação e contacto dos inimigos num componente próprio.
- [ ] Separar simulação do jogador num script próprio.
- [x] Separar HUD da simulação num componente de apresentação.
- [x] Separar gestão de ondas num componente com eventos de spawn e fim/início de ronda.
- [x] Separar estado, vida, eliminações e tempo da run da cena principal.
- [x] Definir estados explícitos de combate, intervalo, pausa e morte, preservando o estado ao retomar.
- [ ] Integrar estado de escolha de melhoria quando existir esse fluxo.
- [ ] Mover atributos de armas, inimigos, ondas e melhorias para Resources reutilizáveis.
- [x] Centralizar eventos de dano recebido, eliminação e fim/início de ronda.
- [ ] Ligar os eventos aos futuros sistemas de áudio e recompensas.
- [x] Configurar Input Map no projeto sem apagar bindings ao abrir a arena.
- [ ] Guardar e carregar preferências e remapeamentos do jogador.
- [ ] Definir camadas de colisão, grupos, ordem de desenho e convenções de pivôs.
- [ ] Definir limites de entidades e medir desempenho antes de introduzir pooling.

### 2. Jogador e combate base

- [x] Movimento normalizado, limites da arena e mira pelo rato.
- [x] Disparo contínuo com intervalo e limpeza de projéteis fora da arena.
- [x] Colisão por segmento para evitar tiros atravessarem inimigos entre frames.
- [x] Acertar apenas no inimigo mais próximo e consumir o projétil.
- [x] Vida, dano de contacto, proteção temporária, morte e reinício.
- [x] Dash direcional com recarga e limites da arena.
- [x] Pausa e retoma com Escape.
- [ ] Afinar velocidade, alcance do dash, hitboxes e intervalo dos disparos em playtests.
- [ ] Verificar proteção de dash nos frames de início/fim e sob diferentes taxas de atualização.
- [ ] Definir origem dos tiros e alinhar muzzle flash, arma, mãos e hitbox.
- [x] Exigir largar o disparo antes de disparar após pausa ou reinício.
- [ ] Aplicar a proteção de disparo aos futuros menus e escolhas de melhorias.
- [x] Pausar ao perder foco e exigir retoma explícita com Escape.
- [ ] **Decidir:** se a lâmina terá ataque corpo a corpo ou será apenas identidade visual.
- [ ] **Decidir:** necessidade de munições, recarga, dano crítico e efeitos de estado.

### 3. Inimigos e encontros

- [x] Inimigo perseguidor com 2 HP e flash ao receber dano.
- [x] Separação entre inimigos, incluindo quando ocupam a mesma posição.
- [x] Recuo ao receber tiros e contagem de eliminações.
- [x] Spawns afastados do jogador e limite de inimigos simultâneos.
- [ ] Criar sinais visuais de spawn e impedir aparecimentos injustos.
- [ ] Melhorar separação junto às paredes e em grupos densos.
- [ ] Adicionar navegação quando existirem obstáculos reais.
- [ ] Criar primeiro inimigo de ataque à distância, com projéteis e aviso legível.
- [ ] Criar inimigo de investida com preparação, ataque e recuperação claros.
- [ ] Criar inimigo resistente que altere o posicionamento do jogador.
- [ ] Definir estatísticas, recompensas e função de cada tipo de inimigo.
- [ ] Combinar tipos em encontros progressivos, evitando picos injustos.
- [ ] Criar primeiro elite com comportamento reconhecível.
- [ ] Criar primeiro boss com ataques anunciados, fases e recompensa.
- [ ] Testar dano simultâneo, eliminações em cadeia e limpeza de inimigos no fim da run.

### 4. Ondas e modo Arena

- [x] Ondas com orçamento crescente de inimigos.
- [x] Aumentar frequência de spawn e velocidade com limites definidos.
- [x] Detetar fim da onda, limpar tiros e iniciar intervalo.
- [x] Recuperar 1 HP uma única vez entre rondas.
- [x] Mostrar ronda, inimigos restantes, HP, eliminações, tempo e recarga do dash.
- [ ] Substituir escalada uniforme por configurações de encontros e composição de ondas.
- [ ] **Decidir:** condição de vitória, duração alvo e eventual variante endless.
- [ ] Criar resumo da partida com ronda, tempo, eliminações e recompensas.
- [ ] Criar fluxo completo: iniciar arena, jogar, terminar, repetir ou regressar ao hub.
- [ ] Guardar recordes locais e apresentar resultados de forma clara.
- [ ] Fazer playtests da primeira ronda, meio da partida e rondas avançadas.

### 5. Arte do Exilado

- [x] Explorar direção visual de Céu em ruínas e selecionar The Exile.
- [x] Criar prancha de personagem, vistas e estudos de poses.
- [x] Integrar corpo PNG transparente, sombra, capa reativa e arma independente.
- [x] Adicionar movimento procedural, recuo visual de disparo e indicação de dano/dash.
- [x] Corrigir espelhamento para manter corpo, capa, arma e sombra no mesmo centro.
- [x] Guardar referências, prompt de geração e capturas do jogo em `docs/art/`.
- [ ] Fixar grelha, paleta e tamanho final do sprite à escala real do jogo.
- [ ] Simplificar o corpo atual num sprite de baixa resolução com pixels consistentes.
- [ ] Produzir vistas frente, costas e laterais com silhuetas coerentes.
- [ ] Criar animações idle e movimento nas direções escolhidas.
- [ ] Criar animações de dash, dano e morte.
- [ ] Finalizar capa e arma com estilo consistente com o corpo.
- [ ] Ajustar mãos, pivôs, pés, sombra e ponto de saída dos tiros por direção.
- [ ] Verificar leitura contra pisos claros/escuros e com muitos efeitos em simultâneo.
- [ ] Verificar todos os ângulos da mira, movimento diagonal, dash e overlays.

### 6. Arena, inimigos e linguagem visual

- [x] Criar primeira prancha com mármore partido, ouro antigo e corrupção vermelha/violeta.
- [ ] Definir especificação visual: tamanho dos tiles, perspetiva, luz e orçamento de cores.
- [ ] Criar tiles de chão com variação moderada e boa leitura dos projéteis.
- [ ] Criar paredes, limites do abismo, cantos e transições sem falhas de encaixe.
- [ ] Criar pilares e ruínas com colisões alinhadas à arte.
- [ ] Construir uma arena finalizada com espaço de combate legível.
- [ ] Substituir o quadrado inimigo pelo primeiro sprite animado.
- [ ] Desenvolver wisp corrompido, sentinela fraturado e aberração como conceitos a validar.
- [ ] Criar arte de elites e boss após validar os respetivos comportamentos.
- [ ] Criar projéteis distintos para jogador e inimigos, com silhuetas reconhecíveis.
- [ ] Criar ícones coerentes para armas, melhorias, recursos e habilidades.
- [ ] Rever escala e contraste de todos os assets no jogo, não apenas nas pranchas.
- [ ] Registar autoria, ferramenta de geração, prompts e licenças dos assets utilizados.

### 7. Feedback e áudio

- [x] Partículas de impacto, morte e dano recebido, com limite e expiração.
- [x] Flash de disparo e flash de dano nos inimigos.
- [ ] Afinar intensidade, duração e ordem das camadas dos efeitos.
- [ ] Criar efeitos para spawn, dash, melhoria, recuperação de vida e fim de onda.
- [ ] Criar sons de tiro, impacto, eliminação, dano, dash e interação de menus.
- [ ] Criar música de combate e ambiente do hub com transições.
- [ ] Configurar buses Master, Music, SFX e UI, com volumes independentes.
- [ ] Limitar sons simultâneos e evitar volume excessivo em combate denso.
- [ ] **Decidir:** incluir hit-stop e screen shake; se usados, oferecer redução/desativação.

### 8. Primeira run roguelite

- [ ] **Decidir:** duração alvo, estrutura de salas/ondas e frequência das escolhas.
- [ ] Definir início, vitória, derrota e retorno ao hub da run.
- [ ] Definir atributos temporários e regras de acumulação de modificadores.
- [ ] Criar escolha de melhorias entre encontros, com descrição do efeito real.
- [ ] Criar primeiro conjunto pequeno de melhorias com estilos de jogo diferentes.
- [ ] Criar segunda arma e validar que oferece uma alternativa real à primeira.
- [ ] Definir raridade, pré-requisitos e exclusões de melhorias, se necessários.
- [ ] Garantir aplicação e remoção correta de todos os modificadores ao terminar/reiniciar.
- [ ] **Decidir:** recuperação, moeda temporária, lojas, rerolls e outros sistemas de economia.
- [ ] Definir recompensas de vitória e derrota antes de ligar progressão persistente.
- [ ] Testar combinações fortes, escolhas sem efeito e situações sem opções válidas.

### 9. XP transversal, hub e skill trees

- [ ] Definir XP global, níveis, fontes de recompensa e limites por modo.
- [ ] Distinguir XP global de experiência ou moeda temporária de uma run.
- [ ] Garantir que Arena e Roguelite usam as mesmas regras de atribuição global.
- [ ] Prevenir entrega duplicada de recompensas ao repetir ecrãs ou carregar saves.
- [ ] Criar hub com acesso aos modos, progressão e configurações.
- [ ] Desenhar skill trees com custos, requisitos e efeitos compreensíveis.
- [ ] Implementar compra e aplicação dos nós desbloqueados.
- [ ] **Decidir:** respec, limites de poder e desbloqueios de conteúdo versus bónus diretos.
- [ ] Apresentar estado bloqueado, disponível e adquirido de cada nó.
- [ ] Validar comportamento com pontos insuficientes, pré-requisitos e compras repetidas.
- [ ] Equilibrar progressão inicial e evitar tornar as primeiras partidas demasiado fracas.

### 10. Save e dados persistentes

- [ ] Definir esquema versionado para XP, desbloqueios, skills, recordes e preferências.
- [ ] Gravar em `user://`, com escrita segura e cópia de recuperação.
- [ ] Criar e carregar perfil inicial quando não existir save.
- [ ] Validar dados e tratar saves incompletos ou corrompidos.
- [ ] Implementar migrações entre versões do esquema.
- [ ] Guardar nos momentos de recompensa, compra e alteração de preferências.
- [ ] Oferecer reposição de progresso com confirmação explícita.
- [ ] Testar encerramento durante gravação e recuperação sem perder todo o perfil.
- [ ] **Decidir:** suporte a vários perfis e continuação de runs interrompidas.

### 11. Menus, HUD e acessibilidade

- [x] HUD funcional e mensagens de morte/pausa.
- [ ] Criar menu principal, seleção de modo e ecrã de resultados.
- [ ] Criar menu de pausa com retomar, configurações, reiniciar e sair.
- [ ] Integrar menus de melhorias, skill tree e recompensas.
- [ ] Criar hierarquia visual e tipografia coerentes com a direção artística.
- [ ] Oferecer remapeamento de teclas e guardar preferências.
- [ ] **Decidir:** suporte de comando; se incluído, implementar mira, foco e navegação completos.
- [ ] Garantir navegação por teclado e foco visível nos menus.
- [ ] Ajustar escala de texto/UI e testar resoluções, fullscreen e janelas pequenas.
- [ ] Distinguir perigos por forma e movimento, além da cor.
- [ ] Oferecer redução de flashes e movimento visual intenso.
- [ ] Criar tutorial curto para mover, apontar, disparar, dash e escolher melhorias.
- [ ] **Decidir:** idiomas suportados e preparar textos para localização.

### 12. Validação, equilíbrio e desempenho

- [x] Testar perseguição, spawn, limite de inimigos e colisão com o alvo mais próximo.
- [x] Testar dano, proteção de contacto, morte e congelamento da simulação.
- [x] Testar transições de ondas, recuperação de vida, dash e reset.
- [x] Testar pausa/retoma, recuo, separação e limite/expiração de partículas.
- [x] Executar importação e arranque gráfico no Godot 4.5.1.
- [ ] Acrescentar testes de regressão relevantes à medida que os sistemas forem separados.
- [ ] Criar testes de melhorias, recompensas únicas, skill trees, saves e migrações.
- [ ] Testar a run completa: hub → combate → resultado → recompensa → hub.
- [ ] Verificar alinhamento visual e hitboxes nas quatro direções e junto aos limites.
- [ ] Medir frame time, memória e entidades nas piores situações de combate.
- [ ] Definir hardware mínimo e objetivo de desempenho com base em medições.
- [ ] Testar sessões longas, muitas rondas, reinícios e alternância de foco.
- [ ] Recolher feedback externo sobre clareza, dificuldade e variedade das escolhas.
- [ ] Registar problemas conhecidos e corrigir bloqueios antes de expandir conteúdo.

### 13. Vertical slice e distribuição

- [ ] Fechar uma experiência pequena: Exilado finalizado, uma arena, inimigos variados e boss.
- [ ] Incluir uma run com escolhas, resultado, recompensa persistente e retorno ao hub.
- [ ] Substituir placeholders que prejudiquem a avaliação da experiência.
- [ ] **Decidir:** plataformas alvo e canal de distribuição.
- [ ] Criar presets de exportação e ícone do jogo para as plataformas escolhidas.
- [ ] Automatizar importação, testes e build de validação no CI.
- [ ] Testar um export numa máquina limpa, sem depender do editor ou caminhos locais.
- [ ] Preparar créditos, licenças de assets, changelog e instruções de instalação.
- [ ] Rever gestão de versões, backups e conteúdo incluído no pacote.
- [ ] Publicar uma demo apenas após validar o fluxo completo e os principais bloqueios.

### 14. Campaign — depois do núcleo Arena/Roguelite

- [ ] Definir premissa, papel do Exilado e regras do Céu em ruínas.
- [ ] Definir estrutura de missões, objetivos e ligação ao hub.
- [ ] Escrever primeira missão e personagens necessários para uma prova de conceito.
- [ ] Criar diálogos, eventos e checkpoints apenas conforme a missão exigir.
- [ ] Integrar recompensas com o XP global e evitar duplicação ao repetir missões.
- [ ] Guardar progresso narrativo no save versionado.
- [ ] Validar uma missão completa antes de planear a produção da campanha inteira.

### Próxima sequência recomendada

1. Corrigir e simplificar a arte do Exilado à escala real, com animações direcionais.
2. Separar jogador, inimigos, projéteis, HUD e ondas para facilitar as próximas mudanças.
3. Finalizar uma arena e um inimigo visualmente coerentes.
4. Adicionar inimigo à distância e equilibrar encontros com os dois tipos.
5. Criar uma primeira run com escolhas temporárias e resultado.
6. Implementar save, XP global e um hub mínimo com uma pequena skill tree.
7. Fechar e testar a vertical slice antes de expandir conteúdo ou Campaign.

## Organização

```text
scenes/       Cenas; atualmente main/main.tscn
scripts/      Simulação principal e visual do jogador
assets/       Arte, áudio e fontes
resources/    Dados e Resources reutilizáveis
tests/       Verificações automáticas do combate
docs/art/    Referências, prompts e capturas reais do jogo
```

Referência visual e limitações atuais: [direção de arte](docs/art/README.md).

## Validação rápida

```sh
godot --headless --editor --path . --quit
godot --headless --path . --quit-after 120
godot --headless --path . --script tests/combat_smoke.gd
```

Os testes verificam a lógica do protótipo. Não substituem playtesting nem revisão visual. No editor, verificar movimento, mira em todos os ângulos, corpo/capa/arma alinhados, dash, colisões, HUD, transição de ondas, pausa, morte e reinício.

## Contribuir e licença

Consultar [CONTRIBUTING.md](CONTRIBUTING.md). Código distribuído sob a [licença MIT](LICENSE). Registar origem e licença dos assets adicionados; não presumir que referências visuais têm automaticamente a mesma licença do código.
