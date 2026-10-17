# Inventário de endereços de memória — ISSD Deluxe

Este inventário **preserva todos os endereços identificados**, independentemente de validação, estabilidade ou utilização atual. Não eliminar endereços por falta de confirmação. Valores de estado, offsets e stride não devem ser confundidos com endereços independentes.

Endereços provenientes dos mapas WCH, `docs/RAM_MAP.md` e `tools/bizhawk/issd/core/config.lua`. As estruturas de 22 jogadores incluem endereços **derivados** por stride `0x100` para coordenadas de mundo e câmera. As referências documentais originais permanecem preservadas.

| Endereço WRAM | Identificação |
|---|---|
| `0x0006` | Gameplay ativo |
| `0x0086` | Identificador do estádio |
| `0x00A6` | Jogador com posse física |
| `0x00BA` | Estado da partida |
| `0x0410` | Candidato altura da bola |
| `0x042A` | Bola X (mundo) |
| `0x042C` | Bola Y (mundo) |
| `0x0500` | Meu time jogador 1 — base |
| `0x0508` | Meu time jogador 1 — X câmera |
| `0x050C` | Meu time jogador 1 — Y câmera |
| `0x052A` | Meu time jogador 1 — X mundo |
| `0x052C` | Meu time jogador 1 — Y mundo |
| `0x056E` | Indicador de lado histórico |
| `0x0600` | Meu time jogador 2 — base |
| `0x0608` | Meu time jogador 2 — X câmera |
| `0x060C` | Meu time jogador 2 — Y câmera |
| `0x062A` | Meu time jogador 2 — X mundo |
| `0x062C` | Meu time jogador 2 — Y mundo |
| `0x0700` | Meu time jogador 3 — base |
| `0x0708` | Meu time jogador 3 — X câmera |
| `0x070C` | Meu time jogador 3 — Y câmera |
| `0x072A` | Meu time jogador 3 — X mundo |
| `0x072C` | Meu time jogador 3 — Y mundo |
| `0x0800` | Meu time jogador 4 — base |
| `0x0808` | Meu time jogador 4 — X câmera |
| `0x080C` | Meu time jogador 4 — Y câmera |
| `0x082A` | Meu time jogador 4 — X mundo |
| `0x082C` | Meu time jogador 4 — Y mundo |
| `0x0900` | Meu time jogador 5 — base |
| `0x0908` | Meu time jogador 5 — X câmera |
| `0x090C` | Meu time jogador 5 — Y câmera |
| `0x092A` | Meu time jogador 5 — X mundo |
| `0x092C` | Meu time jogador 5 — Y mundo |
| `0x096E` | Indicador alternativo de lado |
| `0x0A00` | Meu time jogador 6 — base |
| `0x0A08` | Meu time jogador 6 — X câmera |
| `0x0A0C` | Meu time jogador 6 — Y câmera |
| `0x0A2A` | Meu time jogador 6 — X mundo |
| `0x0A2C` | Meu time jogador 6 — Y mundo |
| `0x0B00` | Meu time jogador 7 — base |
| `0x0B08` | Meu time jogador 7 — X câmera |
| `0x0B0C` | Meu time jogador 7 — Y câmera |
| `0x0B2A` | Meu time jogador 7 — X mundo |
| `0x0B2C` | Meu time jogador 7 — Y mundo |
| `0x0C00` | Meu time jogador 8 — base |
| `0x0C08` | Meu time jogador 8 — X câmera |
| `0x0C0C` | Meu time jogador 8 — Y câmera |
| `0x0C2A` | Meu time jogador 8 — X mundo |
| `0x0C2C` | Meu time jogador 8 — Y mundo |
| `0x0D00` | Meu time jogador 9 — base |
| `0x0D08` | Meu time jogador 9 — X câmera |
| `0x0D0C` | Meu time jogador 9 — Y câmera |
| `0x0D2A` | Meu time jogador 9 — X mundo |
| `0x0D2C` | Meu time jogador 9 — Y mundo |
| `0x0DA2` | Gols meu time |
| `0x0DAA` | Finalizações meu time |
| `0x0E00` | Meu time jogador 10 — base |
| `0x0E08` | Meu time jogador 10 — X câmera |
| `0x0E0C` | Meu time jogador 10 — Y câmera |
| `0x0E2A` | Meu time jogador 10 — X mundo |
| `0x0E2C` | Meu time jogador 10 — Y mundo |
| `0x0EA2` | Gols CPU |
| `0x0EAA` | Finalizações CPU |
| `0x0F00` | Meu time jogador 11 — base |
| `0x0F08` | Meu time jogador 11 — X câmera |
| `0x0F0C` | Meu time jogador 11 — Y câmera |
| `0x0F2A` | Meu time jogador 11 — X mundo |
| `0x0F2C` | Meu time jogador 11 — Y mundo |
| `0x1000` | CPU jogador 1 — base |
| `0x1008` | CPU jogador 1 — X câmera |
| `0x100C` | CPU jogador 1 — Y câmera |
| `0x102A` | CPU jogador 1 — X mundo |
| `0x102C` | CPU jogador 1 — Y mundo |
| `0x104C` | Posse lógica equipe |
| `0x106E` | Lado CPU |
| `0x1100` | CPU jogador 2 — base |
| `0x1108` | CPU jogador 2 — X câmera |
| `0x110C` | CPU jogador 2 — Y câmera |
| `0x112A` | CPU jogador 2 — X mundo |
| `0x112C` | CPU jogador 2 — Y mundo |
| `0x1200` | CPU jogador 3 — base |
| `0x1208` | CPU jogador 3 — X câmera |
| `0x120C` | CPU jogador 3 — Y câmera |
| `0x122A` | CPU jogador 3 — X mundo |
| `0x122C` | CPU jogador 3 — Y mundo |
| `0x12A2` | Comprimento campo |
| `0x12A4` | Largura campo |
| `0x12D8` | Centro Y campo |
| `0x12F2` | Centro X campo |
| `0x1300` | CPU jogador 4 — base |
| `0x1308` | CPU jogador 4 — X câmera |
| `0x130C` | CPU jogador 4 — Y câmera |
| `0x132A` | CPU jogador 4 — X mundo |
| `0x132C` | CPU jogador 4 — Y mundo |
| `0x1400` | CPU jogador 5 — base |
| `0x1408` | CPU jogador 5 — X câmera |
| `0x140C` | CPU jogador 5 — Y câmera |
| `0x142A` | CPU jogador 5 — X mundo |
| `0x142C` | CPU jogador 5 — Y mundo |
| `0x1500` | CPU jogador 6 — base |
| `0x1508` | CPU jogador 6 — X câmera |
| `0x150C` | CPU jogador 6 — Y câmera |
| `0x152A` | CPU jogador 6 — X mundo |
| `0x152C` | CPU jogador 6 — Y mundo |
| `0x1600` | CPU jogador 7 — base |
| `0x1608` | CPU jogador 7 — X câmera |
| `0x160C` | CPU jogador 7 — Y câmera |
| `0x162A` | CPU jogador 7 — X mundo |
| `0x162C` | CPU jogador 7 — Y mundo |
| `0x1700` | CPU jogador 8 — base |
| `0x1708` | CPU jogador 8 — X câmera |
| `0x170C` | CPU jogador 8 — Y câmera |
| `0x172A` | CPU jogador 8 — X mundo |
| `0x172C` | CPU jogador 8 — Y mundo |
| `0x1800` | CPU jogador 9 — base |
| `0x1808` | CPU jogador 9 — X câmera |
| `0x180C` | CPU jogador 9 — Y câmera |
| `0x182A` | CPU jogador 9 — X mundo |
| `0x182C` | CPU jogador 9 — Y mundo |
| `0x1900` | CPU jogador 10 — base |
| `0x1908` | CPU jogador 10 — X câmera |
| `0x190C` | CPU jogador 10 — Y câmera |
| `0x192A` | CPU jogador 10 — X mundo |
| `0x192C` | CPU jogador 10 — Y mundo |
| `0x19E8` | Candidato de referência altura |
| `0x1A00` | CPU jogador 11 — base |
| `0x1A08` | CPU jogador 11 — X câmera |
| `0x1A0C` | CPU jogador 11 — Y câmera |
| `0x1A2A` | CPU jogador 11 — X mundo |
| `0x1A2C` | CPU jogador 11 — Y mundo |
| `0x1AA8` | Controlado meu X câmera |
| `0x1AAC` | Controlado meu Y câmera |
| `0x1ACC` | Controlado meu ponteiro/base |
| `0x1AD8` | Controlado CPU X câmera |
| `0x1ADC` | Controlado CPU Y câmera |
| `0x1AFC` | Controlado CPU ponteiro/base |
| `0x1040B` | Candidato Z (probe histórico) |
| `0x11B4B` | Candidato Z (probe histórico) |
| `0x1476B` | Candidato Z (probe histórico) |
| `0x14959` | Candidato Z (probe histórico) |
| `0x1498A` | Candidato Z (probe histórico) |
| `0x1FFA6` | Bola X câmera |
| `0x1FFA8` | Bola Y câmera |

## Fontes históricas adicionais

O arquivo histórico `International Superstar Soccer Deluxe (USA) ball.wch` é descrito em `docs/RAM_MAP.md` como contendo **84 endereços sem rótulo**. Como os valores individuais não estão transcritos nesse documento, não foram inventados aqui; sua preservação e futura importação integral continuam obrigatórias quando o arquivo de origem estiver disponível.

## Regra de manutenção

- Adicionar novos endereços identificados sem exigir validação prévia.
- Não apagar um endereço porque seja antigo, alternativo, experimental, instável ou ainda sem interpretação.
- Atualizar a identificação se necessário, preservando a referência histórica.
- Esta lista é documental e **não modifica os controles nem os critérios de segurança da automação**.
