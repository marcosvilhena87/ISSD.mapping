# ISS Deluxe — observações PASS LV.1 e mapa de evidências (v0.9.18)

Documento de integração com `marcosvilhena87/ISSD.challenge_mode`, sem alterar o mapa RAM validado até haver confirmação independente.

## Evidências observadas
- Desafio PASS LV.1: contagem espacial dos jogadores de linha IDs 2–11, que depende da interpretação do amostrador e não equivale, isoladamente, à validação oficial da tela.
- Pontuação candidata WRAM: Time Score em `0x01CF3` (u8), Bonus Score em `0x01CF8` (u16 LE), Total em `0x01CFA` (u16 LE) e cópia em `0x0DC06` (u16 LE). **Status: candidatos correlacionados, não mapa confirmado por varredura independente.**
- v0.9.16: 122 + 274 = 396, com cópia sincronizada, observação de 10/10 e incremento do contador de gols após X. Falta tela oficial para confirmar recorde.
- v0.9.17: 115 + 260 = 375; 10/10, X e incremento de gols observados.
- O campo de segundos inteiros do cronômetro não resolve os últimos centésimos. Distinguir segundos positivos, fronteira temporal indeterminada e confirmação por resposta do jogo; não rejeitar automaticamente candidato em tempo inteiro zero.
- Controle de passe B usa cardinal dominante; aproximações podem usar diagonais, e um receptor observado pode divergir do alvo indicado em B.

## Pendências de mapeamento RAM
1. Descobrir contador de subsegundos/frames do cronômetro com experimentos diferenciais e leitura por frame.
2. Identificar posição efetiva da bola e confirmar estabilidade do vínculo com portador.
3. Diferenciar IDs de jogadores, posse observada e recepção real durante animação.
4. Testar se os endereços de pontuação mudam antes/depois de resultado oficial; correlacionar screenshots e savestates.
5. Investigar desvio alvo B (ex.: 8→9 pretendido, 8→11 observado) com coordenadas e timestamps.

## Procedimento
Coletar amostras por frame do mesmo savestate em cenários sem passe, passe B, interceptação, expiração do relógio e entrada no bônus. Comparar endereços em repetidos ensaios; promover a **confirmado** apenas quando reprodução e contraexemplos sustentarem a hipótese.

Fonte de observação: logs de ensaios PASS LV.1 da conversa do projeto, não dump RAM independente. Este documento não substitui `docs/RAM_MAP.md`.
