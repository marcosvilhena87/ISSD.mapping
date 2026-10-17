# Condições dos jogadores — candidatos de memória

Fonte: `ISSD_players_conditions.wch` (SNES / WRAM).

Os 40 registros foram transcritos da fonte enviada, sem atribuir semântica não verificada aos valores. **P1/P2 são rótulos originais da fonte**: não foi demonstrado que correspondam a equipes específicas em todas as situações.

- 20 registros P1: de `0x003E08` a `0x003EC6`, passo `0x0A`.
- 20 registros P2: de `0x003ED0` a `0x003F8E`, passo `0x0A`.
- Formato WCH: `w u 0 WRAM` (word unsigned; 2 bytes; little-endian a confirmar em execução).
- Os comentários indicam mínimo `0` e máximo `4` para cada registro.
- Status: 🟡 candidatos, sem identificação da semântica nem validação dinâmica.

| Bloco | Índice | Endereço WRAM | Tamanho WCH | Sinal WCH | Faixa anotada | Status |
|---|---:|---|---|---|---|---|
| P1 | 01 | `0x003E08` | `w` | `u` | `0..4` | 🟡 |
| P1 | 02 | `0x003E12` | `w` | `u` | `0..4` | 🟡 |
| P1 | 03 | `0x003E1C` | `w` | `u` | `0..4` | 🟡 |
| P1 | 04 | `0x003E26` | `w` | `u` | `0..4` | 🟡 |
| P1 | 05 | `0x003E30` | `w` | `u` | `0..4` | 🟡 |
| P1 | 06 | `0x003E3A` | `w` | `u` | `0..4` | 🟡 |
| P1 | 07 | `0x003E44` | `w` | `u` | `0..4` | 🟡 |
| P1 | 08 | `0x003E4E` | `w` | `u` | `0..4` | 🟡 |
| P1 | 09 | `0x003E58` | `w` | `u` | `0..4` | 🟡 |
| P1 | 10 | `0x003E62` | `w` | `u` | `0..4` | 🟡 |
| P1 | 11 | `0x003E6C` | `w` | `u` | `0..4` | 🟡 |
| P1 | 12 | `0x003E76` | `w` | `u` | `0..4` | 🟡 |
| P1 | 13 | `0x003E80` | `w` | `u` | `0..4` | 🟡 |
| P1 | 14 | `0x003E8A` | `w` | `u` | `0..4` | 🟡 |
| P1 | 15 | `0x003E94` | `w` | `u` | `0..4` | 🟡 |
| P1 | 16 | `0x003E9E` | `w` | `u` | `0..4` | 🟡 |
| P1 | 17 | `0x003EA8` | `w` | `u` | `0..4` | 🟡 |
| P1 | 18 | `0x003EB2` | `w` | `u` | `0..4` | 🟡 |
| P1 | 19 | `0x003EBC` | `w` | `u` | `0..4` | 🟡 |
| P1 | 20 | `0x003EC6` | `w` | `u` | `0..4` | 🟡 |
| P2 | 01 | `0x003ED0` | `w` | `u` | `0..4` | 🟡 |
| P2 | 02 | `0x003EDA` | `w` | `u` | `0..4` | 🟡 |
| P2 | 03 | `0x003EE4` | `w` | `u` | `0..4` | 🟡 |
| P2 | 04 | `0x003EEE` | `w` | `u` | `0..4` | 🟡 |
| P2 | 05 | `0x003EF8` | `w` | `u` | `0..4` | 🟡 |
| P2 | 06 | `0x003F02` | `w` | `u` | `0..4` | 🟡 |
| P2 | 07 | `0x003F0C` | `w` | `u` | `0..4` | 🟡 |
| P2 | 08 | `0x003F16` | `w` | `u` | `0..4` | 🟡 |
| P2 | 09 | `0x003F20` | `w` | `u` | `0..4` | 🟡 |
| P2 | 10 | `0x003F2A` | `w` | `u` | `0..4` | 🟡 |
| P2 | 11 | `0x003F34` | `w` | `u` | `0..4` | 🟡 |
| P2 | 12 | `0x003F3E` | `w` | `u` | `0..4` | 🟡 |
| P2 | 13 | `0x003F48` | `w` | `u` | `0..4` | 🟡 |
| P2 | 14 | `0x003F52` | `w` | `u` | `0..4` | 🟡 |
| P2 | 15 | `0x003F5C` | `w` | `u` | `0..4` | 🟡 |
| P2 | 16 | `0x003F66` | `w` | `u` | `0..4` | 🟡 |
| P2 | 17 | `0x003F70` | `w` | `u` | `0..4` | 🟡 |
| P2 | 18 | `0x003F7A` | `w` | `u` | `0..4` | 🟡 |
| P2 | 19 | `0x003F84` | `w` | `u` | `0..4` | 🟡 |
| P2 | 20 | `0x003F8E` | `w` | `u` | `0..4` | 🟡 |

## Cuidados e testes

1. Capturar os 40 valores em diferentes momentos da partida.
2. Verificar a correspondência entre índices e jogadores/tabelas internas; não pressupor que sejam os 11 titulares.
3. Comparar antes/depois de substituições, mudanças de condição e reinício da partida.
4. Verificar se `0..4` é intervalo exaustivo, se os campos são de fato 16 bits e se há relação com equipes ou estados de jogo.
5. Conservar rótulos e endereços mesmo que alguma hipótese seja refutada.

A sequência de endereços e os rótulos são observações de arquivo, **não prova da função das variáveis**.
