# Sword Ablaze

Top-down pixel-art shooter em GDScript, ambientado num CÃƒÂ©u em ruÃƒÂ­nas. Combate rÃƒÂ¡pido, arenas e progressÃƒÂ£o roguelite formam o foco inicial; uma campanha narrativa fica para uma fase posterior.

## Abrir e executar

1. Instalar **Godot 4.5.1 Standard** (sem .NET), versÃƒÂ£o de referÃƒÂªncia deste init.
2. Clonar este repositÃƒÂ³rio e importar `project.godot` no Godot.
3. Abrir o projeto e carregar **F6** para a cena atual ou **F5** para o projeto.

Pelo terminal: `godot --editor --path .` ou `godot --path .` (com o executÃƒÂ¡vel no PATH).

A primeira arena de combate usa placeholders geomÃƒÂ©tricos: WASD/setas para mover, rato para apontar, botÃƒÂ£o esquerdo/EspaÃƒÂ§o para disparar Shift para dash, Escape para pausar/retomar e R para reiniciar em qualquer momento.

- Inimigos perseguem o jogador e surgem a cada 1,6 segundos, atÃƒÂ© 18 em simultÃƒÂ¢neo, longe da posiÃƒÂ§ÃƒÂ£o do jogador.
- Cada inimigo precisa de dois tiros; o impacto dÃƒÂ¡ um flash e a morte conta uma eliminaÃƒÂ§ÃƒÂ£o.
- O jogador tem 5 HP. Contacto causa 1 de dano, com 0,85 segundos de proteÃƒÂ§ÃƒÂ£o entre impactos.
- O HUD mostra vida, eliminaÃƒÂ§ÃƒÂµes e tempo. Ao morrer, a simulaÃƒÂ§ÃƒÂ£o para e R inicia uma nova partida.
- Ainda nÃƒÂ£o existem XP, ondas, menus, save ou progressÃƒÂ£o persistente. Os inimigos podem sobrepor-se neste protÃƒÂ³tipo.

## Base tÃƒÂ©cnica

- Godot 4.x, GDScript e renderer Compatibility.
- ResoluÃƒÂ§ÃƒÂ£o lÃƒÂ³gica 640Ãƒâ€”360, janela inicial 1280Ãƒâ€”720 e escala inteira.
- Filtro nearest para texturas pixel art; movimento normalizado em passos de fÃƒÂ­sica.
- Arena limitada e projÃƒÂ©teis removidos ao sair dos limites.
- O sandbox regista as aÃƒÂ§ÃƒÂµes de input no arranque em `scripts/main/main.gd`.
- GrÃƒÂ¡ficos temporÃƒÂ¡rios desenhados por cÃƒÂ³digo; nenhum asset externo ÃƒÂ© necessÃƒÂ¡rio.

## OrganizaÃƒÂ§ÃƒÂ£o

```text
scenes/       Cenas, comeÃƒÂ§ando por main/main.tscn
scripts/      GDScript organizado por contexto
tests/        VerificaÃƒÂ§ÃƒÂµes automÃƒÂ¡ticas do combate
assets/       Arte, ÃƒÂ¡udio e fontes
resources/    Resources (.tres) e dados de configuraÃƒÂ§ÃƒÂ£o
```

## VisÃƒÂ£o de progressÃƒÂ£o

**Arena Shooter + Roguelite primeiro. Campaign mais tarde.**

O XP serÃƒÂ¡ transversal aos modos: jogar nos diferentes modos contribuirÃƒÂ¡ para a progressÃƒÂ£o global. O hub roguelite concentrarÃƒÂ¡ a progressÃƒÂ£o persistente e as skill trees. A progressÃƒÂ£o temporÃƒÂ¡ria de cada run deverÃƒÂ¡ ser distinguida da progressÃƒÂ£o global. Regras de equilÃƒÂ­brio, recompensas e persistÃƒÂªncia serÃƒÂ£o definidas antes da implementaÃƒÂ§ÃƒÂ£o destes sistemas.

## Roadmap

- [x] Init: projeto importÃƒÂ¡vel, cena principal, organizaÃƒÂ§ÃƒÂ£o e sandbox de controlos.
- [x] Primeiro combate: inimigo bÃƒÂ¡sico, colisÃƒÂ£o de tiros, dano, morte, HUD e reinÃƒÂ­cio.
- [ ] Separar jogador, projÃƒÂ©teis e inimigos em cenas prÃƒÂ³prias; o primeiro protÃƒÂ³tipo concentra a simulaÃƒÂ§ÃƒÂ£o em `scripts/main/main.gd`.
- [x] Loop inicial de ondas: dificuldade crescente, pausa, recuperaÃ§Ã£o de vida e dash.
- [ ] Afinar feedback de combate, separaÃ§Ã£o dos inimigos e equilÃ­brio da primeira arma.
- [ ] Loop roguelite: runs, escolhas temporÃƒÂ¡rias, recompensas e retorno ao hub.
- [ ] XP transversal, save versionado e skill trees persistentes no hub roguelite.
- [ ] ConteÃƒÂºdo e polimento: armas, inimigos, arte, ÃƒÂ¡udio e acessibilidade.
- [ ] Campaign: narrativa, missÃƒÂµes e integraÃƒÂ§ÃƒÂ£o com os sistemas jÃƒÂ¡ validados.

A sequÃƒÂªncia ÃƒÂ© uma intenÃƒÂ§ÃƒÂ£o de desenvolvimento, sem datas comprometidas. Este init nÃƒÂ£o implementa os sistemas futuros.

## ValidaÃƒÂ§ÃƒÂ£o rÃƒÂ¡pida

```sh
godot --headless --editor --path . --quit
godot --headless --path . --quit-after 120
godot --headless --path . --script tests/combat_smoke.gd
```

O teste de combate verifica perseguiÃƒÂ§ÃƒÂ£o, spawn, colisÃƒÂ£o contÃƒÂ­nua dos tiros, dano, invulnerabilidade, eliminaÃƒÂ§ÃƒÂµes, morte e limpeza no reinÃƒÂ­cio.

No editor, executar F5 e confirmar movimento nas quatro direÃƒÂ§ÃƒÂµes, limites da arena, mira, disparo contÃƒÂ­nuo, legibilidade do HUD, impactos, morte e reinÃƒÂ­cio com R. Os comandos headless verificam importaÃƒÂ§ÃƒÂ£o e arranque, mas nÃƒÂ£o substituem esta verificaÃƒÂ§ÃƒÂ£o interativa.

## Contribuir e licenÃƒÂ§a

Consultar [CONTRIBUTING.md](CONTRIBUTING.md). CÃƒÂ³digo distribuÃƒÂ­do sob a [licenÃƒÂ§a MIT](LICENSE). Assets futuros deverÃƒÂ£o incluir origem e licenÃƒÂ§a prÃƒÂ³prias quando aplicÃƒÂ¡vel.
