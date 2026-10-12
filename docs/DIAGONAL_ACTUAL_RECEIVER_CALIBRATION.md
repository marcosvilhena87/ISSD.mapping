# Calibração do receptor real em passes diagonais

A coleta registra o receptor previsto pelo planejador e o primeiro sinal de posse
individual após cada passe diagonal, incluindo os candidatos $0A00, $0B00 e $0C00.

## Evento
`DIAGONAL_ACTUAL_RECEIVER_CALIBRATION` é emitido no fechamento de uma tentativa
`SHORT_DIAGONAL` ou `EIGHT_WAY_DIAGONAL`, com:
- `expected_receiver`, `actual_owner`, `actual_my_receiver`;
- `outcome`: `PASS_RECEIVED`, `PASS_INTERCEPTED` ou `PASS_UNRESOLVED`;
- `min_gap_0A00`, `min_gap_0B00`, `min_gap_0C00`: menor
  distância de cada candidato à bola, amostrada por frame;
- `passer`, `direction`, `vertical`, `age`,
  `max_displacement`, `sequence`.

No caso anteriormente observado, a hipótese era `expected_receiver=0x0B00`
enquanto o sinal de posse apontou `actual_owner=0x0A00`. Esse dado
não prova que o comando tem destino fixo diferente do previsto; exige
várias reproduções e análise da trajetória.

## Critérios de interpretação
`actual_my_receiver` só é preenchido quando o sistema existente
classifica a jogada como `PASS_RECEIVED`, evitando confundir recuperação
adversária com recepção do destinatário.

A distância mínima à bola, por si só, não comprova toque, e um sinal de
RAM de posse individual tampouco garante recepção física. Os relatórios
não alteram decisões, thresholds nem o plano de passes.

## Próxima validação
Repita os comandos `Right+Up+B` e `Right+Down+B` com recebedores
$0A00, $0B00 e $0C00 em posições variadas. Compare sempre
`expected_receiver`, `actual_my_receiver` e `outcome` por
`sequence`, antes de alterar o mecanismo de seleção.
