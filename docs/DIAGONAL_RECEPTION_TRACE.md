# Rastreamento empírico de recepção diagonal

Esta extensão da sonda `probes/diagonal_action_matrix.lua` registra
a distância mínima bola–receptor `$0C00`, frame dessa aproximação,
primeira observação de `possession=$0C00`, e primeiro sinal de
posse individual da CPU, durante **90 frames** após o comando.

## Procedimento para o lance $0800 → $0C00

1. No BizHawk, salve manualmente um estado com `$0800` dominando a bola,
   antes do desafogo, com `$0C00` disponível.
2. Interrompa `main.lua` e execute apenas
   `tools/bizhawk/issd/probes/diagonal_action_matrix.lua`.
3. A sonda restaura o mesmo savestate em memória antes de cada combinação,
   executa um frame de comando e solta todos os botões para observar.
4. Consulte a linha `Right+Down+B` em
   `tools/bizhawk/issd/diagonal_action_matrix.csv`.
5. Repita com novos estados independentes antes de inferir eficácia.

## Novas colunas

- `target_receiver`: slot configurado (padrão `0x0C00`).
- `target_min_distance` e `target_min_frame`: aproximação real.
- `first_target_owner_frame`: primeiro frame com posse individual do alvo.
- `first_cpu_owner_frame`: primeiro frame com posse individual adversária.
- `outcome_observation`: `TARGET_OWNER_SIGNAL_OBSERVED`,
  `CPU_OWNER_SIGNAL_OBSERVED`, `TARGET_PROXIMITY_ONLY` ou `UNRESOLVED`.

A ordem das observações de alvo e CPU deve ser considerada: um sinal
de posse posterior não significa que a tentativa foi bem-sucedida.

**Limitações:** o campo de posse individual é observacional, não uma prova
isolada de toque físico; a sonda usa um frame de pressão do botão, portanto
não reproduz necessariamente a duração do comando no bot. Proximidade
não é confirmação de domínio. A execução da sonda não altera a política
`forward_pass.lua` nem o filtro `COMMAND_MISS`.