# Calibração de risco: A/B de três comandos

No BizHawk, carregue um estado de jogo ativo com posse individual de `$0800` e execute **isoladamente** `probes/diagonal_risk_comparison.lua` (sem `main.lua`). A sonda restaura um savestate em memória antes de cada ação: `Right+Up+B` para `$0B00`, `Right+Down+B` para `$0C00` e `Right+A` (cinco frames). Registra 0–120 frames por ação em `diagonal_risk_comparison.csv`, depois restaura o estado.

A duração inicial de B é **um frame**. Ajuste `held` por ação para corresponder ao comando manual observado e repita. Comparar um frame de B com A carregado não prova superioridade das decisões reais; os CSVs são experimentos de mecanismo, não partidas completas.

Leia `signal` como observação de dono individual, não confirmação física de toque. `nearest_cpu_ball` e `nearest_cpu_target` são distâncias, não tempos de interceptação. Compare primeira posse observada, distância mínima ao receptor, posição da bola, pressão adversária e persistência da posse após 120 frames. Repita em estados independentes. Nenhum limite de segurança do controlador é alterado.
