# Dados de combate

Editar `dawn_bow.tres`, `default_enemy.tres` e `default_wave.tres` no Inspector do Godot para ajustar o protótipo. Os scripts em `scripts/data/` definem os campos disponíveis.

Os componentes partilham estes recursos apenas para leitura. Vida atual, temporizadores, posição e orçamento restante pertencem às instâncias de simulação. Para criar variantes durante uma partida, duplicar o Resource antes de alterar os seus campos; nunca alterar os defaults partilhados.

A arma define intervalo, velocidade, dano, recuo e origem dos tiros. O inimigo define vida inicial, velocidade, escalada e raios de colisão. A configuração de ondas define orçamento, limites e temporizadores. Alterar valores não equivale a validar equilíbrio: executar os testes e fazer playtesting.

As melhorias em `upgrades/` definem atributo, multiplicador, adição e limite de stacks. A cada terceira onda o protótipo oferece até três opções distintas ainda elegíveis. Os efeitos são recalculados a partir dos defaults; reiniciar limpa todos os stacks. Ao esgotar as opções, a run continua sem abrir uma escolha vazia. `upgrade_every` no Resource de ondas controla a frequência provisória.
