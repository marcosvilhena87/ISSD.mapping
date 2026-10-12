# Calibração do passe de $0A00 para $0C00

A sonda `tools/bizhawk/issd/probes/post_diagonal_direction_comparison.lua`
compara três comandos saindo da **mesma posse individual de $0A00**:
`LEFT_UP_B` (Left+Up+B), `LEFT_DOWN_B` (Left+Down+B) e `RIGHT_A`.

## BizHawk com API de savestate
Interrompa `main.lua`, carregue estado com `$0A00` na posse individual
e execute a sonda. Ela restaura o estado antes de cada ação, acompanha
120 frames e grava `post_diagonal_direction_comparison.csv`.

## BizHawk sem API de savestate
A sonda utiliza `MANUAL_ACTION="LEFT_UP_B"`, grava
`post_diagonal_LEFT_UP_B.csv` e **não restaura** o jogo. Recarregue
manualmente o **mesmo** savestate, mude `MANUAL_ACTION` para
`LEFT_DOWN_B` e depois `RIGHT_A`, repetindo a restauração entre
execuções. Não some as três capturas sem confirmar o estado inicial.

A duração inicial do botão B é 1 frame; iguale `held` à duração usada
no teste manual. O campo `target_distance` indica proximidade da bola
a $0C00, não prova recepção. `owner` e `signal` são indícios de posse
individual registrados pela RAM.

## Cooldown após recepção
O `orchestrator.lua` agora escreve `POST_DIAGONAL_COOLDOWN_BLOCK`
quando o plano principal de $0A00 retorna `COOLDOWN`, com tempo de
cooldown restante e idade da posse. Isso não altera a política de passe
nem cancela o cooldown. O próximo ajuste dependerá da trajetória
instrumentada e das observações do bloqueio.
