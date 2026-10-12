# DIAGONAL_PASS_TRAJECTORY_CALIBRATION

## Problema
O bot rejeita o passe `$0800 → $0C00` por `CORRIDOR_BLOCKED` e margem de chegada insuficiente, apesar de sucesso manual informado para `Right+Down+B`. Não reduzir limites sem comparar trajetória real.

## Experimento
1. Salve um savestate imediatamente antes da decisão, em jogo ativo, com `$0800` portando a bola. Abra o Lua Console e **pare** `main.lua`.
2. Execute apenas `tools/bizhawk/issd/probes/diagonal_trajectory_calibration.lua`.
3. A sonda dispara `Right+Down+B` por **1 frame**, libera os botões e observa 120 frames. Ao terminar, restaura o estado inicial.
4. Analise `tools/bizhawk/issd/diagonal_trajectory_frames.csv`. Verifique posição bola/receptor a cada frame, distância mínima à CPU e primeiro sinal de posse individual de `$0C00` ou da CPU.
5. Se a execução manual exigiu uma duração maior de B, configure `BUTTON_FRAMES` para a mesma duração e repita com o mesmo savestate. Varie depois as condições iniciais para avaliar repetibilidade.

## Limites
O `predicted_45deg_miss` é apenas a projeção teórica inicial. `nearest_cpu_ball_distance` e `nearest_cpu_receiver_distance` são distâncias instantâneas, não a margem dinâmica de chegada; compare esses valores com o risco previsto no relatório principal. `TARGET_OWNER_SIGNAL` é indicação de dono individual, não prova isolada de domínio físico. A sonda não interfere em `forward_pass.lua` e não afrouxa `CORRIDOR_BLOCKED`.

Esta instrumentação gera **dados**; não afirma que o comando funciona automaticamente em todos os estados ou que o receptor efetivamente domina a bola.
