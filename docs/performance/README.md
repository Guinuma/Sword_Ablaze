# Medição do combate

Executar `godot --headless --path . --script tools/combat_benchmark.gd -- docs/performance/baseline.json`.

O cenário aquece durante 600 frames e mede 3600 frames de simulação a passos de 1/60 s. Antes de cada frame, repõe os limites de 18 inimigos (6 à distância), 128 tiros do jogador, 64 tiros hostis e 160 partículas. A reposição fica fora do trecho medido; o movimento, colisões, separação, efeitos e atualização do HUD entram na medição. Os inimigos recebem vida elevada apenas neste cenário.

Na medição inicial em Windows, Godot 4.5.1 e AMD Ryzen 7 5825U, a média foi 1,58 ms, p95 2,37 ms e máximo 6,23 ms. Memória estática máxima do motor: cerca de 30,3 MiB. O relatório bruto está em `baseline.json`.

Estes resultados excluem renderização e interação real, dependem da máquina e não definem FPS, requisitos mínimos ou garantia de desempenho. Repetir com renderização e sessões reais antes de decidir hardware mínimo. Não foi introduzido pooling: medir novamente após alterações relevantes antes de acrescentar essa complexidade.

Limites atuais: 18 inimigos em simultâneo, 128 tiros do jogador, 64 tiros hostis e 160 partículas. Tiros expiram após 5 s ou ao sair da arena. Spawns em preparação contam como inimigos para o limite e o orçamento.
