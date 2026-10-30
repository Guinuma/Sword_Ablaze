# Sword Ablaze

Top-down pixel-art shooter em GDScript, ambientado num Céu em ruínas. Combate rápido, arenas e progressão roguelite formam o foco inicial; uma campanha narrativa fica para uma fase posterior.

## Abrir e executar

1. Instalar **Godot 4.5.1 Standard** (sem .NET), versão de referência deste init.
2. Clonar este repositório e importar `project.godot` no Godot.
3. Abrir o projeto e carregar **F6** para a cena atual ou **F5** para o projeto.

Pelo terminal: `godot --editor --path .` ou `godot --path .` (com o executável no PATH).

A primeira arena de combate usa placeholders geométricos: WASD/setas para mover, rato para apontar, botão esquerdo/Espaço para disparar e R para reiniciar em qualquer momento.

- Inimigos perseguem o jogador e surgem a cada 1,6 segundos, até 18 em simultâneo, longe da posição do jogador.
- Cada inimigo precisa de dois tiros; o impacto dá um flash e a morte conta uma eliminação.
- O jogador tem 5 HP. Contacto causa 1 de dano, com 0,85 segundos de proteção entre impactos.
- O HUD mostra vida, eliminações e tempo. Ao morrer, a simulação para e R inicia uma nova partida.
- Ainda não existem XP, ondas, menus, save ou progressão persistente. Os inimigos podem sobrepor-se neste protótipo.

## Base técnica

- Godot 4.x, GDScript e renderer Compatibility.
- Resolução lógica 640×360, janela inicial 1280×720 e escala inteira.
- Filtro nearest para texturas pixel art; movimento normalizado em passos de física.
- Arena limitada e projéteis removidos ao sair dos limites.
- O sandbox regista as ações de input no arranque em `scripts/main/main.gd`.
- Gráficos temporários desenhados por código; nenhum asset externo é necessário.

## Organização

```text
scenes/       Cenas, começando por main/main.tscn
scripts/      GDScript organizado por contexto
tests/        Verificações automáticas do combate
assets/       Arte, áudio e fontes
resources/    Resources (.tres) e dados de configuração
```

## Visão de progressão

**Arena Shooter + Roguelite primeiro. Campaign mais tarde.**

O XP será transversal aos modos: jogar nos diferentes modos contribuirá para a progressão global. O hub roguelite concentrará a progressão persistente e as skill trees. A progressão temporária de cada run deverá ser distinguida da progressão global. Regras de equilíbrio, recompensas e persistência serão definidas antes da implementação destes sistemas.

## Roadmap

- [x] Init: projeto importável, cena principal, organização e sandbox de controlos.
- [x] Primeiro combate: inimigo básico, colisão de tiros, dano, morte, HUD e reinício.
- [ ] Separar jogador, projéteis e inimigos em cenas próprias; o primeiro protótipo concentra a simulação em `scripts/main/main.gd`.
- [ ] Loop de arena: spawns, ondas, feedback de combate e primeira arma equilibrada.
- [ ] Loop roguelite: runs, escolhas temporárias, recompensas e retorno ao hub.
- [ ] XP transversal, save versionado e skill trees persistentes no hub roguelite.
- [ ] Conteúdo e polimento: armas, inimigos, arte, áudio e acessibilidade.
- [ ] Campaign: narrativa, missões e integração com os sistemas já validados.

A sequência é uma intenção de desenvolvimento, sem datas comprometidas. Este init não implementa os sistemas futuros.

## Validação rápida

```sh
godot --headless --editor --path . --quit
godot --headless --path . --quit-after 120
godot --headless --path . --script tests/combat_smoke.gd
```

O teste de combate verifica perseguição, spawn, colisão contínua dos tiros, dano, invulnerabilidade, eliminações, morte e limpeza no reinício.

No editor, executar F5 e confirmar movimento nas quatro direções, limites da arena, mira, disparo contínuo, legibilidade do HUD, impactos, morte e reinício com R. Os comandos headless verificam importação e arranque, mas não substituem esta verificação interativa.

## Contribuir e licença

Consultar [CONTRIBUTING.md](CONTRIBUTING.md). Código distribuído sob a [licença MIT](LICENSE). Assets futuros deverão incluir origem e licença próprias quando aplicável.
