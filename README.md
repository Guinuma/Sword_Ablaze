# Sword Ablaze

Top-down pixel-art shooter em GDScript, ambientado num CÃ©u em ruÃ­nas. Combate rÃ¡pido, arenas e progressÃ£o roguelite formam o foco inicial; uma campanha narrativa fica para uma fase posterior.

## Abrir e executar

1. Instalar **Godot 4.5.1 Standard** (sem .NET), versÃ£o de referÃªncia deste init.
2. Clonar este repositÃ³rio e importar `project.godot` no Godot.
3. Abrir o projeto e carregar **F6** para a cena atual ou **F5** para o projeto.

Pelo terminal: `godot --editor --path .` ou `godot --path .` (com o executÃ¡vel no PATH).

A primeira arena de combate usa placeholders geomÃ©tricos: WASD/setas para mover, rato para apontar, botÃ£o esquerdo/EspaÃ§o para disparar Shift para dash e R para reiniciar em qualquer momento.

- Inimigos perseguem o jogador e surgem a cada 1,6 segundos, atÃ© 18 em simultÃ¢neo, longe da posiÃ§Ã£o do jogador.
- Cada inimigo precisa de dois tiros; o impacto dÃ¡ um flash e a morte conta uma eliminaÃ§Ã£o.
- O jogador tem 5 HP. Contacto causa 1 de dano, com 0,85 segundos de proteÃ§Ã£o entre impactos.
- O HUD mostra vida, eliminaÃ§Ãµes e tempo. Ao morrer, a simulaÃ§Ã£o para e R inicia uma nova partida.
- Ainda nÃ£o existem XP, ondas, menus, save ou progressÃ£o persistente. Os inimigos podem sobrepor-se neste protÃ³tipo.

## Base tÃ©cnica

- Godot 4.x, GDScript e renderer Compatibility.
- ResoluÃ§Ã£o lÃ³gica 640Ã—360, janela inicial 1280Ã—720 e escala inteira.
- Filtro nearest para texturas pixel art; movimento normalizado em passos de fÃ­sica.
- Arena limitada e projÃ©teis removidos ao sair dos limites.
- O sandbox regista as aÃ§Ãµes de input no arranque em `scripts/main/main.gd`.
- GrÃ¡ficos temporÃ¡rios desenhados por cÃ³digo; nenhum asset externo Ã© necessÃ¡rio.

## OrganizaÃ§Ã£o

```text
scenes/       Cenas, comeÃ§ando por main/main.tscn
scripts/      GDScript organizado por contexto
tests/        VerificaÃ§Ãµes automÃ¡ticas do combate
assets/       Arte, Ã¡udio e fontes
resources/    Resources (.tres) e dados de configuraÃ§Ã£o
```

## VisÃ£o de progressÃ£o

**Arena Shooter + Roguelite primeiro. Campaign mais tarde.**

O XP serÃ¡ transversal aos modos: jogar nos diferentes modos contribuirÃ¡ para a progressÃ£o global. O hub roguelite concentrarÃ¡ a progressÃ£o persistente e as skill trees. A progressÃ£o temporÃ¡ria de cada run deverÃ¡ ser distinguida da progressÃ£o global. Regras de equilÃ­brio, recompensas e persistÃªncia serÃ£o definidas antes da implementaÃ§Ã£o destes sistemas.

## Roadmap

- [x] Init: projeto importÃ¡vel, cena principal, organizaÃ§Ã£o e sandbox de controlos.
- [x] Primeiro combate: inimigo bÃ¡sico, colisÃ£o de tiros, dano, morte, HUD e reinÃ­cio.
- [ ] Separar jogador, projÃ©teis e inimigos em cenas prÃ³prias; o primeiro protÃ³tipo concentra a simulaÃ§Ã£o em `scripts/main/main.gd`.
- [x] Loop inicial de ondas: dificuldade crescente, pausa, recuperação de vida e dash.
- [ ] Afinar feedback de combate, separação dos inimigos e equilíbrio da primeira arma.
- [ ] Loop roguelite: runs, escolhas temporÃ¡rias, recompensas e retorno ao hub.
- [ ] XP transversal, save versionado e skill trees persistentes no hub roguelite.
- [ ] ConteÃºdo e polimento: armas, inimigos, arte, Ã¡udio e acessibilidade.
- [ ] Campaign: narrativa, missÃµes e integraÃ§Ã£o com os sistemas jÃ¡ validados.

A sequÃªncia Ã© uma intenÃ§Ã£o de desenvolvimento, sem datas comprometidas. Este init nÃ£o implementa os sistemas futuros.

## ValidaÃ§Ã£o rÃ¡pida

```sh
godot --headless --editor --path . --quit
godot --headless --path . --quit-after 120
godot --headless --path . --script tests/combat_smoke.gd
```

O teste de combate verifica perseguiÃ§Ã£o, spawn, colisÃ£o contÃ­nua dos tiros, dano, invulnerabilidade, eliminaÃ§Ãµes, morte e limpeza no reinÃ­cio.

No editor, executar F5 e confirmar movimento nas quatro direÃ§Ãµes, limites da arena, mira, disparo contÃ­nuo, legibilidade do HUD, impactos, morte e reinÃ­cio com R. Os comandos headless verificam importaÃ§Ã£o e arranque, mas nÃ£o substituem esta verificaÃ§Ã£o interativa.

## Contribuir e licenÃ§a

Consultar [CONTRIBUTING.md](CONTRIBUTING.md). CÃ³digo distribuÃ­do sob a [licenÃ§a MIT](LICENSE). Assets futuros deverÃ£o incluir origem e licenÃ§a prÃ³prias quando aplicÃ¡vel.
