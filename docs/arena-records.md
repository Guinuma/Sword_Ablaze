# Recordes locais da arena

`user://arena_records.json` guarda um objeto JSON com `version: 1`, `runs`, `best_wave`, `best_kills` e `best_seconds`. Os recordes são máximos independentes, não necessariamente obtidos na mesma partida. Uma derrota é contabilizada uma vez; reiniciar uma partida em curso não conta como derrota.

A gravação escreve e fecha primeiro `.tmp`, copia o ficheiro principal válido para `.bak` e renomeia o temporário para o nome principal. Um principal inválido não substitui o backup. Ao carregar, dados inválidos ou incompletos levam à tentativa do backup e, se este também falhar, aos valores iniciais. Uma versão futura impede novas gravações para evitar destruir dados que este código não compreende. Os campos numéricos são validados antes de serem utilizados.

A UI mostra os melhores valores no resumo e indica falha de gravação. Os testes usam caminhos próprios e removem esses ficheiros; não alteram os recordes do jogador.

Este ficheiro não é o perfil global nem atribui XP ou recompensas. Migrações e a integração com progressão continuam pendentes. Não foi simulada perda de energia durante operações do sistema de ficheiros.

Courtyard Run usa o mesmo armazenamento seguro num ficheiro separado, `user://finite_records.json`. O campo opcional `wins` conta vitórias e fica a zero em saves antigos; deve ser inteiro entre zero e `runs`. Vitória e derrota contam uma partida, mas abandonar/reiniciar uma partida em curso não. O contador local de vitórias não é XP nem perfil global.
