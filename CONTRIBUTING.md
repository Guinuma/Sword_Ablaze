# Contribuir

Usar Godot 4.5.1 Standard e GDScript. Manter alterações pequenas, com um objetivo claro e sem introduzir sistemas futuros antes de validar o loop principal.

- Usar `snake_case` em ficheiros, variáveis e funções; `PascalCase` em classes e nós.
- Usar tabs em GDScript e caminhos `res://` portáveis.
- Organizar cenas e scripts por contexto; colocar dados reutilizáveis em `resources/`.
- Não versionar `.godot/`, builds ou credenciais. Versionar os ficheiros `.uid` gerados pelo Godot para preservar referências.
- Documentar controlos novos, decisões de arquitetura e origem/licença de assets.
- Antes de propor alterações, importar no editor, executar a cena principal e verificar erros no debugger e o estado do Git.
- Na descrição da contribuição, indicar o comportamento alterado e como foi verificado.

Convenções de coordenadas, colisão, grupos, desenho e pivôs: [referência técnica](docs/technical-conventions.md). Consultar antes de acrescentar entidades, obstáculos ou substituir sprites.
