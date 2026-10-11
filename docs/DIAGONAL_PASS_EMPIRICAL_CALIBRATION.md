# DIAGONAL_PASS_EMPIRICAL_CALIBRATION

## Alcance

Instrumentação para reproduzir e medir comandos direcionais diagonais no
BizHawk. **Não altera a política do bot** e não afirma que deslocamento da
bola ou mudança de `Team_Ball_Possession` comprovam recepção.

## Coleta

1. Abra um estado de partida ativa com posse individual do time controlado.
2. Interrompa `main.lua` e execute
   `tools/bizhawk/issd/probes/diagonal_action_matrix.lua` sozinho.
3. Guarde o CSV produzido com nome único, por exemplo
   `captures/situacao_01.csv`.
4. Repita em **pelo menos cinco situações iniciais independentes**,
   variando lado do campo, portador, pressão e alinhamento.
   Repetir o mesmo savestate não constitui nova situação independente.
5. Execute:

```bash
python tools/diagonal_empirical_calibration.py captures/*.csv --output diagonal_empirical_calibration.csv
```

O relatório apresenta as 16 combinações, com enfoque em `Right/Left+Up/Down+B`:
quantidade de capturas independentes, deslocamento médio observado, alinhamento
cosseno em relação ao comando, mudanças do sinal individual de posse e parecer.

Limiares iniciais de medição (não calibrados em dados reais):
`--min-sessions 5`, `--min-motion 8`, `--min-alignment 0.80`.

## Semântica dos pareceres

- `INSUFFICIENT_INDEPENDENT_CAPTURES`: amostra insuficiente.
- `INCONCLUSIVE_LOW_MOTION`: bola não se deslocou o bastante.
- `INCONSISTENT_DIRECTION`: ao menos uma amostra com movimento contrário
  ao alinhamento mínimo estabelecido.
- `DIRECTION_REPRODUCED_NOT_PASS_CONFIRMED`: deslocamento observado
  reproduzido, **não comprovação de passe nem de recepção**.

`pass_confirmed=NO` é intencional: o CSV atual não contém confirmação física
de domínio por receptor específico. A próxima etapa é registrar portador,
receptor planejado, trajetória, adversário mais próximo e posse física final,
ligando cada tentativa ao resultado. Só então calibrar ranking e margens de
segurança no `forward_pass.lua`.

## Restrições

O experimento executa as 16 combinações sobre a mesma origem por arquivo,
usando savestate em memória. As 16 linhas não são réplicas independentes.
O script de análise não aciona o emulador e não altera `config.lua`.
